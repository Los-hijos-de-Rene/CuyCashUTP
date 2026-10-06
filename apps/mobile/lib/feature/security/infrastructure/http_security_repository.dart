import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/linked_device.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';

/// Impl real contra `services/api`: `/v1/auth/pin/change`,
/// `/v1/auth/biometric/*`, `/v1/devices*`. [dio] de `buildAuthenticatedDio`.
///
/// Un 401 `INVALID_CREDENTIALS` aquí es "PIN actual errado", no sesión
/// vencida: el interceptor solo cierra sesión ante `UNAUTHENTICATED` o sin
/// `code`.
class HttpSecurityRepository implements SecurityRepository {
  HttpSecurityRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) => _guard(() async {
    final response = await _dio.post<dynamic>(
      '/v1/auth/pin/change',
      data: {'current_pin': current, 'new_pin': nuevo},
    );
    if (_failureFor(response) case final f?) {
      return left(GlobalFailure.server(f));
    }
    return right(_cuerpo(response)['revoked_sessions'] as int);
  });

  @override
  FutureResult<SecurityFailure, List<LinkedDevice>> devices() =>
      _guard(() async {
        final response = await _dio.get<dynamic>('/v1/devices');
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right([
          for (final d in _cuerpo(response)['dispositivos'] as List)
            _device(d as Map<String, dynamic>),
        ]);
      });

  @override
  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) =>
      _guard(() async {
        final response = await _dio.delete<dynamic>(
          '/v1/devices/${Uri.encodeComponent(id)}',
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(unit);
      });

  @override
  FutureResult<SecurityFailure, String> enrollBiometric(String pin) =>
      _guard(() async {
        final response = await _dio.post<dynamic>(
          '/v1/auth/biometric/enroll',
          data: {'pin': pin},
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(_cuerpo(response)['credential'] as String);
      });

  @override
  FutureResult<SecurityFailure, Unit> revokeBiometric() => _guard(() async {
    final response = await _dio.delete<dynamic>('/v1/auth/biometric/current');
    if (_failureFor(response) case final f?) {
      return left(GlobalFailure.server(f));
    }
    return right(unit);
  });

  LinkedDevice _device(Map<String, dynamic> j) => LinkedDevice(
    id: j['id'] as String,
    nombre: j['nombre'] as String?,
    plataforma: j['plataforma'] as String?,
    vinculadoEl: DateTime.parse(j['vinculado_el'] as String).toUtc(),
    ultimoUso: DateTime.parse(j['ultimo_uso'] as String).toUtc(),
    esEste: j['es_este'] as bool,
    conHuella: j['con_huella'] as bool,
  );

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  SecurityFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;
    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'INVALID_CREDENTIALS' => switch (body['attempts_left']) {
        final int n => SecurityFailure.wrongPin(n),
        _ => const SecurityFailure.wrongPin(0),
      },
      'IDENTIFIER_LOCKED' || 'DEVICE_LOCKED' => switch (DateTime.tryParse(
        '${body['locked_until']}',
      )) {
        final DateTime until => SecurityFailure.locked(until),
        _ => const SecurityFailure.unexpected(),
      },
      'WEAK_PIN' => const SecurityFailure.weakPin(),
      'PIN_UNCHANGED' => const SecurityFailure.pinUnchanged(),
      'CANNOT_UNLINK_CURRENT' => const SecurityFailure.cannotUnlinkCurrent(),
      'DEVICE_NOT_FOUND' => const SecurityFailure.deviceNotFound(),
      'UNAUTHENTICATED' => const SecurityFailure.unauthenticated(),
      _ when status == 401 => const SecurityFailure.unauthenticated(),
      _ => const SecurityFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<SecurityFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<SecurityFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      return left(
        GlobalFailure.server(switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.connectionError => const SecurityFailure.network(),
          _ => const SecurityFailure.unexpected(),
        }),
      );
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
