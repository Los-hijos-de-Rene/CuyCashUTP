import 'package:core_kernel/core_kernel.dart';

import 'recipient.dart';
import 'transfer_failure.dart';
import 'transfer_receipt.dart';

/// Contrato de movimientos de dinero (domain). Nunca lanza: devuelve `Result`.
/// Su `Memory*` funcional comparte la batería de contrato con la impl HTTP.
///
/// Enviar y recargar comparten motor pero no contrato: recargar no tiene
/// destinatario ni puede fallar por fondos, por eso son métodos separados.
///
/// Toda operación que mueve dinero exige una `idempotencyKey` de 8 a 64
/// caracteres generada UNA vez por intención del usuario y reutilizada en los
/// reintentos.
abstract interface class TransferRepository {
  /// Busca al destinatario por DNI. Consume el presupuesto de consultas.
  FutureResult<TransferFailure, Recipient> resolverDestinatario(String dni);

  /// Envía [monto] desde [cuentaOrigenId] al cliente con [destinatarioDni].
  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String destinatarioDni,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  });

  /// Acredita [monto] en [cuentaId] (cash-in simulado).
  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String pin,
    required String idempotencyKey,
  });
}
