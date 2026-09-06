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

  /// Inicia sesión con DNI/Alias + PIN.
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  });

  /// Registra una cuenta nueva con el perfil completo (DNI + datos + PIN 6).
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  });

  FutureResult<AuthFailure, Unit> signOut();
}
