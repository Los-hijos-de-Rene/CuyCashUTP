import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/presentation/home/bloc/account_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Repo que cuenta las llamadas y puede fallar o quedarse esperando.
class _CountingRepo implements AccountRepository {
  _CountingRepo(this._inner);

  final AccountRepository _inner;
  int movimientosCalls = 0;

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() => _inner.cuentas();

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async {
    movimientosCalls++;
    // Como la red: la respuesta tarda más que la ráfaga de avisos de scroll.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _inner.movimientos(cuentaId, cursor: cursor);
  }

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(String id) =>
      _inner.movimiento(id);
}

class _RepoQueFalla implements AccountRepository {
  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async =>
      left(const GlobalFailure.server(AccountFailure.network()));

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async => left(const GlobalFailure.server(AccountFailure.network()));

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(String id) async =>
      left(const GlobalFailure.server(AccountFailure.network()));
}

void main() {
  blocTest<AccountBloc, AccountState>(
    'al arrancar emite loading y luego la cuenta con sus movimientos',
    build: () => AccountBloc(AccountActions(MemoryAccountRepository())),
    act: (bloc) => bloc.add(const AccountStarted()),
    expect: () => [
      isA<AccountState>().having(
        (s) => s.status,
        'status',
        AccountStatus.loading,
      ),
      isA<AccountState>()
          .having((s) => s.status, 'status', AccountStatus.ready)
          .having((s) => s.cuenta?.saldoDisponible.centimos, 'saldo', 125040)
          .having((s) => s.movimientos, 'movimientos', hasLength(3)),
    ],
  );

  blocTest<AccountBloc, AccountState>(
    'un fallo de red deja la pantalla en error, no vacía',
    build: () => AccountBloc(AccountActions(_RepoQueFalla())),
    act: (bloc) => bloc.add(const AccountStarted()),
    expect: () => [
      isA<AccountState>().having(
        (s) => s.status,
        'status',
        AccountStatus.loading,
      ),
      isA<AccountState>()
          .having((s) => s.status, 'status', AccountStatus.error)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<AccountBloc, AccountState>(
    'pedir más sin cursor no vuelve a llamar al backend',
    build: () => AccountBloc(AccountActions(MemoryAccountRepository())),
    seed: () => const AccountState(status: AccountStatus.ready),
    act: (bloc) => bloc.add(const AccountMoreRequested()),
    expect: () => <AccountState>[],
  );

  test('pedir más sin cursor no hace ninguna llamada', () async {
    final repo = _CountingRepo(MemoryAccountRepository());
    final bloc = AccountBloc(AccountActions(repo));
    addTearDown(bloc.close);
    bloc.add(const AccountStarted());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);
    expect(bloc.state.nextCursor, isNull);
    final antes = repo.movimientosCalls;

    bloc.add(const AccountMoreRequested());
    await Future<void>.delayed(Duration.zero);

    expect(repo.movimientosCalls, antes);
  });

  test('con más páginas, pedir más añade al final y agota el cursor', () async {
    final repo = _CountingRepo(MemoryAccountRepository(pageSize: 2));
    final bloc = AccountBloc(AccountActions(repo));
    addTearDown(bloc.close);
    bloc.add(const AccountStarted());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);
    expect(bloc.state.movimientos, hasLength(2));
    expect(bloc.state.nextCursor, isNotNull);

    bloc.add(const AccountMoreRequested());
    await bloc.stream.firstWhere(
      (s) => !s.loadingMore && s.movimientos.length == 3,
    );

    expect(bloc.state.nextCursor, isNull);
  });

  test('avisos de scroll en ráfaga piden UNA sola página', () async {
    final repo = _CountingRepo(MemoryAccountRepository(pageSize: 1));
    final bloc = AccountBloc(AccountActions(repo));
    addTearDown(bloc.close);
    bloc.add(const AccountStarted());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);
    final antes = repo.movimientosCalls;

    for (var i = 0; i < 5; i++) {
      bloc.add(const AccountMoreRequested());
    }
    await bloc.stream.firstWhere(
      (s) => !s.loadingMore && s.movimientos.length == 2,
    );
    await Future<void>.delayed(Duration.zero);

    expect(repo.movimientosCalls - antes, 1);
    expect(bloc.state.movimientos, hasLength(2));
  });

  test('refrescar tras un error vuelve a cargar y limpia el fallo', () async {
    final bloc = AccountBloc(AccountActions(MemoryAccountRepository()));
    addTearDown(bloc.close);
    bloc.add(const AccountStarted());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);

    bloc.add(const AccountRefreshed());
    await bloc.stream.firstWhere((s) => !s.refreshing);

    expect(bloc.state.status, AccountStatus.ready);
    expect(bloc.state.movimientos, hasLength(3));
  });
}
