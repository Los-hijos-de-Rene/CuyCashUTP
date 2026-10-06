import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/recipient.dart';
import '../domain/transfer_failure.dart';
import '../domain/transfer_receipt.dart';
import '../domain/transfer_repository.dart';

/// Impl real contra `services/api` (`GET /v1/directory/resolve`,
/// `POST /v1/transfers`, `POST /v1/topups`).
///
/// [dio] debe venir de `buildAuthenticatedDio`: el token y `X-Device-Id` los
/// pone su interceptor, este repositorio no sabe de ellos.
///
/// Errores: cuerpo PLANO `{code, detail, <extras en la raíz>}`. Se mapea por
/// `code` y NUNCA por el texto de `detail`. Un PIN errado es 403 (no 401: la
/// sesión sigue siendo válida) y un bloqueo es 423.
class HttpTransferRepository implements TransferRepository {
  HttpTransferRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  FutureResult<TransferFailure, Recipient> resolverDestinatario(String dni) =>
      _guard(() async {
        final response = await _dio.get<dynamic>(
          '/v1/directory/resolve',
          queryParameters: {'dni': dni},
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        final j = _cuerpo(response);
        return right(
          Recipient(
            dni: j['dni'] as String,
            nombreEnmascarado: j['nombre_enmascarado'] as String,
            cuentaDestinoMasked: j['cuenta_destino_numero_masked'] as String,
          ),
        );
      });

  @override
  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String destinatarioDni,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  }) => _mover('/v1/transfers', {
    // OJO: `motivo` viaja tal cual. El backend lo limita a 40 caracteres y uno
    // más largo da 422 (cae en `TransferUnexpectedFailure`): la UI debe
    // recortarlo y limitar el campo; este repositorio no lo hace.
    'cuenta_origen_id': cuentaOrigenId,
    'destinatario_dni': destinatarioDni,
    'monto_centimos': monto.centimos,
    'motivo': ?motivo,
    'pin': pin,
    'idempotency_key': idempotencyKey,
  }, monto.currency);

  @override
  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String pin,
    required String idempotencyKey,
  }) => _mover('/v1/topups', {
    'cuenta_id': cuentaId,
    'monto_centimos': monto.centimos,
    'pin': pin,
    'idempotency_key': idempotencyKey,
  }, monto.currency);

  FutureResult<TransferFailure, TransferReceipt> _mover(
    String path,
    Map<String, Object?> body,
    Currency moneda,
  ) => _guard(() async {
    final response = await _dio.post<dynamic>(path, data: body);
    if (_failureFor(response) case final f?) {
      return left(GlobalFailure.server(f));
    }
    final j = _cuerpo(response);
    return right(
      TransferReceipt(
        transactionId: j['transaction_id'] as String,
        monto: Money(j['monto_centimos'] as int, moneda),
        fecha: _utc(j['created_at'] as String),
        // 200 = el servidor devolvió la operación original; 201 = nueva.
        reutilizada: response.statusCode == 200,
      ),
    );
  });

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  /// El contrato es UTC con `Z`; sin sufijo `DateTime.parse` leería hora
  /// LOCAL, así que se fuerza UTC (el backend siempre escribe en UTC).
  DateTime _utc(String texto) {
    final f = DateTime.parse(texto);
    return f.isUtc
        ? f
        : DateTime.utc(
            f.year,
            f.month,
            f.day,
            f.hour,
            f.minute,
            f.second,
            f.millisecond,
            f.microsecond,
          );
  }

  /// `null` si no es un instante legible: el llamador cae en `unexpected` en
  /// vez de inventar una fecha de fin de bloqueo.
  DateTime? _instante(Object? crudo) =>
      crudo is String && DateTime.tryParse(crudo) != null ? _utc(crudo) : null;

  TransferFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;
    if (status == 401) return const TransferFailure.unauthenticated();

    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'INSUFFICIENT_FUNDS' => const TransferFailure.insufficientFunds(),
      'RECIPIENT_NOT_FOUND' => const TransferFailure.recipientNotFound(),
      'SELF_TRANSFER' => const TransferFailure.selfTransfer(),
      'ACCOUNT_NOT_FOUND' => const TransferFailure.accountNotFound(),
      'ACCOUNT_BLOCKED' => const TransferFailure.accountBlocked(),
      'AMOUNT_OUT_OF_RANGE' => const TransferFailure.amountOutOfRange(),
      'IDEMPOTENCY_KEY_REUSED' => const TransferFailure.idempotencyKeyReused(),
      // 403 con `intentos_restantes` en la RAÍZ.
      'INVALID_CREDENTIALS' => switch (body['intentos_restantes']) {
        final int n => TransferFailure.wrongPin(n),
        _ => const TransferFailure.unexpected(),
      },
      // 423 con `locked_until` en la raíz.
      'IDENTIFIER_LOCKED' => switch (_instante(body['locked_until'])) {
        final DateTime hasta => TransferFailure.identifierLocked(hasta),
        _ => const TransferFailure.unexpected(),
      },
      'DEVICE_LOCKED' => switch (_instante(body['locked_until'])) {
        final DateTime hasta => TransferFailure.deviceLocked(hasta),
        _ => const TransferFailure.unexpected(),
      },
      // 429 con `retry_after_seconds` en la raíz (opcional para el failure).
      'RATE_LIMITED' => TransferFailure.rateLimited(
        switch (body['retry_after_seconds']) {
          final num s => Duration(seconds: s.ceil()),
          _ => null,
        },
      ),
      _ => const TransferFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<TransferFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<TransferFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      return left(
        GlobalFailure.server(switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.connectionError => const TransferFailure.network(),
          _ => const TransferFailure.unexpected(),
        }),
      );
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
