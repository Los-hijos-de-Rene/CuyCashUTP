import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_repository_contract.dart';

void main() {
  probarContratoDeCuentas(
    'MemoryAccountRepository',
    () => MemoryAccountRepository(clock: () => DateTime.utc(2026, 10, 5, 18)),
  );

  group('MemoryAccountRepository · paginación', () {
    final repo = MemoryAccountRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
      pageSize: 2,
    );

    test('con más movimientos que la página devuelve cursor y luego cierra',
        () async {
      final p1 = (await repo.movimientos('acc-demo-1')).getRight().toNullable()!;
      expect(p1.items.map((m) => m.transactionId), ['tx-demo-1', 'tx-demo-2']);
      expect(p1.nextCursor, isNotNull);

      final p2 = (await repo.movimientos('acc-demo-1', cursor: p1.nextCursor))
          .getRight()
          .toNullable()!;
      expect(p2.items.map((m) => m.transactionId), ['tx-demo-3']);
      expect(p2.nextCursor, isNull);
    });

    test('un cursor ilegible empieza por el principio, como el backend',
        () async {
      final p = (await repo.movimientos('acc-demo-1', cursor: 'basura'))
          .getRight()
          .toNullable()!;
      expect(p.items.first.transactionId, 'tx-demo-1');
    });
  });

  test('los identificadores de la demo son estables', () {
    expect(MemoryAccountRepository.tx1, 'tx-demo-1');
    expect(MemoryAccountRepository.tx2, 'tx-demo-2');
    expect(MemoryAccountRepository.tx3, 'tx-demo-3');
  });
}
