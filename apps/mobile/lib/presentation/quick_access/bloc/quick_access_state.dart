part of 'quick_access_bloc.dart';

enum QuickAccessStatus { idle, verifying }

@freezed
abstract class QuickAccessState with _$QuickAccessState {
  const factory QuickAccessState({
    required RememberedUser user,
    @Default('') String pin,
    @Default(QuickAccessStatus.idle) QuickAccessStatus status,
    @Default(LockoutPolicy.maxAttempts) int attemptsLeft,
    @Default(false) bool lastWrong,

    /// Hay credencial guardada y el sistema puede pedir la huella.
    @Default(false) bool biometricAvailable,

    /// El servidor rechazó la credencial: se borró y hay que entrar con PIN.
    @Default(false) bool biometricRevoked,

    /// La huella se leyó pero no se pudo abrir sesión (servidor o red): se
    /// avisa y se puede reintentar o usar el PIN.
    @Default(false) bool biometricFailed,

    /// PIN correcto, pero este teléfono dejó de ser de confianza (lo
    /// desvincularon): la pantalla lleva al login, que corre el OTP.
    @Default(false) bool needsDeviceVerification,
    DateTime? lockedUntil,

    /// Cuánto durará el bloqueo si se agotan los intentos (escala por nivel).
    Duration? nextLockout,
  }) = _QuickAccessState;
}
