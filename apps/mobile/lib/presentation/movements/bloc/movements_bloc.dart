import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/application/account_actions.dart';
import '../../../feature/account/domain/account_failure.dart';
import '../../../feature/account/domain/movement.dart';
import '../../account/account_failure_flatten.dart';

part 'movements_bloc.freezed.dart';
part 'movements_event.dart';
part 'movements_state.dart';

/// El historial paginado de UNA cuenta ([cuentaId]) o de todas (`null`).
/// Consume `AccountActions` por constructor.
class MovementsBloc extends Bloc<MovementsEvent, MovementsState> {
  MovementsBloc(this._actions, {this.cuentaId})
    : super(const MovementsState()) {
    on<MovementsStarted>(_onStarted);
    on<MovementsRefreshed>(_onRefreshed);
    on<MovementsMoreRequested>(_onMoreRequested);
  }

  final AccountActions _actions;

  /// `null` = el historial combinado de todas las cuentas.
  final String? cuentaId;

  /// Cuántas veces se reemplazó la primera página. Una página pedida antes de
  /// un reemplazo no debe anexarse a la lista nueva: traería movimientos
  /// duplicados o fuera de orden.
  int _generation = 0;

  Future<Result<AccountFailure, MovementPage>> _pagina({String? cursor}) =>
      switch (cuentaId) {
        final String id => _actions.movimientos(id, cursor: cursor),
        null => _actions.todosLosMovimientos(cursor: cursor),
      };

  Future<void> _onStarted(
    MovementsStarted event,
    Emitter<MovementsState> emit,
  ) async {
    emit(const MovementsState());
    final result = await _pagina();
    _generation++;
    emit(
      result.match(
        (failure) => MovementsState(
          status: MovementsStatus.error,
          failure: flattenAccountFailure(failure),
        ),
        (page) => MovementsState(
          status: MovementsStatus.ready,
          movimientos: page.items,
          nextCursor: page.nextCursor,
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    MovementsRefreshed event,
    Emitter<MovementsState> emit,
  ) async {
    if (state.refreshing || state.status == MovementsStatus.loading) return;
    emit(state.copyWith(refreshing: true, refreshFailed: false));
    final result = await _pagina();
    emit(
      result.match(
        (failure) => state.status == MovementsStatus.error
            ? MovementsState(
                status: MovementsStatus.error,
                failure: flattenAccountFailure(failure),
              )
            : state.copyWith(refreshing: false, refreshFailed: true),
        (page) {
          _generation++;
          return MovementsState(
            status: MovementsStatus.ready,
            movimientos: page.items,
            nextCursor: page.nextCursor,
          );
        },
      ),
    );
  }

  Future<void> _onMoreRequested(
    MovementsMoreRequested event,
    Emitter<MovementsState> emit,
  ) async {
    final cursor = state.nextCursor;
    if (cursor == null ||
        state.loadingMore ||
        state.status != MovementsStatus.ready) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    final result = await _pagina(cursor: cursor);
    // Un refresco terminó mientras tanto: esta página es de la lista vieja.
    if (generation != _generation) return;
    emit(
      result.match(
        (failure) => state.copyWith(loadingMore: false, loadMoreFailed: true),
        (page) => state.copyWith(
          loadingMore: false,
          movimientos: [...state.movimientos, ...page.items],
          nextCursor: page.nextCursor,
        ),
      ),
    );
  }
}
