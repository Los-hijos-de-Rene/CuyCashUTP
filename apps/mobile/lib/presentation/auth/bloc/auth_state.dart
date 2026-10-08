part of 'auth_bloc.dart';

/// Progreso del form de auth.
enum FormStatus { idle, submitting }

/// Tipo de error de auth. El bloc no carga texto: la UI traduce con ARB
/// (ver `auth_error_text.dart`).
enum AuthError {
  invalidCredentials,
  identifierTaken,
  weakPin,
  pinUnchanged,
  identityNotVerified,
  generic
}

@freezed
sealed class AuthState with _$AuthState {
  /// Sin sesión. `pendingDeviceSession` no es null cuando el PIN fue correcto
  /// pero el teléfono aún no está vinculado. `lockedUntil` no es null cuando se
  /// agotaron los intentos: la pantalla sale a /bloqueado.
  const factory AuthState.unauthenticated({
    @Default(FormStatus.idle) FormStatus status,
    @Default(LockoutPolicy.maxAttempts) int attemptsLeft,
    AuthError? error,
    AuthSession? pendingDeviceSession,
    DateTime? lockedUntil,
    /// Cuánto durará el bloqueo si se agotan los intentos (escala por nivel).
    Duration? nextLockout,
  }) = AuthUnauthenticated;

  const factory AuthState.authenticated(AuthSession session) = AuthAuthenticated;
}
