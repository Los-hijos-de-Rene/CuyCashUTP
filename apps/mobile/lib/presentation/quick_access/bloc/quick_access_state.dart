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
    DateTime? lockedUntil,

    /// Cuánto durará el bloqueo si se agotan los intentos (escala por nivel).
    Duration? nextLockout,
  }) = _QuickAccessState;
}
