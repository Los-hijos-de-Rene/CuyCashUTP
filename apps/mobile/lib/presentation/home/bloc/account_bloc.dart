import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/application/account_actions.dart';
import '../../../feature/account/domain/account.dart';
import '../../../feature/account/domain/account_failure.dart';
import '../../../feature/account/domain/account_limits.dart';
import '../../../feature/account/domain/movement.dart';

part 'account_bloc.freezed.dart';
part 'account_event.dart';
part 'account_state.dart';

/// Las cuentas del titular, la que se ve en el carrusel y sus movimientos.
/// Consume `AccountActions` por constructor.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(this._actions) : super(const AccountState()) {
    on<AccountStarted>(_onStarted);
    on<AccountRefreshed>(_onRefreshed);
    on<AccountMoreRequested>(_onMoreRequested);
    on<AccountSelected>(_onSelected);
    on<AccountOpened>(_onOpened);
    on<AccountRenameRequested>(_onRenameRequested);
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
          cuentas: data.cuentas,
          seleccionada: data.indice,
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
    final antes = state.cuenta?.id;
    final loaded = await _loadFirstPage(preferirId: antes);
    emit(
      loaded.match(
        // Con datos ya en pantalla un fallo de refresco no los borra, pero
        // `refreshFailed` obliga a avisar que son datos anteriores; sin ellos
        // (venía de un error) se muestra el error de nuevo.
        (failure) => state.cuenta == null
            ? AccountState(status: AccountStatus.error, failure: failure)
            : state.copyWith(refreshing: false, refreshFailed: true),
        (data) {
          final ahora = state.cuenta?.id;
          if (ahora != antes) {
            // Deslizó mientras tanto: los movimientos que llegaron son de la
            // cuenta anterior. Se toman los saldos nuevos y se conserva lo que
            // `selected` ya trajo para la cuenta visible.
            final i = data.cuentas.indexWhere((c) => c.id == ahora);
            return state.copyWith(
              refreshing: false,
              refreshFailed: false,
              cuentas: data.cuentas,
              seleccionada: i < 0 ? 0 : i,
            );
          }
          _generation++;
          return AccountState(
            status: AccountStatus.ready,
            cuentas: data.cuentas,
            seleccionada: data.indice,
            movimientos: data.page.items,
            nextCursor: data.page.nextCursor,
            // Un renombrado en vuelo no es de este refresco: no se pisa.
            renaming: state.renaming,
            renameFailure: state.renameFailure,
          );
        },
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
        state.cargandoMovimientos ||
        state.status != AccountStatus.ready) {
      return;
    }

    final generation = _generation;
    final cuentaId = cuenta.id;
    emit(state.copyWith(loadingMore: true));
    final result = await _actions.movimientos(cuenta.id, cursor: cursor);
    // Un refresco terminó mientras tanto: esta página es de la lista vieja.
    if (generation != _generation || state.cuenta?.id != cuentaId) return;
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

  Future<
    Either<
      AccountFailure,
      ({List<Account> cuentas, int indice, MovementPage page})
    >
  >
  _loadFirstPage({String? preferirId}) async {
    final cuentas = await _actions.cuentas();
    final elegida = cuentas
        .match<Either<AccountFailure, ({List<Account> lista, int i})>>(
          (failure) => left(_toAccountFailure(failure)),
          (lista) {
            if (lista.isEmpty) {
              return left(const AccountFailure.accountNotFound());
            }
            final i = lista.indexWhere((c) => c.id == preferirId);
            return right((lista: lista, i: i < 0 ? 0 : i));
          },
        );
    return switch (elegida) {
      Left(:final value) => left(value),
      Right(value: (:final lista, :final i)) =>
        (await _actions.movimientos(lista[i].id)).match(
          (failure) => left(_toAccountFailure(failure)),
          (page) => right((cuentas: lista, indice: i, page: page)),
        ),
    };
  }

  Future<void> _onSelected(
    AccountSelected event,
    Emitter<AccountState> emit,
  ) async {
    if (event.indice == state.seleccionada ||
        event.indice < 0 ||
        event.indice >= state.cuentas.length) {
      return;
    }
    // Otra cuenta, otra lista: cualquier página en vuelo es de la anterior.
    final generation = ++_generation;
    emit(
      state.copyWith(
        seleccionada: event.indice,
        movimientos: const [],
        nextCursor: null,
        cargandoMovimientos: true,
        loadingMore: false,
      ),
    );
    final result = await _actions.movimientos(state.cuentas[event.indice].id);
    if (generation != _generation) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(cargandoMovimientos: false, refreshFailed: true),
        (page) => state.copyWith(
          cargandoMovimientos: false,
          movimientos: page.items,
          nextCursor: page.nextCursor,
        ),
      ),
    );
  }

  Future<void> _onOpened(
    AccountOpened event,
    Emitter<AccountState> emit,
  ) async {
    final cuentas = [...state.cuentas, event.cuenta];
    emit(state.copyWith(cuentas: cuentas));
    add(AccountEvent.selected(cuentas.length - 1));
  }

  Future<void> _onRenameRequested(
    AccountRenameRequested event,
    Emitter<AccountState> emit,
  ) async {
    if (state.renaming) return;
    emit(state.copyWith(renaming: true, renameFailure: null));
    final result = await _actions.renombrar(event.cuentaId, event.nombre);
    emit(
      result.match(
        (failure) => state.copyWith(
          renaming: false,
          renameFailure: _toAccountFailure(failure),
        ),
        (cuenta) => state.copyWith(
          renaming: false,
          cuentas: [
            for (final c in state.cuentas) c.id == cuenta.id ? cuenta : c,
          ],
        ),
      ),
    );
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
