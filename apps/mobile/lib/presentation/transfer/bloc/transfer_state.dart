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

    /// Reservado para "guardar como frecuente" (`feature/beneficiary`, tarea
    /// 16). Sin UI hasta entonces: un interruptor que no hace nada mentiría.
    @Default(false) bool guardarFrecuente,

    /// Identifica la INTENCIÓN de enviar este monto a este destinatario. Se
    /// fija al abrir la confirmación y solo se borra si cambia la intención;
    /// jamás entre reintentos. Vacía = aún no hay intención.
    @Default('') String idempotencyKey,

    /// El último fallo (de la búsqueda o del envío, según la pantalla).
    TransferFailure? failure,
    TransferReceipt? constancia,
  }) = _TransferState;
}
