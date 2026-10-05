part of 'topup_bloc.dart';

/// `editing`: el usuario elige el monto (también vuelve aquí tras un fallo,
/// con todo intacto). `submitting`: la recarga va en vuelo; no admite otra.
/// `done`: hay constancia.
enum TopUpStatus { editing, submitting, done }

@freezed
abstract class TopUpState with _$TopUpState {
  const factory TopUpState({
    @Default(TopUpStatus.editing) TopUpStatus status,
    @Default('') String cuentaId,
    Money? monto,

    /// Identifica la INTENCIÓN de recargar este monto. Nace al abrir la
    /// pantalla, cambia solo si cambia el monto y jamás entre reintentos.
    @Default('') String idempotencyKey,
    TransferFailure? failure,

    /// La recarga falló sin que se sepa si se acreditó (red, 429, inesperado),
    /// o la clave se recuperó de un intento anterior sin resolver. Sella la
    /// intención: no se edita el monto, solo reintentar con la MISMA clave o
    /// salir con aviso.
    @Default(false) bool outcomeUnknown,

    /// Había una operación sin resolver de este usuario al abrir la pantalla.
    @Default(false) bool pendingElsewhere,

    /// La clave de este intento NO se pudo guardar.
    @Default(false) bool keyUnsaved,
    TransferReceipt? constancia,
  }) = _TopUpState;
}
