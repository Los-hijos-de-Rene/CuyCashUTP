import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/beneficiary.dart';
import '../domain/beneficiary_failure.dart';
import '../domain/beneficiary_limits.dart';
import '../domain/beneficiary_repository.dart';

/// Operaciones FINAS de frecuentes (delegación sobre el
/// `BeneficiaryRepository`). El bloc la consume por constructor; nunca toca el
/// repo.
class BeneficiaryActions {
  const BeneficiaryActions(this._repo);

  final BeneficiaryRepository _repo;

  FutureResult<BeneficiaryFailure, List<Beneficiary>> listar() =>
      _repo.listar();

  FutureResult<BeneficiaryFailure, Unit> guardar({
    required String cuentaDestinoId,
    required String apodo,
  }) => _repo.guardar(
    cuentaDestinoId: cuentaDestinoId,
    apodo: BeneficiaryLimits.normalizarApodo(apodo),
  );

  FutureResult<BeneficiaryFailure, Unit> eliminar(String id) =>
      _repo.eliminar(id);
}
