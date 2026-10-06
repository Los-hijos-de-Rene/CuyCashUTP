import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/account.dart';
import '../domain/account_failure.dart';
import '../domain/account_repository.dart';
import '../domain/movement.dart';

/// Impl real contra `services/api` (`GET /v1/accounts`, `/movements`).
///
/// [dio] debe venir de `buildAuthenticatedDio`: el token y `X-Device-Id` los
/// pone su interceptor, este repositorio no sabe de ellos.
///
/// Los montos llegan en céntimos enteros y se quedan en `int` hasta [Money];
/// las fechas llegan en UTC con sufijo `Z` y se parsean como UTC.
class HttpAccountRepository implements AccountRepository {
  HttpAccountRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() => _guard(() async {
    final response = await _dio.get<dynamic>('/v1/accounts');
    final failure = _failureFor(response);
    if (failure != null) return left(GlobalFailure.server(failure));

    final cuentas = _cuerpo(response)['cuentas'] as List;
    return right([for (final c in cuentas) _cuenta(c as Map<String, dynamic>)]);
  });

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/v1/accounts/${Uri.encodeComponent(cuentaId)}/movements',
      queryParameters: {'cursor': ?cursor},
    );
    final failure = _failureFor(response);
    if (failure != null) return left(GlobalFailure.server(failure));

    final data = _cuerpo(response);
    return right(
      MovementPage(
        items: [
          for (final m in data['movimientos'] as List)
            _movimiento(m as Map<String, dynamic>),
        ],
        nextCursor: data['next_cursor'] as String?,
      ),
    );
  });

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(
    String transactionId,
  ) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/v1/movements/${Uri.encodeComponent(transactionId)}',
    );
    final failure = _failureFor(response);
    if (failure != null) return left(GlobalFailure.server(failure));

    return right(_detalle(_cuerpo(response)));
  });

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  Account _cuenta(Map<String, dynamic> j) {
    final moneda = _moneda(j['moneda']);
    return Account(
      id: j['id'] as String,
      numero: j['numero'] as String,
      tipo: j['tipo'] as String,
      moneda: moneda,
      estado: j['estado'] as String,
      saldoDisponible: Money(j['saldo_disponible'] as int, moneda),
      saldoContable: Money(j['saldo_contable'] as int, moneda),
    );
  }

  /// Una moneda desconocida NO se adivina: pintar dólares como soles es peor
  /// que fallar. La `FormatException` la recoge `_guard` como inesperado.
  Currency _moneda(Object? code) => switch (code) {
    final String c =>
      Currency.fromCode(c) ?? (throw FormatException('Moneda desconocida: $c')),
    _ => throw const FormatException('Objeto sin moneda'),
  };

  Movement _movimiento(Map<String, dynamic> j) {
    final moneda = _moneda(j['moneda']);
    return Movement(
      transactionId: j['transaction_id'] as String,
      tipo: _tipo(j['tipo'] as String),
      direccion: _direccion(j['direccion'] as String),
      monto: Money(j['monto'] as int, moneda),
      contraparte: j['contraparte'] as String?,
      motivo: j['motivo'] as String?,
      saldoPosterior: Money(j['saldo_posterior'] as int, moneda),
      fecha: _fecha(j['created_at'] as String),
    );
  }

  MovementDetail _detalle(Map<String, dynamic> j) {
    final moneda = _moneda(j['moneda']);
    return MovementDetail(
      transactionId: j['transaction_id'] as String,
      tipo: _tipo(j['tipo'] as String),
      direccion: _direccion(j['direccion'] as String),
      monto: Money(j['monto'] as int, moneda),
      contraparte: j['contraparte'] as String?,
      motivo: j['motivo'] as String?,
      saldoPosterior: Money(j['saldo_posterior'] as int, moneda),
      fecha: _fecha(j['created_at'] as String),
      estado: j['estado'] as String,
      cuentaDestinoMasked: j['cuenta_destino_masked'] as String?,
    );
  }

  MovementKind _tipo(String tipo) => switch (tipo) {
    'transferencia' => MovementKind.transferencia,
    'recarga' => MovementKind.recarga,
    _ => MovementKind.otro,
  };

  /// Un sentido desconocido NO se adivina: signar mal un monto es peor que
  /// fallar. La `FormatException` la recoge `_guard` como inesperado.
  MovementDirection _direccion(String d) => switch (d) {
    'debito' => MovementDirection.debito,
    'credito' => MovementDirection.credito,
    _ => throw FormatException('Dirección desconocida: $d'),
  };

  /// El contrato es UTC con `Z`. Si faltara el sufijo, `DateTime.parse` lo
  /// leería como hora LOCAL y el movimiento saldría a horas equivocadas: se
  /// fuerza UTC en ese caso (el backend siempre escribe en UTC).
  DateTime _fecha(String texto) {
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

  /// Traduce estado y `code` estable (cuerpo PLANO `{code, detail}`) a un
  /// failure. Se mapea por código y NUNCA por el texto de `detail`.
  AccountFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;
    if (status == 401) return const AccountFailure.unauthenticated();

    final data = response.data;
    final code = data is Map ? data['code'] : null;
    return switch ((status, code)) {
      (404, 'ACCOUNT_NOT_FOUND' || 'MOVEMENT_NOT_FOUND') =>
        const AccountFailure.accountNotFound(),
      _ => const AccountFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<AccountFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<AccountFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      return left(
        GlobalFailure.server(switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.connectionError => const AccountFailure.network(),
          _ => const AccountFailure.unexpected(),
        }),
      );
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
