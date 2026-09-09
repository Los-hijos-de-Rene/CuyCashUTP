part of 'register_bloc.dart';

@freezed
sealed class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.fieldChanged(RegisterField field, String value) =
      RegisterFieldChanged;
  const factory RegisterEvent.captured(DocSide side, Uint8List image) =
      RegisterCaptured;
  const factory RegisterEvent.captureFailed(DocSide side) = RegisterCaptureFailed;
  const factory RegisterEvent.faceScanStarted() = RegisterFaceScanStarted;
  const factory RegisterEvent.faceScanCompleted() = RegisterFaceScanCompleted;
  const factory RegisterEvent.pinDigitPressed(int digit) =
      RegisterPinDigitPressed;
  const factory RegisterEvent.pinBackspace() = RegisterPinBackspace;
  const factory RegisterEvent.biometricToggled(bool value) =
      RegisterBiometricToggled;
  const factory RegisterEvent.stepAdvanced() = RegisterStepAdvanced;
  const factory RegisterEvent.stepBack() = RegisterStepBack;
  const factory RegisterEvent.submitted() = RegisterSubmitted;

  /// "Ir a mi cuenta" en la pantalla de éxito: activa la sesión creada.
  const factory RegisterEvent.accountOpened() = RegisterAccountOpened;
}
