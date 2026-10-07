import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/application/account_actions.dart';
import '../../../feature/account/domain/account.dart';
import '../../../feature/account/domain/account_failure.dart';
import '../../../feature/account/domain/account_limits.dart';
import '../../../feature/account/domain/movement.dart';
import '../../account/account_failure_flatten.dart';

part 'account_bloc.freezed.dart';
part 'account_event.dart';
part 'account_state.dart';

/// El inicio: las cuentas del titular, la que se ve en el carrusel y los
/// últimos movimientos de TODAS ellas. Consume `AccountActions` por
/// constructor.
///
/// No pagina: el historial completo (de una cuenta o de todas) lo lleva
/// `MovementsBloc` en su propia pantalla.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(this._actions) : super(const AccountState()) {
    on<AccountStarted>(_onStarted);
    on<AccountRefreshed>(_onRefreshed);
    on<AccountSelected>(_onSelected);
    on<AccountOpened>(_onOpened);
    on<AccountRenameRequested>(_onRenameRequested);
  }

  /// Cuántos movimientos muestra el inicio. Pocos a propósito: es un resumen,
  /// y "Ver más" lleva al historial completo.
  static const recientesEnInicio = 5;

  final AccountActions _actions;

  Future<void> _onStarted(
    AccountStarted event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountState());
    final loaded = await _load();
    emit(
      loaded.match(
        (failure) =>
            AccountState(status: AccountStatus.error, failure: failure),
        (data) => AccountState(
          status: AccountStatus.ready,
          cuentas: data.cuentas,
          recientes: data.page.items,
          hayMasMovimientos: data.page.nextCursor != null,
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
    final loaded = await _load();
    emit(
      loaded.match(
        // Con datos ya en pantalla un fallo de refresco no los borra, pero
        // `refreshFailed` obliga a avisar que son datos anteriores; sin ellos
        // (venía de un error) se muestra el error de nuevo.
        (failure) => state.cuenta == null
            ? AccountState(status: AccountStatus.error, failure: failure)
            : state.copyWith(refreshing: false, refreshFailed: true),
        (data) {
          // La cuenta visible sigue siendo la misma aunque cambie su índice.
          final i = data.cuentas.indexWhere((c) => c.id == antes);
          return state.copyWith(
            status: AccountStatus.ready,
            cuentas: data.cuentas,
            seleccionada: i < 0 ? 0 : i,
            recientes: data.page.items,
            hayMasMovimientos: data.page.nextCursor != null,
            refreshing: false,
            refreshFailed: false,
            failure: null,
          );
        },
      ),
    );
  }

  /// Las cuentas y los últimos movimientos, a la vez: son independientes y el
  /// inicio no debe esperar uno para pedir el otro.
  Future<Either<AccountFailure, ({List<Account> cuentas, MovementPage page})>>
  _load() async {
    final (cuentas, page) = await (
      _actions.cuentas(),
      _actions.todosLosMovimientos(limit: recientesEnInicio),
    ).wait;
    return switch ((cuentas, page)) {
      (Left(:final value), _) ||
      (_, Left(:final value)) => left(flattenAccountFailure(value)),
      (Right(value: final lista), Right(value: final p)) =>
        lista.isEmpty
            ? left(const AccountFailure.accountNotFound())
            : right((cuentas: lista, page: p)),
    };
  }

  void _onSelected(AccountSelected event, Emitter<AccountState> emit) {
    if (event.indice == state.seleccionada ||
        event.indice < 0 ||
        event.indice >= state.cuentas.length) {
      return;
    }
    emit(state.copyWith(seleccionada: event.indice));
  }

  void _onOpened(AccountOpened event, Emitter<AccountState> emit) {
    final cuentas = [...state.cuentas, event.cuenta];
    // Recién abierta: sin movimientos, así que los recientes no cambian.
    emit(state.copyWith(cuentas: cuentas, seleccionada: cuentas.length - 1));
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
          renameFailure: flattenAccountFailure(failure),
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
}
