import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/presentation/home/bloc/account_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

DateTime _reloj() => DateTime.utc(2026, 10, 6, 12);

const _cuentaNueva = Account(
  id: 'acc-nueva',
  numero: '19100000009999',
  tipo: AccountType.corriente,
  moneda: Currency.usd,
  estado: 'activa',
  saldoDisponible: Money.dolares(0),
  saldoContable: Money.dolares(0),
);

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

  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) => _inner.abrir(
    tipo: tipo,
    moneda: moneda,
    nombre: nombre,
    pin: pin,
    idempotencyKey: idempotencyKey,
  );

  @override
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) => _inner.renombrar(cuentaId, nombre);
}

/// Repo cuyos movimientos tardan distinto según la cuenta (la red no respeta
/// el orden de las peticiones).
class _RepoLentoPorCuenta extends _GuionRepo {
  _RepoLentoPorCuenta(super.inner, this.retardos);

  final Map<String, Duration> retardos;

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async {
    await Future<void>.delayed(retardos[cuentaId] ?? Duration.zero);
    return super.movimientos(cuentaId, cursor: cursor);
  }
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

  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) => _inner.abrir(
    tipo: tipo,
    moneda: moneda,
    nombre: nombre,
    pin: pin,
    idempotencyKey: idempotencyKey,
  );

  @override
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) => _inner.renombrar(cuentaId, nombre);
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

  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) async => left(const GlobalFailure.server(AccountFailure.network()));

  @override
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) async => left(const GlobalFailure.server(AccountFailure.network()));
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

  group('varias cuentas', () {
    blocTest<AccountBloc, AccountState>(
      'arranca en la primera y trae sus movimientos',
      build: () =>
          AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) => b.add(const AccountEvent.started()),
      verify: (b) {
        expect(b.state.cuentas, hasLength(3));
        expect(b.state.cuenta?.id, MemoryLedger.cuentaId);
        expect(b.state.movimientos, hasLength(3));
      },
    );

    blocTest<AccountBloc, AccountState>(
      'deslizar a otra cuenta trae los movimientos de esa',
      build: () =>
          AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(1));
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaSueldoId);
        expect(b.state.movimientos, isEmpty);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'una respuesta tardía de la cuenta anterior no se pinta en la nueva',
      build: () {
        final repo = _CountingRepo(MemoryAccountRepository(clock: _reloj));
        return AccountBloc(AccountActions(repo));
      },
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(2)); // dólares
        b.add(const AccountEvent.selected(0)); // vuelve antes de que llegue
      },
      wait: const Duration(milliseconds: 100),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaId);
        expect(b.state.movimientos.map((m) => m.transactionId), [
          MemoryLedger.tx1,
          MemoryLedger.tx2,
          MemoryLedger.tx3,
        ]);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'la respuesta lenta de una cuenta que ya no se ve no pisa a la visible',
      build: () => AccountBloc(
        AccountActions(
          _RepoLentoPorCuenta(MemoryAccountRepository(clock: _reloj), {
            MemoryLedger.cuentaId: const Duration(milliseconds: 5),
            MemoryLedger.cuentaSueldoId: const Duration(milliseconds: 60),
          }),
        ),
      ),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(1)); // lenta
        b.add(const AccountEvent.selected(0)); // rápida, llega primero
      },
      wait: const Duration(milliseconds: 150),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaId);
        expect(b.state.movimientos, hasLength(3));
        expect(b.state.loadingMore, isFalse);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'deslizar mientras refresca: la cuenta visible y sus movimientos coinciden',
      build: () => AccountBloc(
        AccountActions(_CountingRepo(MemoryAccountRepository(clock: _reloj))),
      ),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.refreshed());
        b.add(const AccountEvent.selected(1));
      },
      wait: const Duration(milliseconds: 150),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaSueldoId);
        expect(b.state.movimientos, isEmpty);
        expect(b.state.refreshing, isFalse);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'una cuenta recién abierta se agrega y queda seleccionada',
      build: () =>
          AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.opened(_cuentaNueva));
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.cuentas.last.id, _cuentaNueva.id);
        expect(b.state.cuenta?.id, _cuentaNueva.id);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'renombrar actualiza la tarjeta sin perder la selección',
      build: () =>
          AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(1));
        b.add(
          const AccountEvent.renameRequested(
            cuentaId: MemoryLedger.cuentaSueldoId,
            nombre: 'Planilla',
          ),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.cuenta?.nombre, 'Planilla');
        expect(b.state.seleccionada, 1);
        expect(b.state.renaming, isFalse);
        expect(b.state.renameFailure, isNull);
      },
    );

    test(
      'un refresco que termina durante un renombrado no apaga renaming',
      () async {
        final repo = _RenombraLento(MemoryAccountRepository(clock: _reloj));
        final b = AccountBloc(AccountActions(repo));
        addTearDown(b.close);
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);

        b.add(
          const AccountEvent.renameRequested(
            cuentaId: MemoryLedger.cuentaSueldoId,
            nombre: 'Planilla',
          ),
        );
        await b.stream.firstWhere((s) => s.renaming);
        b.add(const AccountEvent.refreshed());
        await b.stream.firstWhere((s) => s.refreshing);
        await b.stream.firstWhere((s) => !s.refreshing);
        // El refresco terminó; el renombrado sigue en vuelo.
        expect(b.state.renaming, isTrue);

        repo.liberar.complete();
        await b.stream.firstWhere((s) => !s.renaming);
        expect(b.state.renameFailure, isNull);
      },
    );
  });
}

/// Repo cuyo `renombrar` espera a [liberar].
class _RenombraLento extends _GuionRepo {
  _RenombraLento(super.inner);

  final Completer<void> liberar = Completer<void>();

  @override
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) async {
    await liberar.future;
    return super.renombrar(cuentaId, nombre);
  }
}
