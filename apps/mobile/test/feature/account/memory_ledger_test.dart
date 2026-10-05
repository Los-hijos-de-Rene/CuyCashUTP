import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
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
      expect(await saldo(), const Money.fromCentimos(125040));

      await transferencias.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.fromCentimos(10000),
        pin: MemoryTransferRepository.pinValido,
        idempotencyKey: 'recarga-0001',
      );

      expect(await saldo(), const Money.fromCentimos(135040));
      final pagina = (await cuentas.movimientos(
        MemoryLedger.cuentaId,
      )).getRight().toNullable()!;
      final primero = pagina.items.first;
      expect(primero.tipo, MovementKind.recarga);
      expect(primero.direccion, MovementDirection.credito);
      expect(primero.saldoPosterior, const Money.fromCentimos(135040));
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
        destinatarioDni: MemoryTransferRepository.dniDestino,
        monto: const Money.fromCentimos(5000),
        motivo: 'Cena',
        pin: MemoryTransferRepository.pinValido,
        idempotencyKey: 'envio-0001',
      );

      expect(await saldo(), const Money.fromCentimos(120040));
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
        monto: const Money.fromCentimos(10000),
        pin: MemoryTransferRepository.pinValido,
        idempotencyKey: 'recarga-0001',
      );
    }
    expect(await saldo(), const Money.fromCentimos(135040));
  });

  test('un fallo (PIN errado, fondos) no toca el saldo', () async {
    await transferencias.recargar(
      cuentaId: MemoryTransferRepository.cuentaId,
      monto: const Money.fromCentimos(10000),
      pin: '111111',
      idempotencyKey: 'recarga-0002',
    );
    await transferencias.enviar(
      cuentaOrigenId: MemoryTransferRepository.cuentaId,
      destinatarioDni: MemoryTransferRepository.dniDestino,
      monto: const Money.fromCentimos(200000),
      pin: MemoryTransferRepository.pinValido,
      idempotencyKey: 'envio-0002',
    );
    expect(await saldo(), const Money.fromCentimos(125040));
  });

  test(
    'el grafo mock comparte UN libro mayor entre ambos repositorios',
    () async {
      final deps = await buildMockDependencies();
      await deps.transferRepository.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.fromCentimos(10000),
        pin: MemoryTransferRepository.pinValido,
        idempotencyKey: 'recarga-0003',
      );
      final cuentasMock = (await deps.accountRepository.cuentas())
          .getRight()
          .toNullable()!;
      expect(
        cuentasMock.first.saldoDisponible,
        const Money.fromCentimos(135040),
      );
    },
  );
}
