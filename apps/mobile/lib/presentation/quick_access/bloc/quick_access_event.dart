part of 'quick_access_bloc.dart';

@freezed
sealed class QuickAccessEvent with _$QuickAccessEvent {
  const factory QuickAccessEvent.digitPressed(int digit) =
      QuickAccessDigitPressed;
  const factory QuickAccessEvent.backspace() = QuickAccessBackspace;
  const factory QuickAccessEvent.started() = QuickAccessStarted;
  const factory QuickAccessEvent.biometric({required String reason}) =
      QuickAccessBiometric;
}
