part of 'topup_bloc.dart';

@freezed
sealed class TopUpEvent with _$TopUpEvent {
  /// Se abrió la pantalla: AQUÍ nace la clave de idempotencia, no al pulsar.
  const factory TopUpEvent.opened({required String cuentaId}) = TopUpOpened;

  /// El monto cambió (`null` si el campo no es un monto legible). Se ignora
  /// con la intención sellada.
  const factory TopUpEvent.amountChanged(Money? monto) = TopUpAmountChanged;

  /// El usuario confirmó con su PIN. Se ignora si ya hay una recarga en curso.
  const factory TopUpEvent.submitted({required String pin}) = TopUpSubmitted;
}
