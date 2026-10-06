part of 'biometric_settings_bloc.dart';

enum BiometricSettingsStatus { loading, ready, askingPin, working }

enum BiometricSettingsError { wrongPin, unavailable, generic }

@freezed
abstract class BiometricSettingsState with _$BiometricSettingsState {
  const factory BiometricSettingsState({
    @Default(BiometricSettingsStatus.loading) BiometricSettingsStatus status,
    @Default(false) bool available,
    @Default(false) bool enabled,
    @Default('') String pin,
    BiometricSettingsError? error,
    int? attemptsLeft,
    DateTime? lockedUntil,
    @Default(false) bool justEnabled,
  }) = _BiometricSettingsState;
}
