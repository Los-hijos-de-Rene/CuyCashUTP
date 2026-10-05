import 'package:core_kernel/core_kernel.dart';

/// Constancia de un movimiento de dinero (envío o recarga) ya confirmado.
class TransferReceipt {
  const TransferReceipt({
    required this.transactionId,
    required this.monto,
    required this.fecha,
    this.destinatarioNombre,
    this.reutilizada = false,
  });

  final String transactionId;
  final Money monto;

  /// Instante en UTC (`isUtc == true`); convertir con `toLocal()` al mostrarlo.
  final DateTime fecha;

  /// Nombre del destinatario cuando quien implementa lo conoce. El backend no
  /// lo devuelve en la constancia: la UI usa el [Recipient] que ya resolvió.
  /// Nulo en recargas.
  final String? destinatarioNombre;

  /// `true` si el servidor reconoció la `idempotencyKey` y devolvió la
  /// operación ORIGINAL (HTTP 200 en vez de 201): el dinero no se movió otra
  /// vez.
  final bool reutilizada;
}
