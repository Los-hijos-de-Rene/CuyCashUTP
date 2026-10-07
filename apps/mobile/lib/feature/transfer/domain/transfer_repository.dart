import 'package:core_kernel/core_kernel.dart';

import 'recipient_directory.dart';
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
  /// Busca a la persona por DNI o por alias ([consulta] tal como se
  /// tecleó, ver `RecipientQuery`) y lista sus cuentas que pueden recibir (el
  /// propio DNI o alias lista las mías). Consume el presupuesto de consultas.
  /// Un texto que no es ni DNI ni alias válido es `RecipientNotFound`.
  FutureResult<TransferFailure, RecipientDirectory> resolverDestinatario(
    String consulta,
  );

  /// Envía [monto] desde [cuentaOrigenId] a [cuentaDestinoId]. Ambas deben
  /// ser de la misma moneda.
  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String cuentaDestinoId,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  });

  /// Acredita [monto] en [cuentaId] (cash-in simulado). No pide PIN: meter
  /// dinero a la cuenta propia no necesita la autorización del titular.
  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String idempotencyKey,
  });
}
