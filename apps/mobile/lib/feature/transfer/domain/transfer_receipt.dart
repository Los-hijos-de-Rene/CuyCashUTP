import 'package:core_kernel/core_kernel.dart';

/// Constancia de un movimiento de dinero (envío o recarga) ya confirmado.
class TransferReceipt {
  const TransferReceipt({
    required this.transactionId,
    required this.monto,
    required this.fecha,
    this.reutilizada = false,
  });

  final String transactionId;
  final Money monto;

  /// Instante en UTC (`isUtc == true`); convertir con `toLocal()` al mostrarlo.
  final DateTime fecha;

  // Sin nombre de destinatario: el backend no lo manda en la constancia. La
  // pantalla usa el `Recipient` que ya resolvió.

  /// `true` si el servidor reconoció la `idempotencyKey` y devolvió la
  /// operación ORIGINAL (HTTP 200 en vez de 201): el dinero no se movió otra
  /// vez.
  final bool reutilizada;
}
