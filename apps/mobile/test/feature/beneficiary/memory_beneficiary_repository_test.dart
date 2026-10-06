import 'package:core_kernel/core_kernel.dart';
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
    dniPropio: MemoryTransferRepository.dniPropio,
    dniConocido: MemoryTransferRepository.dniDestino,
    dniConocido2: MemoryTransferRepository.dniDestino2,
    consultasMaximas: 20,
  );

  test('la ventana deslizante libera el presupuesto con el tiempo', () async {
    var ahora = DateTime.utc(2026, 10, 5, 18);
    final repo = MemoryBeneficiaryRepository(
      clock: () => ahora,
      consultasMaximas: 2,
    );
    await repo.guardar(MemoryTransferRepository.dniDestino, 'A');
    await repo.guardar(MemoryTransferRepository.dniDestino, 'B');
    final bloqueado = await repo.guardar(
      MemoryTransferRepository.dniDestino,
      'C',
    );
    expect(bloqueado.isLeft(), isTrue);

    ahora = ahora.add(const Duration(minutes: 11));
    final libre = await repo.guardar(MemoryTransferRepository.dniDestino, 'C');
    expect(libre.isRight(), isTrue);
  });

  test('un DNI mal formado es un fallo inesperado, no un recipientNotFound',
      () async {
    final r = await MemoryBeneficiaryRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
    ).guardar('123', 'X');
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<BeneficiaryFailure>>());
    expect(
      (failure! as ServerFailure<BeneficiaryFailure>).failure,
      isA<BeneficiaryUnexpectedFailure>(),
    );
  });
}
