import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/application/account_actions.dart';
import '../../../feature/account/domain/account.dart';
import '../../../feature/account/domain/account_failure.dart';
import '../../../feature/account/domain/movement.dart';

part 'account_bloc.freezed.dart';
part 'account_event.dart';
part 'account_state.dart';

/// Saldo y movimientos del inicio. Consume `AccountActions` por constructor.
///
/// Hoy el usuario tiene una sola cuenta: se muestra la primera que devuelve el
/// servidor.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(this._actions) : super(const AccountState()) {
    on<AccountStarted>(_onStarted);
    on<AccountRefreshed>(_onRefreshed);
    on<AccountMoreRequested>(_onMoreRequested);
  }

  final AccountActions _actions;

  /// Cuenta cuántas veces se reemplazó la primera página (arranque o refresco
  /// con éxito). Una página pedida antes de un reemplazo no debe anexarse a la
  /// lista nueva: traería movimientos duplicados o fuera de orden.
  int _generation = 0;

  Future<void> _onStarted(
    AccountStarted event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountState());
    final loaded = await _loadFirstPage();
    _generation++;
    emit(
      loaded.match(
        (failure) =>
            AccountState(status: AccountStatus.error, failure: failure),
        (data) => AccountState(
          status: AccountStatus.ready,
          cuenta: data.cuenta,
          movimientos: data.page.items,
          nextCursor: data.page.nextCursor,
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    AccountRefreshed event,
    Emitter<AccountState> emit,
  ) async {
    if (state.refreshing || state.status == AccountStatus.loading) return;
    emit(state.copyWith(refreshing: true, refreshFailed: false));
    final loaded = await _loadFirstPage();
    if (loaded.isRight()) _generation++;
    emit(
      loaded.match(
        // Con datos ya en pantalla un fallo de refresco no los borra, pero
        // `refreshFailed` obliga a avisar que son datos anteriores; sin ellos
        // (venía de un error) se muestra el error de nuevo.
        (failure) => state.cuenta == null
            ? AccountState(status: AccountStatus.error, failure: failure)
            : state.copyWith(refreshing: false, refreshFailed: true),
        (data) => AccountState(
          status: AccountStatus.ready,
          cuenta: data.cuenta,
          movimientos: data.page.items,
          nextCursor: data.page.nextCursor,
        ),
      ),
    );
  }

  Future<void> _onMoreRequested(
    AccountMoreRequested event,
    Emitter<AccountState> emit,
  ) async {
    final cuenta = state.cuenta;
    final cursor = state.nextCursor;
    if (cuenta == null ||
        cursor == null ||
        state.loadingMore ||
        state.status != AccountStatus.ready) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    final result = await _actions.movimientos(cuenta.id, cursor: cursor);
    // Un refresco terminó mientras tanto: esta página es de la lista vieja.
    if (generation != _generation) return;
    emit(
      result.match(
        // Se conserva el cursor: el siguiente scroll reintenta la misma página.
        (failure) => state.copyWith(loadingMore: false),
        (page) => state.copyWith(
          loadingMore: false,
          movimientos: [...state.movimientos, ...page.items],
          nextCursor: page.nextCursor,
        ),
      ),
    );
  }

  Future<Either<AccountFailure, ({Account cuenta, MovementPage page})>>
  _loadFirstPage() async {
    final cuentas = await _actions.cuentas();
    final first = cuentas.match<Either<AccountFailure, Account>>(
      (failure) => left(_toAccountFailure(failure)),
      (list) => list.isEmpty
          ? left(const AccountFailure.accountNotFound())
          : right(list.first),
    );
    return switch (first) {
      Left(:final value) => left(value),
      Right(value: final cuenta) =>
        (await _actions.movimientos(cuenta.id)).match(
          (failure) => left(_toAccountFailure(failure)),
          (page) => right((cuenta: cuenta, page: page)),
        ),
    };
  }

  /// Aplana el `GlobalFailure` a lo que la pantalla sabe decir: sin conexión o
  /// agotado el tiempo es red; lo que el servidor dijo se conserva.
  AccountFailure _toAccountFailure(GlobalFailure<AccountFailure> failure) =>
      switch (failure) {
        ServerFailure(:final failure) => failure,
        NoConnection() || Timeout() => const AccountFailure.network(),
        _ => const AccountFailure.unexpected(),
      };
}
