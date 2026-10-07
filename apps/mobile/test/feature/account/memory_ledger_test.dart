import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryAccountRepository cuentas;
  late MemoryTransferRepository transferencias;

  setUp(() {
    final ledger = MemoryLedger(clock: () => DateTime.utc(2026, 10, 5, 18));
    cuentas = MemoryAccountRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
      ledger: ledger,
    );
    transferencias = MemoryTransferRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
      ledger: ledger,
    );
  });

  Future<Money> saldo() async =>
      (await cuentas.cuentas()).getRight().toNullable()!.first.saldoDisponible;

  test(
    'recargar sube el saldo que ve el inicio y deja el movimiento',
    () async {
      expect(await saldo(), const Money.soles(125040));

      await transferencias.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.soles(10000),
        idempotencyKey: 'recarga-0001',
      );

      expect(await saldo(), const Money.soles(135040));
      final pagina = (await cuentas.movimientos(
        MemoryLedger.cuentaId,
      )).getRight().toNullable()!;
      final primero = pagina.items.first;
      expect(primero.tipo, MovementKind.recarga);
      expect(primero.direccion, MovementDirection.credito);
      expect(primero.saldoPosterior, const Money.soles(135040));
      expect(primero.transactionId, startsWith('tx-mem-'));
      // La ficha del movimiento nuevo también se encuentra.
      expect(
        (await cuentas.movimiento(primero.transactionId)).isRight(),
        isTrue,
      );
    },
  );

  test(
    'enviar baja el saldo y registra el movimiento con su contraparte',
    () async {
      await transferencias.enviar(
        cuentaOrigenId: MemoryTransferRepository.cuentaId,
        cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
        monto: const Money.soles(5000),
        motivo: 'Cena',
        pin: MemoryTransferRepository.pinValido,
        idempotencyKey: 'envio-0001',
      );

      expect(await saldo(), const Money.soles(120040));
      final primero = (await cuentas.movimientos(
        MemoryLedger.cuentaId,
      )).getRight().toNullable()!.items.first;
      expect(primero.direccion, MovementDirection.debito);
      expect(primero.contraparte, 'J*** M*** R***');
      expect(primero.motivo, 'Cena');
    },
  );

  test('un reintento con la misma clave NO mueve el saldo dos veces', () async {
    for (var i = 0; i < 2; i++) {
      await transferencias.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.soles(10000),
        idempotencyKey: 'recarga-0001',
      );
    }
    expect(await saldo(), const Money.soles(135040));
  });

  test('un fallo (PIN errado, fondos) no toca el saldo', () async {
    await transferencias.enviar(
      cuentaOrigenId: MemoryTransferRepository.cuentaId,
      cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
      monto: const Money.soles(10000),
      pin: '111111',
      idempotencyKey: 'envio-0001',
    );
    await transferencias.enviar(
      cuentaOrigenId: MemoryTransferRepository.cuentaId,
      cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
      monto: const Money.soles(200000),
      pin: MemoryTransferRepository.pinValido,
      idempotencyKey: 'envio-0002',
    );
    expect(await saldo(), const Money.soles(125040));
  });

  test('el titular de demo tiene tres cuentas y cada una su saldo', () async {
    final lista = (await cuentas.cuentas()).getRight().toNullable()!;
    expect(lista.map((c) => (c.id, c.tipo, c.moneda, c.saldoDisponible)), [
      ('acc-demo-1', AccountType.ahorro, Currency.pen, const Money.soles(125040)),
      ('acc-demo-2', AccountType.sueldo, Currency.pen, const Money.soles(350000)),
      ('acc-demo-3', AccountType.ahorro, Currency.usd, const Money.dolares(12000)),
    ]);
  });

  test('recargar una cuenta no toca el saldo de las otras', () async {
    await transferencias.recargar(
      cuentaId: MemoryLedger.cuentaDolaresId,
      monto: const Money.dolares(500),
      idempotencyKey: 'recarga-usd-0001',
    );
    final lista = (await cuentas.cuentas()).getRight().toNullable()!;
    expect(lista[0].saldoDisponible, const Money.soles(125040));
    expect(lista[2].saldoDisponible, const Money.dolares(12500));
    final movs = (await cuentas.movimientos(MemoryLedger.cuentaDolaresId)).getRight().toNullable()!;
    expect(movs.items.single.monto, const Money.dolares(500));
  });

  test('las cuentas sin movimientos devuelven una página vacía', () async {
    final p = (await cuentas.movimientos(MemoryLedger.cuentaSueldoId)).getRight().toNullable()!;
    expect(p.items, isEmpty);
    expect(p.nextCursor, isNull);
  });

  test(
    'el grafo mock comparte UN libro mayor entre ambos repositorios',
    () async {
      final deps = await buildMockDependencies();
      await deps.transferRepository.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.soles(10000),
        idempotencyKey: 'recarga-0003',
      );
      final cuentasMock = (await deps.accountRepository.cuentas())
          .getRight()
          .toNullable()!;
      expect(cuentasMock.first.saldoDisponible, const Money.soles(135040));
    },
  );
}
