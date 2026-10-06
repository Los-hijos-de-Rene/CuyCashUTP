part of 'change_pin_bloc.dart';

@freezed
sealed class ChangePinEvent with _$ChangePinEvent {
  const factory ChangePinEvent.digitPressed(int digit) = ChangePinDigitPressed;
  const factory ChangePinEvent.backspace() = ChangePinBackspace;
  const factory ChangePinEvent.back() = ChangePinBack;
}
