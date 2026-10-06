part of 'movement_detail_bloc.dart';

@freezed
sealed class MovementDetailEvent with _$MovementDetailEvent {
  /// Se abrió la ficha (o se pidió reintentar): traer el movimiento.
  const factory MovementDetailEvent.opened(String transactionId) =
      MovementDetailOpened;
}
