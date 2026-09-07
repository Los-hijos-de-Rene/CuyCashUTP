part of 'register_bloc.dart';

enum CaptureStatus { empty, captured, unreadable }

enum FaceScanStatus { idle, scanning, success }

enum RegisterField { dni, nombres, apellidos, email }

enum DocSide { front, back }

enum FieldError { dniLength, requiredField, emailInvalid }

enum RegisterStatus { editing, submitting }

@freezed
abstract class RegisterDraft with _$RegisterDraft {
  const factory RegisterDraft({
    @Default('') String dni,
    @Default('') String nombres,
    @Default('') String apellidos,
    @Default('') String email,
    @Default(CaptureStatus.empty) CaptureStatus dniFront,
    @Default(CaptureStatus.empty) CaptureStatus dniBack,
    @Default(FaceScanStatus.idle) FaceScanStatus faceStatus,
    @Default('') String pin,
    @Default(true) bool biometricEnabled,
  }) = _RegisterDraft;
}

@freezed
abstract class RegisterErrors with _$RegisterErrors {
  const RegisterErrors._();
  const factory RegisterErrors({
    FieldError? dni,
    FieldError? nombres,
    FieldError? apellidos,
    FieldError? email,
    @Default(false) bool showBanner,
  }) = _RegisterErrors;

  int get count =>
      [dni, nombres, apellidos, email].where((e) => e != null).length;
}

@freezed
abstract class RegisterState with _$RegisterState {
  const RegisterState._();
  const factory RegisterState({
    @Default(0) int step,
    @Default(RegisterDraft()) RegisterDraft draft,
    @Default(RegisterErrors()) RegisterErrors errors,
    @Default(RegisterStatus.editing) RegisterStatus status,
    AuthError? submitError,
    // Cuenta creada tras un registro exitoso (aún NO autenticada): dispara la
    // pantalla de éxito. Se activa con `RegisterEvent.accountOpened`.
    AuthSession? createdSession,
  }) = _RegisterState;

  /// ¿El paso actual permite avanzar / finalizar?
  bool get canAdvance => switch (step) {
        0 => RegisterValidators.dataValid(draft),
        1 => draft.dniFront == CaptureStatus.captured &&
            draft.dniBack == CaptureStatus.captured,
        2 => draft.faceStatus == FaceScanStatus.success,
        _ => RegisterValidators.pinValid(draft.pin),
      };
}
