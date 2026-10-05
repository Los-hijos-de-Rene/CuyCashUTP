part of 'transfer_bloc.dart';

@freezed
sealed class TransferEvent with _$TransferEvent {
  /// Arranca el flujo con la cuenta de origen (la que el inicio ya muestra).
  const factory TransferEvent.started(Account cuenta) = TransferStarted;

  /// El DNI llegó a 8 dígitos: resolver contra el backend.
  const factory TransferEvent.recipientRequested(String dni) =
      TransferRecipientRequested;

  /// El DNI se editó: lo resuelto o el error ya no corresponden.
  const factory TransferEvent.recipientCleared() = TransferRecipientCleared;

  /// El monto y el motivo quedaron fijados al pasar a la confirmación.
  const factory TransferEvent.amountEntered({
    required Money monto,
    String? motivo,
  }) = TransferAmountEntered;

  /// Se abrió la pantalla de confirmación: AQUÍ nace la clave de idempotencia.
  const factory TransferEvent.confirmationOpened() = TransferConfirmationOpened;

  /// El usuario confirmó con su PIN. Se ignora si ya hay un envío en curso.
  const factory TransferEvent.submitted({required String pin}) =
      TransferSubmitted;
}
