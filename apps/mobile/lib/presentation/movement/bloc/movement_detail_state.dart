part of 'movement_detail_bloc.dart';

enum MovementDetailStatus { loading, ready, error }

@freezed
abstract class MovementDetailState with _$MovementDetailState {
  const factory MovementDetailState({
    @Default(MovementDetailStatus.loading) MovementDetailStatus status,

    /// Solo con `status == ready`.
    MovementDetail? detalle,

    /// Solo con `status == error`.
    AccountFailure? failure,
  }) = _MovementDetailState;
}
