part of 'reset_pin_bloc.dart';

@freezed
sealed class ResetPinEvent with _$ResetPinEvent {
  const factory ResetPinEvent.digitPressed(int digit) = ResetPinDigitPressed;
  const factory ResetPinEvent.backspace() = ResetPinBackspace;

  /// Vuelve del paso 2 al paso 1 (la X y el gesto de retroceso del sistema).
  const factory ResetPinEvent.backToFirstStep() = ResetPinBackToFirstStep;
}
