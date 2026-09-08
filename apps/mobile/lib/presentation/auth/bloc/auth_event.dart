part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginSubmitted({
    required String identifier,
    required String pin,
  }) = AuthLoginSubmitted;

  /// El OTP de dispositivo nuevo se verificó: vincula el teléfono y activa la
  /// sesión que quedó pendiente.
  const factory AuthEvent.deviceVerified(AuthSession session) =
      AuthDeviceVerified;

  const factory AuthEvent.signedOut() = AuthSignedOut;

  const factory AuthEvent.sessionChanged(AuthSession? session) =
      _AuthSessionChanged;
}
