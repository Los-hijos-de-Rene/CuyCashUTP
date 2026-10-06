import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/application/account_actions.dart';
import '../../../feature/account/domain/account_failure.dart';
import '../../../feature/account/domain/movement.dart';

part 'movement_detail_bloc.freezed.dart';
part 'movement_detail_event.dart';
part 'movement_detail_state.dart';

/// Ficha de un movimiento. Consume `AccountActions` por constructor.
///
/// Un movimiento ajeno y uno inexistente llegan igual (`AccountNotFound`): el
/// backend responde 404 a ambos a propósito, y la pantalla no debe distinguirlos.
class MovementDetailBloc
    extends Bloc<MovementDetailEvent, MovementDetailState> {
  MovementDetailBloc(this._actions) : super(const MovementDetailState()) {
    on<MovementDetailOpened>(_onOpened);
  }

  final AccountActions _actions;

  Future<void> _onOpened(
    MovementDetailOpened event,
    Emitter<MovementDetailState> emit,
  ) async {
    emit(const MovementDetailState());
    final result = await _actions.movimiento(event.transactionId);
    emit(
      result.match(
        (failure) => MovementDetailState(
          status: MovementDetailStatus.error,
          failure: _flatten(failure),
        ),
        (detalle) => MovementDetailState(
          status: MovementDetailStatus.ready,
          detalle: detalle,
        ),
      ),
    );
  }

  AccountFailure _flatten(GlobalFailure<AccountFailure> failure) =>
      switch (failure) {
        ServerFailure(:final failure) => failure,
        NoConnection() || Timeout() => const AccountFailure.network(),
        _ => const AccountFailure.unexpected(),
      };
}
