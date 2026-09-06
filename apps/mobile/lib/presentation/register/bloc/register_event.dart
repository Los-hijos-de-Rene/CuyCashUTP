part of 'register_bloc.dart';

@freezed
sealed class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.fieldChanged(RegisterField field, String value) =
      RegisterFieldChanged;
  const factory RegisterEvent.captured(DocSide side) = RegisterCaptured;
  const factory RegisterEvent.captureFailed(DocSide side) = RegisterCaptureFailed;
  const factory RegisterEvent.faceScanStarted() = RegisterFaceScanStarted;
  const factory RegisterEvent.faceScanCompleted() = RegisterFaceScanCompleted;
  const factory RegisterEvent.pinChanged(String pin) = RegisterPinChanged;
  const factory RegisterEvent.biometricToggled(bool value) =
      RegisterBiometricToggled;
  const factory RegisterEvent.stepAdvanced() = RegisterStepAdvanced;
  const factory RegisterEvent.stepBack() = RegisterStepBack;
  const factory RegisterEvent.submitted() = RegisterSubmitted;
}
