import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Impl real contra `services/api`.
///
/// Reemplaza al stub de Supabase: el modelo de identidad de CuyCash es
/// DNI + PIN, y Supabase Auth está construido alrededor de email+contraseña
/// (ver ADR-0002).
///
/// Nada de lo que decide seguridad se calcula aquí: los intentos restantes y el
/// bloqueo vienen del servidor. Llevarlos en el teléfono permitiría ponerlos a
/// cero reinstalando la app.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({required Dio dio, required this.deviceId}) : _dio = dio;

  factory HttpAuthRepository.withConfig({
    required String baseUrl,
    required String deviceId,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 70),
  }) =>
      HttpAuthRepository(
        deviceId: deviceId,
        dio: Dio(BaseOptions(
          baseUrl: baseUrl,
          // Las dos esperas son distintas a propósito. El plan gratuito del
          // hosting suspende el servicio tras unos minutos sin tráfico: la
          // primera petición conecta en el acto —responde el proxy— y después
          // se queda esperando a que el contenedor arranque, cerca de un
          // minuto. Con un único valor hay que elegir entre cortar ese
          // arranque en frío o tardar más de un minuto en avisar de que no hay
          // red. Separadas, se consigue lo uno y lo otro.
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          headers: {'X-Device-Id': deviceId},
          // Los 4xx son respuestas de negocio (PIN incorrecto, bloqueo), no
          // excepciones: se leen y se mapean a failures.
          validateStatus: (status) => status != null && status < 500,
        )),
      );

  final Dio _dio;
  final String deviceId;

  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _session;

  /// Token de la sesión abierta. Vive en memoria: persistirlo es trabajo del
  /// almacén cifrado y todavía no está cableado.
  String? _sessionToken;

  /// Acredita "el PIN fue correcto" mientras se verifica el dispositivo.
  String? _pendingToken;

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> sessionChanges() => _controller.stream;

  @override
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/auth/register',
          data: {
            'dni': dni,
            'nombres': nombres,
            'apellidos': apellidos,
            'email': email,
            'pin': pin,
          },
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data ?? const {};
        // Registrarse NO abre sesión: la app la activa tras la pantalla de
        // éxito.
        return right(AuthSession(
          userId: data['id'] as String? ?? '',
          identifier: dni,
          alias: data['alias'] as String?,
          fullName: data['full_name'] as String?,
        ));
      });

  @override
  FutureResult<AuthFailure, AuthSession> authenticate({
    required String identifier,
    required String pin,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/auth/authenticate',
          data: {'identifier': identifier, 'pin': pin},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data ?? const {};
        final session = AuthSession(
          userId: (data['user'] as Map?)?['id'] as String? ?? '',
          identifier: identifier,
          alias: (data['user'] as Map?)?['alias'] as String?,
        );

        if (data['result'] == 'session') {
          // El teléfono ya era de confianza: la sesión viene hecha.
          _sessionToken = data['session_token'] as String?;
          _pendingToken = null;
        } else {
          // PIN correcto pero teléfono desconocido: falta el OTP. La sesión
          // NO se abre hasta que llegue el ticket.
          _sessionToken = null;
          _pendingToken = data['pending_token'] as String?;
        }
        return right(session);
      });

  @override
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) async {
    final result = await authenticate(identifier: identifier, pin: pin);
    return result.flatMap((session) {
      if (_sessionToken == null) {
        // Sin sesión abierta, `signIn` no puede cumplir su promesa: hace falta
        // verificar el dispositivo primero.
        return left(const GlobalFailure.server(AuthFailure.authUnavailable()));
      }
      _emit(session);
      return right(session);
    });
  }

  @override
  Future<void> activate(AuthSession session, {String? otpTicket}) async {
    if (_sessionToken != null) {
      _emit(session);
      return;
    }
    final pending = _pendingToken;
    if (pending == null || otpTicket == null) return;

    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/sessions',
      data: {'pending_token': pending, 'otp_ticket': otpTicket},
    );
    if (response.statusCode != 200) return;
    _sessionToken = response.data?['session_token'] as String?;
    _pendingToken = null;
    _emit(session);
  }

  @override
  FutureResult<AuthFailure, bool> isCurrentPin({
    required String identifier,
    required String pin,
    String? otpTicket,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/auth/pin/check-current',
          data: {'otp_ticket': otpTicket, 'pin': pin},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));
        return right(response.data?['is_current'] as bool? ?? false);
      });

  @override
  FutureResult<AuthFailure, Unit> resetPin({
    required String identifier,
    required String newPin,
    String? otpTicket,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/auth/pin/reset',
          data: {'otp_ticket': otpTicket, 'new_pin': newPin},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));
        // El servidor revocó todas las sesiones, incluida la de este teléfono.
        _sessionToken = null;
        _session = null;
        return right(unit);
      });

  @override
  FutureResult<AuthFailure, Unit> signOut() => _guard(() async {
        final token = _sessionToken;
        if (token != null) {
          await _dio.delete<void>(
            '/v1/auth/sessions/current',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        }
        _sessionToken = null;
        _session = null;
        _controller.add(null);
        return right(unit);
      });

  /// Traduce el `code` estable del backend a un failure de dominio.
  ///
  /// Se mapea por código y NUNCA por el texto: el `detail` está para redactarse
  /// mejor, y atarse a él haría que un cambio de copy rompiera la app en
  /// silencio (la lección del servicio de KYC, R2 del ADR-0001).
  AuthFailure? _failureFor(Response<Map<String, dynamic>> response) {
    final status = response.statusCode ?? 0;
    if (status == 200 || status == 201) return null;

    final data = response.data ?? const {};
    return switch (data['code']) {
      'INVALID_CREDENTIALS' => switch (data['attempts_left']) {
          final int left => AuthFailure.tooManyAttempts(left),
          _ => const AuthFailure.invalidCredentials(),
        },
      'IDENTIFIER_LOCKED' || 'DEVICE_LOCKED' => switch (
            DateTime.tryParse('${data['locked_until']}')) {
          final DateTime until => AuthFailure.accessLocked(until),
          _ => const AuthFailure.invalidCredentials(),
        },
      'IDENTIFIER_TAKEN' => const AuthFailure.identifierTaken(),
      'WEAK_PIN' => const AuthFailure.weakPin(),
      'PIN_UNCHANGED' => const AuthFailure.pinUnchanged(),
      _ => const AuthFailure.authUnavailable(),
    };
  }

  void _emit(AuthSession session) {
    _session = session;
    _controller.add(session);
  }

  Future<Either<GlobalFailure<AuthFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<AuthFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (_) {
      return left(const GlobalFailure.server(AuthFailure.authUnavailable()));
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
