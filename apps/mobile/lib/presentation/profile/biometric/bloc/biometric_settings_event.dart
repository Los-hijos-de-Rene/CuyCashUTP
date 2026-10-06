part of 'biometric_settings_bloc.dart';

@freezed
sealed class BiometricSettingsEvent with _$BiometricSettingsEvent {
  const factory BiometricSettingsEvent.started() = BiometricSettingsStarted;
  const factory BiometricSettingsEvent.enableRequested() =
      BiometricSettingsEnableRequested;

  /// [reason] es el texto del diálogo del sistema (viene del ARB).
  const factory BiometricSettingsEvent.pinDigit(
    int digit, {
    required String reason,
  }) = BiometricSettingsPinDigit;
  const factory BiometricSettingsEvent.pinBackspace() =
      BiometricSettingsPinBackspace;
  const factory BiometricSettingsEvent.pinCancelled() =
      BiometricSettingsPinCancelled;
  const factory BiometricSettingsEvent.disableRequested() =
      BiometricSettingsDisableRequested;
}
