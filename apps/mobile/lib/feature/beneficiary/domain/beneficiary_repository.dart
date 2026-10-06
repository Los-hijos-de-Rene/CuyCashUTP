import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import 'beneficiary.dart';
import 'beneficiary_failure.dart';

/// Contrato de frecuentes (domain). Nunca lanza: devuelve `Result`. Su
/// `Memory*` funcional comparte la batería de contrato con la impl HTTP.
abstract interface class BeneficiaryRepository {
  /// Del más reciente al más antiguo. No gasta presupuesto de consultas.
  FutureResult<BeneficiaryFailure, List<Beneficiary>> listar();

  /// Guarda [dni] con [apodo]. Si ya estaba guardado solo actualiza el apodo
  /// (upsert: el doble toque es inofensivo). Valida que el DNI sea cliente,
  /// así que CONSUME el presupuesto de consultas de destinatario.
  FutureResult<BeneficiaryFailure, Unit> guardar(String dni, String apodo);

  /// Idempotente: borrar uno que no existe no es un error.
  FutureResult<BeneficiaryFailure, Unit> eliminar(String id);
}
