part of 'register_bloc.dart';

enum CaptureStatus { empty, captured, unreadable }

enum FaceScanStatus { idle, scanning, success }

enum RegisterField { dni, nombres, apellidos, email }

enum DocSide { front, back }

enum FieldError { dniLength, requiredField, emailInvalid }

enum RegisterStatus { editing, submitting }

/// Subpasos del paso 4. El indicador sigue marcando "Paso 4 de 4": los
/// macro-pasos siguen siendo cuatro; esto solo evita meter dos filas de
/// casillas, una checklist, una tarjeta y un teclado en la misma pantalla.
enum SecurityStep { crear, confirmar, biometria }

@freezed
abstract class RegisterDraft with _$RegisterDraft {
  const factory RegisterDraft({
    @Default('') String dni,
    @Default('') String nombres,
    @Default('') String apellidos,
    @Default('') String email,
    @Default(CaptureStatus.empty) CaptureStatus dniFront,
    @Default(CaptureStatus.empty) CaptureStatus dniBack,

    /// Bytes de las capturas. Viven en memoria hasta la verificación y se
    /// sueltan ahí: son datos de identidad, no van a disco.
    Uint8List? dniFrontImage,
    Uint8List? dniBackImage,
    @Default(FaceScanStatus.idle) FaceScanStatus faceStatus,
    @Default('') String pin,

    /// Segunda escritura del PIN. Sin ella, un error de tecleo deja al usuario
    /// fuera de la cuenta que acaba de abrir.
    @Default('') String confirmPin,
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
    @Default(SecurityStep.crear) SecurityStep securityStep,
    @Default(false) bool pinMismatch,
    @Default(RegisterDraft()) RegisterDraft draft,
    @Default(RegisterErrors()) RegisterErrors errors,
    @Default(RegisterStatus.editing) RegisterStatus status,
    AuthError? submitError,
    // Cuenta creada tras un registro exitoso (aún NO autenticada): dispara la
    // pantalla de éxito. Se activa con `RegisterEvent.accountOpened`.
    AuthSession? createdSession,
    // ¿El teléfono tiene sensor? Sin él, el paso 4C no ofrece la huella.
    @Default(false) bool biometricAvailable,
    // La huella no pudo activarse tras el alta. No deshace la cuenta.
    @Default(false) bool biometricEnrollFailed,
  }) = _RegisterState;

  /// ¿El paso actual permite avanzar / finalizar?
  bool get canAdvance => switch (step) {
    0 => RegisterValidators.dataValid(draft),
    1 =>
      draft.dniFront == CaptureStatus.captured &&
          draft.dniBack == CaptureStatus.captured,
    2 => draft.faceStatus == FaceScanStatus.success,
    // En el paso 4 solo hay botón al final: crear y confirmar avanzan
    // solos con el sexto dígito.
    _ =>
      securityStep == SecurityStep.biometria &&
          RegisterValidators.pinValid(draft.pin),
  };

  /// Una regla por cada condición que el sistema comprueba, ni más ni menos.
  /// Ninguna puede darse por cumplida antes de tiempo: un indicador que se
  /// adelanta miente, y una condición sin regla deja al usuario atascado.
  bool get pinHasSixDigits => RegisterValidators.hasSixDigits(draft.pin);

  bool get pinHasNoRepeatedDigit =>
      RegisterValidators.hasNoRepeatedDigit(draft.pin);

  bool get pinHasNoSequence => RegisterValidators.hasNoSequence(draft.pin);
}
