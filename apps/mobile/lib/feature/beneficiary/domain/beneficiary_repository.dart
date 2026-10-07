import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import 'beneficiary.dart';
import 'beneficiary_failure.dart';

/// Contrato de frecuentes (domain). Nunca lanza: devuelve `Result`. Su
/// `Memory*` funcional comparte la batería de contrato con la impl HTTP.
abstract interface class BeneficiaryRepository {
  /// Del más reciente al más antiguo. No gasta presupuesto de consultas.
  FutureResult<BeneficiaryFailure, List<Beneficiary>> listar();

  /// Guarda la cuenta [cuentaDestinoId] con [apodo]. Si ya estaba guardada
  /// solo actualiza el apodo (upsert por cuenta: el doble toque es
  /// inofensivo). Valida que la cuenta pueda recibir (también las propias),
  /// así que CONSUME el presupuesto de consultas de destinatario.
  FutureResult<BeneficiaryFailure, Unit> guardar({
    required String cuentaDestinoId,
    required String apodo,
  });

  /// Idempotente: borrar uno que no existe no es un error.
  FutureResult<BeneficiaryFailure, Unit> eliminar(String id);
}
