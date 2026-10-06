import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import 'auth_failure.dart';
import 'auth_session.dart';

/// Contrato de auth (domain). Nunca lanza: devuelve `Result`. Impl real =
/// Supabase (local/prod); su `Memory*` funcional vive en infrastructure.
abstract interface class AuthRepository {
  /// Sesión actual cacheada (sincrónica), o null.
  AuthSession? get currentSession;

  /// Emite la sesión vigente ante cambios (login/register/logout).
  Stream<AuthSession?> sessionChanges();

  /// Valida DNI/Alias + PIN y devuelve la sesión SIN iniciarla. Es el paso que
  /// permite intercalar la verificación de un teléfono nuevo antes de dar
  /// acceso: quien la llama decide si `activate` o si manda al OTP.
  FutureResult<AuthFailure, AuthSession> authenticate({
    required String identifier,
    required String pin,
  });

  /// Inicia sesión con DNI/Alias + PIN (valida y activa en un solo paso).
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  });

  /// Registra una cuenta nueva con el perfil completo (DNI + datos + PIN 6).
  /// Crea la cuenta y devuelve la sesión (con alias) pero NO inicia sesión:
  /// usar [activate] para autenticar (tras la pantalla de éxito).
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  });

  /// Activa (inicia sesión) una sesión ya creada por [register] o validada por
  /// [authenticate], y la emite.
  ///
  /// [otpTicket] es obligatorio contra el backend real cuando el teléfono aún
  /// no es de confianza: es lo que acredita que se pasó por el código. Tras un
  /// alta no hace falta, porque el registro ya devuelve la sesión.
  ///
  /// Devuelve `Result` y no `void` a propósito: cuando no podía fallar "hacia
  /// fuera", una activación imposible dejaba el botón de la pantalla de éxito
  /// muerto, sin éxito ni error que mostrar.
  FutureResult<AuthFailure, Unit> activate(AuthSession session,
      {String? otpTicket});

  /// ¿El PIN propuesto es el que la cuenta ya tiene? Permite rechazarlo al
  /// terminar de escribirlo, sin esperar a que el usuario teclee doce dígitos.
  ///
  /// Solo debe existir DENTRO de una recuperación ya verificada por OTP y con
  /// límite de intentos: preguntado a discreción sería un oráculo del PIN.
  FutureResult<AuthFailure, bool> isCurrentPin({
    required String identifier,
    required String pin,
    String? otpTicket,
  });

  /// Cambia el PIN tras una recuperación verificada por OTP. NO inicia sesión:
  /// restablecer no otorga acceso, el usuario debe entrar con el PIN nuevo.
  /// Invalida además las sesiones de los demás dispositivos.
  FutureResult<AuthFailure, Unit> resetPin({
    required String identifier,
    required String newPin,
    String? otpTicket,
  });

  FutureResult<AuthFailure, Unit> signOut();
}
