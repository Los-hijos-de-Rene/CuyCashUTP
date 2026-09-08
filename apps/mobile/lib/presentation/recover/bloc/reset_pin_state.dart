part of 'reset_pin_bloc.dart';

/// Los dos pasos de la pantalla. Uno a la vez: dos filas de seis casillas más
/// aviso, teclado y botón no caben en un teléfono chico.
enum ResetPinStep { crear, confirmar }

enum ResetPinStatus { idle, submitting }

/// Error del paso actual. `samePin` solo puede ocurrir en `crear` y `mismatch`
/// solo en `confirmar`.
enum ResetPinError { samePin, mismatch, weakPin, generic }

@freezed
abstract class ResetPinState with _$ResetPinState {
  const factory ResetPinState({
    @Default(ResetPinStep.crear) ResetPinStep step,

    /// Dígitos del paso ACTIVO. Es lo único que pintan las casillas.
    @Default('') String pin,

    /// PIN elegido en el paso 1, a la espera de confirmación.
    @Default('') String chosenPin,
    @Default(ResetPinStatus.idle) ResetPinStatus status,
    @Default(false) bool done,
    ResetPinError? error,
  }) = _ResetPinState;

  const ResetPinState._();

  bool get isComplete => pin.length == 6;

  /// Con error las casillas se pintan en carmín.
  bool get hasError => error != null;
}
