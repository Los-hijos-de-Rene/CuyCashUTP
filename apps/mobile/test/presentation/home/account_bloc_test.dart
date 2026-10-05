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

/// Repo con interruptor de fallo y latencia solo para las páginas con cursor.
class _GuionRepo implements AccountRepository {
  _GuionRepo(this._inner, {this.latenciaConCursor = Duration.zero});

  final AccountRepository _inner;
  final Duration latenciaConCursor;
  bool falla = false;

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async => falla
      ? left(const GlobalFailure.server(AccountFailure.network()))
      : _inner.cuentas();

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async {
    if (cursor != null) await Future<void>.delayed(latenciaConCursor);
    return falla
        ? left(const GlobalFailure.server(AccountFailure.network()))
        : _inner.movimientos(cuentaId, cursor: cursor);
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

  test('refrescar tras un error de carga inicial vuelve a cargar', () async {
    final repo = _GuionRepo(MemoryAccountRepository())..falla = true;
    final bloc = AccountBloc(AccountActions(repo));
    addTearDown(bloc.close);
    bloc.add(const AccountStarted());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.error);

    repo.falla = false;
    bloc.add(const AccountRefreshed());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);

    expect(bloc.state.failure, isNull);
    expect(bloc.state.movimientos, hasLength(3));
  });

  test(
    'un refresco fallido conserva los datos y marca refreshFailed',
    () async {
      final repo = _GuionRepo(MemoryAccountRepository());
      final bloc = AccountBloc(AccountActions(repo));
      addTearDown(bloc.close);
      bloc.add(const AccountStarted());
      await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);

      repo.falla = true;
      bloc.add(const AccountRefreshed());
      await bloc.stream.firstWhere((s) => !s.refreshing);

      expect(bloc.state.status, AccountStatus.ready);
      expect(bloc.state.refreshFailed, isTrue);
      expect(bloc.state.cuenta?.saldoDisponible.centimos, 125040);
      expect(bloc.state.movimientos, hasLength(3));

      // Un refresco que sí funciona limpia el aviso.
      repo.falla = false;
      bloc.add(const AccountRefreshed());
      await bloc.stream.firstWhere((s) => !s.refreshing && !s.refreshFailed);
      expect(bloc.state.refreshFailed, isFalse);
    },
  );

  test(
    'una página pedida antes de un refresco no se anexa a la lista nueva',
    () async {
      final repo = _GuionRepo(
        MemoryAccountRepository(pageSize: 1),
        latenciaConCursor: const Duration(milliseconds: 50),
      );
      final bloc = AccountBloc(AccountActions(repo));
      addTearDown(bloc.close);
      bloc.add(const AccountStarted());
      await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);

      bloc.add(const AccountMoreRequested()); // lenta
      await bloc.stream.firstWhere((s) => s.loadingMore);
      bloc.add(const AccountRefreshed()); // rápida: termina antes
      await bloc.stream.firstWhere((s) => !s.refreshing && !s.loadingMore);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.movimientos, hasLength(1));
      expect(bloc.state.loadingMore, isFalse);
    },
  );
}
