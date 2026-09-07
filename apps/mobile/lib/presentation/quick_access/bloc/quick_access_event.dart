part of 'quick_access_bloc.dart';

@freezed
sealed class QuickAccessEvent with _$QuickAccessEvent {
  const factory QuickAccessEvent.digitPressed(int digit) =
      QuickAccessDigitPressed;
  const factory QuickAccessEvent.backspace() = QuickAccessBackspace;
  const factory QuickAccessEvent.biometric() = QuickAccessBiometric;
}
