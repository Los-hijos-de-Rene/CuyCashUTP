part of 'register_bloc.dart';

@freezed
sealed class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.fieldChanged(RegisterField field, String value) =
      RegisterFieldChanged;
  const factory RegisterEvent.captured(DocSide side, Uint8List image) =
      RegisterCaptured;
  const factory RegisterEvent.captureFailed(DocSide side) =
      RegisterCaptureFailed;
  const factory RegisterEvent.faceScanStarted() = RegisterFaceScanStarted;
  /// El KYC aprobó. [kycTicket] es lo que `/register` exige al servidor.
  const factory RegisterEvent.faceScanCompleted({String? kycTicket}) =
      RegisterFaceScanCompleted;
  const factory RegisterEvent.pinDigitPressed(int digit) =
      RegisterPinDigitPressed;
  const factory RegisterEvent.pinBackspace() = RegisterPinBackspace;
  const factory RegisterEvent.biometricToggled(bool value) =
      RegisterBiometricToggled;
  const factory RegisterEvent.stepAdvanced() = RegisterStepAdvanced;
  const factory RegisterEvent.stepBack() = RegisterStepBack;
  const factory RegisterEvent.submitted() = RegisterSubmitted;

  /// "Ir a mi cuenta" en la pantalla de éxito: activa la sesión creada.
  const factory RegisterEvent.accountOpened({required String biometricReason}) =
      RegisterAccountOpened;

  /// La pantalla ya mostró el aviso de "activa la huella después": ahora sí
  /// se abre la sesión (que lleva a /home y cierra este bloc).
  const factory RegisterEvent.biometricNoticeShown() =
      RegisterBiometricNoticeShown;
  const factory RegisterEvent.biometricChecked() = RegisterBiometricChecked;
}
