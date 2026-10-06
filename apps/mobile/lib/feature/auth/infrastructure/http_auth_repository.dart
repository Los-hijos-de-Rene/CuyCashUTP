import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/http/session_token_holder.dart';
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
  /// [dio] debe venir de `buildAuthenticatedDio` y compartir [tokenHolder]:
  /// el interceptor adjunta la cabecera, este repositorio solo escribe el
  /// token que recibe del servidor.
  HttpAuthRepository({
    required Dio dio,
    required this.deviceId,
    required SessionTokenHolder tokenHolder,
  })  : _dio = dio,
        _tokenHolder = tokenHolder;

  final Dio _dio;
  final SessionTokenHolder _tokenHolder;
  final String deviceId;

  final _controller = StreamController<AuthSession?>.broadcast();
  AuthSession? _session;

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
        // El alta YA abre sesión y vincula este teléfono: se guarda el token
        // para que "Ir a mi cuenta" solo tenga que emitir la sesión.
        _tokenHolder.token = data['session_token'] as String?;
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
          _tokenHolder.token = data['session_token'] as String?;
          _pendingToken = null;
        } else {
          // PIN correcto pero teléfono desconocido: falta el OTP. La sesión
          // NO se abre hasta que llegue el ticket.
          _tokenHolder.clear();
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
      if (_tokenHolder.token == null) {
        // Sin sesión abierta, `signIn` no puede cumplir su promesa: hace falta
        // verificar el dispositivo primero.
        return left(const GlobalFailure.server(AuthFailure.authUnavailable()));
      }
      _emit(session);
      return right(session);
    });
  }

  @override
  FutureResult<AuthFailure, Unit> activate(AuthSession session,
          {String? otpTicket}) =>
      _guard(() async {
        // Ya hay token: lo deja el alta, o una sesión abierta antes.
        if (_tokenHolder.token != null) {
          _emit(session);
          return right(unit);
        }

        // Camino del login desde un teléfono desconocido: hace falta el
        // pendiente de `authenticate` y el ticket del OTP de dispositivo.
        final pending = _pendingToken;
        if (pending == null || otpTicket == null) {
          // Antes esto era un `return` mudo, y el botón de la pantalla de
          // éxito moría sin decir nada. Ahora quien llama puede mostrarlo.
          return left(const GlobalFailure.server(AuthFailure.authUnavailable()));
        }

        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/auth/sessions',
          data: {'pending_token': pending, 'otp_ticket': otpTicket},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final token = response.data?['session_token'] as String?;
        if (token == null) {
          return left(const GlobalFailure.server(AuthFailure.authUnavailable()));
        }
        _tokenHolder.token = token;
        _pendingToken = null;
        _emit(session);
        return right(unit);
      });

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
        _tokenHolder.clear();
        _session = null;
        return right(unit);
      });

  @override
  FutureResult<AuthFailure, AuthSession> signInWithBiometric({
    required String dni,
    required String credential,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/auth/sessions/biometric',
          data: {'dni': dni, 'credential': credential},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data ?? const {};
        final user = data['user'] as Map? ?? const {};
        _tokenHolder.token = data['session_token'] as String?;
        final session = AuthSession(
          userId: user['id'] as String? ?? '',
          identifier: dni,
          alias: user['alias'] as String?,
        );
        _emit(session);
        return right(session);
      });

  @override
  FutureResult<AuthFailure, Unit> signOut() => _guard(() async {
        final token = _tokenHolder.token;
        // El holder se vacía antes de llamar: así el DELETE no vuelve a pasar
        // por el aviso de sesión vencida. Lleva la cabecera explícita porque
        // revoca ese token concreto, que ya no está en el holder.
        _tokenHolder.clear();
        try {
          if (token != null) {
            await _dio.delete<void>(
              '/v1/auth/sessions/current',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
          }
        } on DioException catch (_) {
          // Revocar en el servidor es de mejor esfuerzo (sin red o con el
          // hosting arrancando en frío puede fallar). El token quedará válido
          // hasta que venza en el servidor.
        } finally {
          // El cierre local ocurre PASE LO QUE PASE, incluso ante una
          // excepción inesperada: es lo único que lleva al usuario al login.
          _session = null;
          _controller.add(null);
        }
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
      'BIOMETRIC_REVOKED' => const AuthFailure.biometricRevoked(),
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
