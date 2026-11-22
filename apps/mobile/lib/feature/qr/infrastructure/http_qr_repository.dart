import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../account/domain/account.dart';
import '../domain/qr_charge.dart';
import '../domain/qr_failure.dart';
import '../domain/qr_payment_preview.dart';
import '../domain/qr_receipt.dart';
import '../domain/qr_repository.dart';
import '../domain/qr_static.dart';

/// Impl real contra `services/api` (`/v1/qr/emitir`, `/estatico`,
/// `/estatico/regenerar`, `/validar` y `/pagar`).
///
/// [dio] debe venir de `buildAuthenticatedDio`: el token y `X-Device-Id` los
/// pone su interceptor. El contenido del QR es opaco: la firma la emite y la
/// comprueba el servidor. El PIN se pide siempre: el backend también lo exige
/// siempre (`QR_AUTH_REQUIRED`).
class HttpQrRepository implements QrRepository {
  HttpQrRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// `idempotencyKey` no viaja: emitir no mueve dinero y cada cobro es nuevo.
  @override
  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _dio.post<dynamic>(
      '/v1/qr/emitir',
      data: {
        'cuenta_id': cuentaId,
        'monto_centimos': monto.centimos,
        'concepto': concepto,
        'caducidad_segundos': QrCharge.vigencia.inSeconds,
      },
    );
    if (_failureFor(response) case final f?) {
      return left(GlobalFailure.server(f));
    }
    final j = _cuerpo(response);
    return right(
      QrCharge(
        id: j['id'] as String,
        payload: j['qr'] as String,
        monto: _dinero(j),
        concepto: j['concepto'] as String,
        expira: _utc(j['caduca_en'] as String),
        cuentaId: cuentaId,
      ),
    );
  });

  @override
  FutureResult<QrFailure, QrStatic> miQr(Account cuenta) =>
      _estatico('/v1/qr/estatico', cuenta);

  @override
  FutureResult<QrFailure, QrStatic> regenerarMiQr(Account cuenta) =>
      _estatico('/v1/qr/estatico/regenerar', cuenta);

  FutureResult<QrFailure, QrStatic> _estatico(String ruta, Account cuenta) =>
      _guard(() async {
        final response = await _dio.post<dynamic>(
          ruta,
          data: {'cuenta_id': cuenta.id},
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        final j = _cuerpo(response);
        return right(
          QrStatic(
            payload: j['qr'] as String,
            cuentaId: j['cuenta_id'] as String,
            moneda: _moneda(j['moneda']),
          ),
        );
      });

  @override
  FutureResult<QrFailure, QrPaymentPreview> leer(String payload) =>
      _guard(() async {
        final response = await _dio.post<dynamic>(
          '/v1/qr/validar',
          // Sin esto el servidor responde QR_UPDATE_REQUIRED a un "Mi QR":
          // es como distingue a los APK que no saben pedir el monto.
          data: {'qr': payload, 'acepta_monto_libre': true},
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        final j = _cuerpo(response);
        final moneda = _moneda(j['moneda']);
        final QrCobro cobro = switch (j['tipo']) {
          'libre' => const QrCobroLibre(),
          'fijo' => QrCobroFijo(
            monto: _dinero(j),
            concepto: j['concepto'] as String,
            expira: _utc(j['caduca_en'] as String),
          ),
          final otro => throw FormatException('Tipo de QR desconocido: $otro'),
        };
        return right(
          QrPaymentPreview(
            payload: payload,
            nombreEnmascarado: j['nombre_enmascarado'] as String,
            cuentaDestinoId: j['cuenta_destino_id'] as String,
            moneda: moneda,
            cobro: cobro,
            disponibleHoy: switch (j['disponible_hoy_centimos']) {
              final int c => Money(c, moneda),
              _ => null,
            },
          ),
        );
      });

  @override
  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
    Money? monto,
    String? mensaje,
  }) => _guard(() async {
    final nota = mensaje?.trim() ?? '';
    final response = await _dio.post<dynamic>(
      '/v1/qr/pagar',
      data: {
        'qr': payload,
        'cuenta_origen_id': cuentaOrigenId,
        'pin': pin,
        'idempotency_key': idempotencyKey,
        'monto_centimos': ?monto?.centimos,
        if (nota.isNotEmpty) 'mensaje': nota,
      },
    );
    if (_failureFor(response) case final f?) {
      return left(GlobalFailure.server(f));
    }
    final j = _cuerpo(response);
    return right(
      QrReceipt(
        transactionId: j['transaction_id'] as String,
        monto: _dinero(j),
        fecha: _utc(j['created_at'] as String),
      ),
    );
  });

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  Money _dinero(Map<String, dynamic> j) =>
      Money(j['monto_centimos'] as int, _moneda(j['moneda']));

  Currency _moneda(Object? codigo) => switch (Currency.fromCode('$codigo')) {
    final Currency c => c,
    null => throw FormatException('Moneda desconocida: $codigo'),
  };

  DateTime _utc(String texto) {
    final f = DateTime.parse(texto);
    if (f.isUtc) return f;
    return DateTime.utc(
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

  QrFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;

    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'QR_EXPIRED' => const QrFailure.expired(),
      'QR_INVALID' => const QrFailure.tampered(),
      'QR_REVOKED' => const QrFailure.revoked(),
      'QR_UPDATE_REQUIRED' => const QrFailure.updateRequired(),
      'QR_ALREADY_PAID' => const QrFailure.alreadyPaid(),
      'QR_NOT_CONFIGURED' => const QrFailure.unavailable(),
      'INSUFFICIENT_FUNDS' => const QrFailure.insufficientFunds(),
      'SAME_ACCOUNT' => const QrFailure.sameAccount(),
      'CURRENCY_MISMATCH' => const QrFailure.currencyMismatch(),
      'AMOUNT_OUT_OF_RANGE' => const QrFailure.amountOutOfRange(),
      'QR_DAILY_LIMIT' => switch ((
        body['disponible_centimos'],
        Currency.fromCode('${body['moneda']}'),
      )) {
        (final int centimos, final Currency moneda) =>
          QrFailure.dailyLimit(Money(centimos, moneda)),
        _ => const QrFailure.unexpected(),
      },
      'RECIPIENT_NOT_FOUND' ||
      'ACCOUNT_NOT_FOUND' ||
      'ACCOUNT_BLOCKED' => const QrFailure.accountUnavailable(),
      'IDENTIFIER_LOCKED' ||
      'DEVICE_LOCKED' ||
      'RATE_LIMITED' => const QrFailure.locked(),
      // 403 con `intentos_restantes` en la RAÍZ.
      'INVALID_CREDENTIALS' => switch (body['intentos_restantes']) {
        final int n => QrFailure.wrongPin(n),
        _ => const QrFailure.unexpected(),
      },
      _ => const QrFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<QrFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<QrFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      // Un 5xx llega como excepción, pero trae el código del backend.
      if (e.response case final response?) {
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
      }
      return left(
        GlobalFailure.server(switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.connectionError => const QrFailure.network(),
          _ => const QrFailure.unexpected(),
        }),
      );
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
