part of 'auth_bloc.dart';

/// Progreso del form de auth.
enum FormStatus { idle, submitting }

/// Tipo de error de auth. El bloc no carga texto: la UI traduce con ARB
/// (ver `auth_error_text.dart`).
enum AuthError { invalidCredentials, identifierTaken, weakPin, generic }

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unauthenticated({
    @Default(FormStatus.idle) FormStatus status,
    AuthError? error,
  }) = AuthUnauthenticated;

  const factory AuthState.authenticated(AuthSession session) = AuthAuthenticated;
}
