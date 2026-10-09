part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginSubmitted({
    required String identifier,
    required String pin,
  }) = AuthLoginSubmitted;

  /// El OTP de dispositivo nuevo se verificó: vincula el teléfono y activa la
  /// sesión que quedó pendiente.
  const factory AuthEvent.deviceVerified(AuthSession session, String otpTicket) =
      AuthDeviceVerified;

  /// El usuario volvió a escribir el DNI (o a empezar el PIN): el error y los
  /// intentos restantes eran del intento anterior, quizá de OTRO DNI.
  const factory AuthEvent.formReset() = AuthFormReset;

  const factory AuthEvent.signedOut() = AuthSignedOut;

  const factory AuthEvent.sessionChanged(AuthSession? session) =
      _AuthSessionChanged;
}
