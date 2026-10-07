import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_repository_contract.dart';

void main() {
  probarContratoDeCuentas(
    'MemoryAccountRepository',
    ({int? pageSize}) => MemoryAccountRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
      pageSize: pageSize ?? 20,
    ),
  );

  group('MemoryAccountRepository · paginación', () {
    final repo = MemoryAccountRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
      pageSize: 2,
    );

    test(
      'con más movimientos que la página devuelve cursor y luego cierra',
      () async {
        final p1 = (await repo.movimientos(
          'acc-demo-1',
        )).getRight().toNullable()!;
        expect(p1.items.map((m) => m.transactionId), [
          'tx-demo-1',
          'tx-demo-2',
        ]);
        expect(p1.nextCursor, isNotNull);

        final p2 = (await repo.movimientos(
          'acc-demo-1',
          cursor: p1.nextCursor,
        )).getRight().toNullable()!;
        expect(p2.items.map((m) => m.transactionId), ['tx-demo-3']);
        expect(p2.nextCursor, isNull);
      },
    );

    test(
      'un cursor ilegible empieza por el principio, como el backend',
      () async {
        final p = (await repo.movimientos(
          'acc-demo-1',
          cursor: 'basura',
        )).getRight().toNullable()!;
        expect(p.items.first.transactionId, 'tx-demo-1');
      },
    );
  });

  group('abrir aplica las reglas del backend', () {
    late MemoryAccountRepository repo;
    setUp(
      () => repo = MemoryAccountRepository(
        clock: () => DateTime.utc(2026, 10, 6),
      ),
    );

    Future<AccountFailure> falla(
      Future<Result<AccountFailure, Account>> r,
    ) async {
      final f = (await r).getLeft().toNullable();
      expect(f, isA<ServerFailure<AccountFailure>>());
      return (f as ServerFailure<AccountFailure>).failure;
    }

    Future<Result<AccountFailure, Account>> abrir({
      AccountType tipo = AccountType.ahorro,
      Currency moneda = Currency.pen,
      String? nombre,
      String pin = '000000',
      required String clave,
    }) => repo.abrir(
      tipo: tipo,
      moneda: moneda,
      nombre: nombre,
      pin: pin,
      idempotencyKey: clave,
    );

    test('sueldo en dólares', () async {
      expect(
        await falla(
          abrir(tipo: AccountType.sueldo, moneda: Currency.usd, clave: 'k-01'),
        ),
        isA<InvalidAccountCurrency>(),
      );
    });

    test('la demo ya tiene sueldo', () async {
      expect(
        await falla(abrir(tipo: AccountType.sueldo, clave: 'k-02')),
        isA<SalaryAccountExists>(),
      );
    });

    test('tope de cinco (la demo trae tres)', () async {
      expect((await abrir(clave: 'k-03')).isRight(), isTrue);
      expect((await abrir(clave: 'k-04')).isRight(), isTrue);
      expect(await falla(abrir(clave: 'k-05')), isA<AccountLimitReached>());
    });

    test('nombre de más de 30', () async {
      expect(
        await falla(abrir(nombre: 'x' * 31, clave: 'k-06')),
        isA<InvalidAccountName>(),
      );
    });

    test('PIN errado descuenta intentos', () async {
      final f = await falla(abrir(pin: '111111', clave: 'k-07'));
      expect(f, isA<AccountWrongPin>());
      expect(
        (f as AccountWrongPin).intentosRestantes,
        LockoutPolicy.maxAttempts - 1,
      );
    });

    test('misma clave con otro tipo', () async {
      await abrir(clave: 'k-08');
      expect(
        await falla(abrir(tipo: AccountType.corriente, clave: 'k-08')),
        isA<AccountKeyReused>(),
      );
    });
  });

  test('los identificadores de la demo son estables', () {
    expect(MemoryAccountRepository.tx1, 'tx-demo-1');
    expect(MemoryAccountRepository.tx2, 'tx-demo-2');
    expect(MemoryAccountRepository.tx3, 'tx-demo-3');
  });
}
