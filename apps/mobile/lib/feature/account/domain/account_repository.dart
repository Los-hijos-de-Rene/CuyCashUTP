import 'package:core_kernel/core_kernel.dart';

import 'account.dart';
import 'account_failure.dart';
import 'movement.dart';

/// Contrato de consulta de cuentas (domain). Solo lectura. Nunca lanza:
/// devuelve `Result`. Su `Memory*` funcional vive en infrastructure y comparte
/// la batería de contrato con la impl HTTP.
abstract interface class AccountRepository {
  FutureResult<AccountFailure, List<Account>> cuentas();

  /// Historial de [cuentaId], más reciente primero. [cursor] es el
  /// `nextCursor` de la página anterior; ausente = desde el principio.
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  });

  /// Ficha de un movimiento por su `transactionId`.
  FutureResult<AccountFailure, MovementDetail> movimiento(String transactionId);
}
