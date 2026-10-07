import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/presentation/home/bloc/account_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scripted_account_repository.dart';

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

void main() {
  blocTest<AccountBloc, AccountState>(
    'al arrancar trae las cuentas y los últimos movimientos de todas',
    build: () =>
        AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
    act: (bloc) => bloc.add(const AccountStarted()),
    expect: () => [
      isA<AccountState>().having(
        (s) => s.status,
        'status',
        AccountStatus.loading,
      ),
      isA<AccountState>()
          .having((s) => s.status, 'status', AccountStatus.ready)
          .having((s) => s.cuentas, 'cuentas', hasLength(3))
          .having((s) => s.cuenta?.id, 'visible', MemoryLedger.cuentaId)
          .having((s) => s.recientes, 'recientes', hasLength(3))
          .having((s) => s.hayMasMovimientos, 'hay más', isFalse),
    ],
  );

  test(
    'pide como mucho los recientes del inicio, y avisa si hay más',
    () async {
      final repo = ScriptedAccountRepository(
        MemoryAccountRepository(clock: _reloj, pageSize: 2),
      );
      final bloc = AccountBloc(AccountActions(repo));
      addTearDown(bloc.close);
      bloc.add(const AccountStarted());
      await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);

      expect(repo.limites, [AccountBloc.recientesEnInicio]);
      // Con 3 movimientos y límite 5 no hay más; el `pageSize` no aplica.
      expect(bloc.state.recientes, hasLength(3));
      expect(bloc.state.hayMasMovimientos, isFalse);
    },
  );

  test('con más de 5 movimientos ofrece "Ver más"', () async {
    final ledger = MemoryLedger(clock: _reloj);
    for (var i = 0; i < 3; i++) {
      ledger.registrar(
        cuentaId: MemoryLedger.cuentaSueldoId,
        transactionId: 'tx-extra-$i',
        tipo: MovementKind.recarga,
        direccion: MovementDirection.credito,
        monto: const Money.soles(100),
        fecha: _reloj(),
      );
    }
    final bloc = AccountBloc(
      AccountActions(MemoryAccountRepository(ledger: ledger)),
    );
    addTearDown(bloc.close);
    bloc.add(const AccountStarted());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);

    expect(bloc.state.recientes, hasLength(AccountBloc.recientesEnInicio));
    expect(bloc.state.hayMasMovimientos, isTrue);
  });

  blocTest<AccountBloc, AccountState>(
    'un fallo de red deja la pantalla en error, no vacía',
    build: () => AccountBloc(
      AccountActions(
        ScriptedAccountRepository(MemoryAccountRepository())..falla = true,
      ),
    ),
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

  test('refrescar tras un error de carga inicial vuelve a cargar', () async {
    final repo = ScriptedAccountRepository(MemoryAccountRepository())
      ..falla = true;
    final bloc = AccountBloc(AccountActions(repo));
    addTearDown(bloc.close);
    bloc.add(const AccountStarted());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.error);

    repo.falla = false;
    bloc.add(const AccountRefreshed());
    await bloc.stream.firstWhere((s) => s.status == AccountStatus.ready);

    expect(bloc.state.failure, isNull);
    expect(bloc.state.recientes, hasLength(3));
  });

  test(
    'un refresco fallido conserva los datos y marca refreshFailed',
    () async {
      final repo = ScriptedAccountRepository(MemoryAccountRepository());
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
      expect(bloc.state.recientes, hasLength(3));

      // Un refresco que sí funciona limpia el aviso.
      repo.falla = false;
      bloc.add(const AccountRefreshed());
      await bloc.stream.firstWhere((s) => !s.refreshing && !s.refreshFailed);
      expect(bloc.state.refreshFailed, isFalse);
    },
  );

  group('varias cuentas', () {
    blocTest<AccountBloc, AccountState>(
      'deslizar solo cambia la cuenta visible: no pide movimientos',
      build: () =>
          AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(1));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaSueldoId);
        // Los recientes son de todas: no cambian con el carrusel.
        expect(b.state.recientes, hasLength(3));
      },
    );

    blocTest<AccountBloc, AccountState>(
      'refrescar conserva la cuenta visible',
      build: () =>
          AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(2));
        b.add(const AccountEvent.refreshed());
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaDolaresId);
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
        final repo = ScriptedAccountRepository(
          MemoryAccountRepository(clock: _reloj),
          renombrarLento: true,
        );
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

        repo.liberarRenombrar.complete();
        await b.stream.firstWhere((s) => !s.renaming);
        expect(b.state.renameFailure, isNull);
      },
    );
  });
}
