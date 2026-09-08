part of 'otp_bloc.dart';

/// Eje 1 — el código escrito. Vive de su propio reloj (el TTL).
enum OtpCodeState { empty, incomplete, complete, invalid, expired }

/// Eje 2 — el reenvío. Vive de OTRO reloj (el enfriamiento). Que el
/// enfriamiento llegue a cero no invalida el código vigente.
enum OtpResendState { cooling, available, exhausted }

/// Progreso de la llamada en curso.
enum OtpStatus { loading, idle, submitting }

/// Estado del OTP. Los tres ejes ([codeState], [resendState], [attemptsLeft])
/// son INDEPENDIENTES a propósito: colapsarlos en un solo enum haría que el
/// enfriamiento venciera el código o que un intento fallido reiniciara el
/// contador de reenvíos.
@freezed
abstract class OtpState with _$OtpState {
  const factory OtpState({
    String? challengeId,
    @Default('') String maskedEmail,
    @Default('') String code,
    @Default(OtpCodeState.empty) OtpCodeState codeState,
    @Default(OtpResendState.cooling) OtpResendState resendState,
    @Default(OtpPolicy.maxAttempts) int attemptsLeft,
    @Default(OtpPolicy.maxResends) int resendsLeft,
    @Default(Duration.zero) Duration cooldownRemaining,
    @Default(OtpStatus.loading) OtpStatus status,
    @Default(false) bool verified,
    @Default(false) bool cancelled,
    OtpCancelReason? cancelledReason,
    DateTime? expiresAt,
    DateTime? cooldownUntil,
  }) = _OtpState;

  const OtpState._();

  /// El botón primario solo se habilita con las seis casillas llenas; con el
  /// código vencido cambia de significado (pedir uno nuevo) y vuelve a estar
  /// activo.
  bool get canSubmit =>
      codeState == OtpCodeState.expired ||
      (code.length == 6 && status == OtpStatus.idle);

  /// La fila de reenvío desaparece con el código vencido: ahí pedir un código
  /// nuevo ya es la acción principal, no una alternativa.
  bool get showsResendRow =>
      codeState != OtpCodeState.expired && status != OtpStatus.loading;

  /// La leyenda del spam solo acompaña al reenvío ya disponible.
  bool get showsSpamHint =>
      showsResendRow && resendState == OtpResendState.available;
}
