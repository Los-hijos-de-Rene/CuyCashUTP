part of 'otp_bloc.dart';

@freezed
sealed class OtpEvent with _$OtpEvent {
  /// Abre el reto contra el servicio.
  const factory OtpEvent.started() = OtpStarted;

  const factory OtpEvent.codeChanged(String code) = OtpCodeChanged;

  const factory OtpEvent.submitted() = OtpSubmitted;

  /// Reenviar. Es también la acción principal cuando el código venció.
  const factory OtpEvent.resendRequested() = OtpResendRequested;

  /// Latido del reloj: recalcula enfriamiento y vencimiento por separado.
  const factory OtpEvent.ticked() = OtpTicked;
}
