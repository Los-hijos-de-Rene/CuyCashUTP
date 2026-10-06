part of 'transfer_bloc.dart';

/// `idle`: sin destinatario (nada buscado, o la búsqueda falló).
/// `resolving`: buscando el DNI.
/// `ready`: destinatario resuelto; también vuelve aquí un envío fallido, con
/// todo lo que el usuario ya eligió intacto.
/// `submitting`: el envío va en vuelo; no admite otro.
/// `done`: hay constancia.
enum TransferStatus { idle, resolving, ready, submitting, done }

@freezed
abstract class TransferState with _$TransferState {
  const factory TransferState({
    @Default(TransferStatus.idle) TransferStatus status,
    Account? cuenta,
    Recipient? destinatario,
    Money? monto,
    String? motivo,

    /// "Guardar como frecuente": se aplica DESPUÉS de un envío exitoso.
    @Default(false) bool guardarFrecuente,

    /// Cómo llamará el titular al frecuente. Vacío = usar el nombre
    /// enmascarado como apodo por defecto.
    @Default('') String apodoFrecuente,

    /// El envío salió bien pero guardar al destinatario como frecuente falló.
    @Default(false) bool frecuenteNoGuardado,

    /// Identifica la INTENCIÓN de enviar este monto a este destinatario. Se
    /// fija al abrir la confirmación y solo se borra si cambia la intención;
    /// jamás entre reintentos. Vacía = aún no hay intención.
    @Default('') String idempotencyKey,

    /// El último fallo (de la búsqueda o del envío, según la pantalla).
    TransferFailure? failure,

    /// Un envío falló sin que se sepa si el dinero se movió (red, 429,
    /// inesperado). Sella la intención: mientras esté encendida no se puede
    /// cambiar destinatario ni monto, solo reintentar con la MISMA clave o
    /// abandonar el flujo.
    @Default(false) bool outcomeUnknown,

    /// Al abrir la confirmación había un envío pendiente de este usuario que
    /// NO coincide exacto con esta intención (otro monto, otro motivo). No se
    /// sella —no se sabe si es el mismo—, pero se avisa.
    @Default(false) bool pendingElsewhere,

    /// La clave de este envío NO se pudo guardar: si el resultado queda
    /// desconocido, reentrar al flujo no la recuperará.
    @Default(false) bool keyUnsaved,
    TransferReceipt? constancia,
  }) = _TransferState;
}
