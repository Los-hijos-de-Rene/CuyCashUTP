import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary_failure.dart';
import 'package:cuycash/feature/beneficiary/infrastructure/memory_beneficiary_repository.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'beneficiary_repository_contract.dart';

void main() {
  probarContratoDeBeneficiarios(
    'MemoryBeneficiaryRepository',
    () => MemoryBeneficiaryRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
    ),
    dniConocido: MemoryTransferRepository.dniDestino,
    cuentaConocida: MemoryTransferRepository.cuentaDestinoId,
    cuentaConocida2: MemoryTransferRepository.cuentaDestinoCorrienteId,
    consultasMaximas: 20,
  );

  test('la ventana deslizante libera el presupuesto con el tiempo', () async {
    var ahora = DateTime.utc(2026, 10, 5, 18);
    final repo = MemoryBeneficiaryRepository(
      clock: () => ahora,
      consultasMaximas: 2,
    );
    await repo.guardar(
      cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
      apodo: 'A',
    );
    await repo.guardar(
      cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
      apodo: 'B',
    );
    final bloqueado = await repo.guardar(
      cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
      apodo: 'C',
    );
    expect(bloqueado.isLeft(), isTrue);

    ahora = ahora.add(const Duration(minutes: 11));
    final libre = await repo.guardar(
      cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
      apodo: 'C',
    );
    expect(libre.isRight(), isTrue);
  });

  test('una cuenta propia se guarda con el DNI del titular y su nombre',
      () async {
    final ledger = MemoryLedger(clock: () => DateTime.utc(2026, 10, 5, 18));
    final repo = MemoryBeneficiaryRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
      ledger: ledger,
    );
    ledger.renombrar(MemoryLedger.cuentaSueldoId, 'Sueldo');
    final r = await repo.guardar(
      cuentaDestinoId: MemoryLedger.cuentaSueldoId,
      apodo: 'Mi sueldo',
    );
    expect(r.isRight(), isTrue);

    final b = (await repo.listar()).getRight().toNullable()?.single;
    expect(b?.dni, MemoryTransferRepository.dniPropio);
    expect(b?.nombreEnmascarado, MemoryTransferRepository.nombrePropioEnmascarado);
    expect(b?.cuenta?.cuentaId, MemoryLedger.cuentaSueldoId);
    expect(b?.cuenta?.nombre, 'Sueldo');
  });

  test('un apodo vacío es un fallo inesperado, no un recipientNotFound',
      () async {
    final r = await MemoryBeneficiaryRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
    ).guardar(
      cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
      apodo: '',
    );
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<BeneficiaryFailure>>());
    expect(
      (failure! as ServerFailure<BeneficiaryFailure>).failure,
      isA<BeneficiaryUnexpectedFailure>(),
    );
  });
}
