import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/presentation/account_open/bloc/open_account_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../transfer/fake_transfer_repositories.dart';

void main() {
  late MemoryAccountRepository repo;
  late List<Account> iniciales;
  var n = 0;
  String clave() => 'clave-apertura-${n++}';

  setUp(() async {
    n = 0;
    _RepoContador.llamadas = 0;
    repo = MemoryAccountRepository(clock: () => DateTime.utc(2026, 10, 6));
    iniciales = (await repo.cuentas()).getRight().toNullable()!;
  });

  OpenAccountBloc build({AccountRepository? r}) => OpenAccountBloc(
    AccountActions(r ?? repo),
    pending: pendientesDePrueba(),
    userId: 'u1',
    cuentas: iniciales,
    newKey: clave,
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'abrir: la clave nace al abrir y no cambia entre reintentos',
    build: build,
    act: (b) async {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.tipoChanged(AccountType.corriente));
      b.add(const OpenAccountEvent.monedaChanged(Currency.usd));
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.status, OpenAccountStatus.done);
      expect(b.state.cuenta?.tipo, AccountType.corriente);
      expect(b.state.cuenta?.moneda, Currency.usd);
    },
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'cambiar el tipo, la moneda o el nombre genera otra clave',
    build: build,
    act: (b) {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.tipoChanged(AccountType.corriente));
      b.add(const OpenAccountEvent.nombreChanged('Viaje'));
    },
    verify: (b) => expect(b.state.idempotencyKey, 'clave-apertura-2'),
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'elegir sueldo fija la moneda en soles',
    build: build,
    act: (b) {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.monedaChanged(Currency.usd));
      b.add(const OpenAccountEvent.tipoChanged(AccountType.sueldo));
    },
    verify: (b) {
      expect(b.state.moneda, Currency.pen);
      expect(b.state.monedaFija, isTrue);
    },
  );

  test('la demo ya tiene sueldo: no está disponible', () {
    expect(build().state.sueldoDisponible, isFalse);
  });

  blocTest<OpenAccountBloc, OpenAccountState>(
    'PIN errado vuelve a editar con el fallo y la misma clave',
    build: build,
    act: (b) async {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.submitted(pin: '111111'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.status, OpenAccountStatus.editing);
      expect(b.state.failure, isA<AccountWrongPin>());
      expect(b.state.idempotencyKey, 'clave-apertura-0');
      expect(b.state.outcomeUnknown, isFalse);
    },
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'un fallo de red sella la intención: no se puede cambiar el tipo',
    build: () => build(r: _RepoSinRed(repo)),
    act: (b) async {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const OpenAccountEvent.tipoChanged(AccountType.corriente));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.outcomeUnknown, isTrue);
      expect(b.state.tipo, AccountType.ahorro);
      expect(b.state.idempotencyKey, 'clave-apertura-0');
    },
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'dos toques en abrir mandan una sola petición',
    build: () => build(r: _RepoContador(repo)),
    act: (b) {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) => expect(_RepoContador.llamadas, 1),
  );
}

class _RepoSinRed implements AccountRepository {
  _RepoSinRed(this._r);
  final AccountRepository _r;

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() => _r.cuentas();

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) => _r.movimientos(cuentaId, cursor: cursor);

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(String id) =>
      _r.movimiento(id);

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
  ) => _r.renombrar(cuentaId, nombre);
}

class _RepoContador extends _RepoSinRed {
  _RepoContador(super.r);
  static int llamadas = 0;

  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) {
    llamadas++;
    return _r.abrir(
      tipo: tipo,
      moneda: moneda,
      nombre: nombre,
      pin: pin,
      idempotencyKey: idempotencyKey,
    );
  }
}
