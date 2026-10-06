part of 'change_pin_bloc.dart';

enum ChangePinStep { actual, nuevo, confirmar }

enum ChangePinStatus { idle, submitting, done }

enum ChangePinError {
  wrongPin,
  weakPin,
  samePin,
  mismatch,
  unknownOutcome,
  generic,
}

@freezed
abstract class ChangePinState with _$ChangePinState {
  const factory ChangePinState({
    @Default(ChangePinStep.actual) ChangePinStep step,

    /// Dígitos del paso activo: lo único que pintan las casillas.
    @Default('') String pin,
    @Default('') String currentPin,
    @Default('') String newPin,
    @Default(ChangePinStatus.idle) ChangePinStatus status,
    ChangePinError? error,
    int? attemptsLeft,
    DateTime? lockedUntil,
    @Default(0) int revokedSessions,
  }) = _ChangePinState;
}
