part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginSubmitted({
    required String identifier,
    required String pin,
  }) = AuthLoginSubmitted;

  const factory AuthEvent.registerSubmitted({
    required String dni,
    String? alias,
    required String pin,
  }) = AuthRegisterSubmitted;

  const factory AuthEvent.signedOut() = AuthSignedOut;

  const factory AuthEvent.sessionChanged(AuthSession? session) =
      _AuthSessionChanged;
}
