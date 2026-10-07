import 'package:core_kernel/core_kernel.dart';

import 'account.dart';
import 'account_failure.dart';
import 'account_type.dart';
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

  /// Historial de TODAS las cuentas del titular, más reciente primero. Cada
  /// movimiento trae su `cuenta`; una transferencia entre cuentas propias sale
  /// una vez, con `cuentaDestino`. [limit] es el tamaño de página (el inicio
  /// pide pocos); ausente, el del servidor.
  FutureResult<AccountFailure, MovementPage> todosLosMovimientos({
    String? cursor,
    int? limit,
  });

  /// Ficha de un movimiento por su `transactionId`.
  FutureResult<AccountFailure, MovementDetail> movimiento(String transactionId);

  /// Abre otra cuenta del titular. Pide PIN y una `idempotencyKey` de 8 a 64
  /// caracteres generada UNA vez por intención.
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  });

  /// Pone o quita (`null`) el nombre. Sin PIN.
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  );
}
