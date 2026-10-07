part of 'transfer_bloc.dart';

@freezed
sealed class TransferEvent with _$TransferEvent {
  /// Arranca el flujo con la cuenta de origen (la que el inicio ya muestra).
  const factory TransferEvent.started(Account cuenta) = TransferStarted;

  /// Buscar al destinatario: un DNI que llegó a 8 dígitos o un alias que el
  /// usuario mandó a buscar (ver `RecipientQuery`).
  const factory TransferEvent.recipientRequested(String consulta) =
      TransferRecipientRequested;

  /// El DNI o alias se editó: lo resuelto o el error ya no corresponden.
  const factory TransferEvent.recipientCleared() = TransferRecipientCleared;

  /// El usuario tocó una cuenta (de la búsqueda o un frecuente que ya la trae).
  const factory TransferEvent.recipientSelected(Recipient destinatario) =
      TransferRecipientSelected;

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

  /// El usuario escribió (o borró) el apodo del frecuente.
  const factory TransferEvent.frequentNicknameChanged(String value) =
      TransferFrequentNicknameChanged;

  /// El usuario encendió o apagó "guardar como frecuente".
  const factory TransferEvent.saveFrequentToggled(bool value) =
      TransferSaveFrequentToggled;
}
