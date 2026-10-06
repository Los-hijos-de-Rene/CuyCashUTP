import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transfer_repository_contract.dart';

void main() {
  probarContratoDeTransferencias(
    'MemoryTransferRepository',
    () => MemoryTransferRepository(clock: () => DateTime.utc(2026, 10, 5, 18)),
    pinValido: MemoryTransferRepository.pinValido,
    cuentaOrigenId: MemoryTransferRepository.cuentaId,
    dniPropio: MemoryTransferRepository.dniPropio,
    dniDestino: MemoryTransferRepository.dniDestino,
    consultasMaximas: 20,
    maxIntentos: LockoutPolicy.maxAttempts,
  );

  group('MemoryTransferRepository · bloqueo con reloj', () {
    test('el bloqueo termina cuando pasa el tiempo', () async {
      var ahora = DateTime.utc(2026, 10, 5, 18);
      final repo = MemoryTransferRepository(clock: () => ahora);
      Future<Result<TransferFailure, Object?>> mal(int i) => repo.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.soles(100),
        pin: '111111',
        idempotencyKey: 'mala-000$i',
      );
      for (var i = 1; i <= LockoutPolicy.maxAttempts; i++) {
        await mal(i);
      }

      ahora = ahora.add(const Duration(minutes: 16));
      final r = await repo.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.soles(100),
        pin: MemoryTransferRepository.pinValido,
        idempotencyKey: 'buena-001',
      );

      expect(r.isRight(), isTrue);
    });

    test('hasta es ahora + la duración del bloqueo, en UTC', () async {
      final repo = MemoryTransferRepository(
        clock: () => DateTime.utc(2026, 10, 5, 18),
        maxIntentos: 1,
        bloqueo: const Duration(minutes: 15),
      );

      final r = await repo.recargar(
        cuentaId: MemoryTransferRepository.cuentaId,
        monto: const Money.soles(100),
        pin: '111111',
        idempotencyKey: 'mala-0001',
      );

      final f =
          (r.getLeft().toNullable()! as ServerFailure<TransferFailure>).failure
              as IdentifierLocked;
      expect(f.hasta, DateTime.utc(2026, 10, 5, 18, 15));
    });
  });

  group('MemoryTransferRepository · ventana de consultas', () {
    test('el presupuesto se renueva al caducar la ventana', () async {
      var ahora = DateTime.utc(2026, 10, 5, 18);
      final repo = MemoryTransferRepository(
        clock: () => ahora,
        consultasMaximas: 2,
      );
      await repo.resolverDestinatario(MemoryTransferRepository.dniDestino);
      await repo.resolverDestinatario(MemoryTransferRepository.dniDestino);
      final agotado = await repo.resolverDestinatario(
        MemoryTransferRepository.dniDestino,
      );
      expect(agotado.isLeft(), isTrue);

      ahora = ahora.add(const Duration(minutes: 10, seconds: 1));
      final r = await repo.resolverDestinatario(
        MemoryTransferRepository.dniDestino,
      );

      expect(r.isRight(), isTrue);
    });

    test(
      'la espera informada es lo que falta para la marca más antigua',
      () async {
        var ahora = DateTime.utc(2026, 10, 5, 18);
        final repo = MemoryTransferRepository(
          clock: () => ahora,
          consultasMaximas: 1,
        );
        await repo.resolverDestinatario(MemoryTransferRepository.dniDestino);
        ahora = ahora.add(const Duration(minutes: 4));

        final r = await repo.resolverDestinatario(
          MemoryTransferRepository.dniDestino,
        );

        final f =
            (r.getLeft().toNullable()! as ServerFailure<TransferFailure>)
                    .failure
                as RateLimited;
        expect(f.reintentarEn, const Duration(minutes: 6));
      },
    );
  });
}
