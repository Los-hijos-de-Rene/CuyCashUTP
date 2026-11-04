import 'package:core_kernel/core_kernel.dart';

/// Constancia de un pago con QR ya confirmado.
class QrReceipt {
  const QrReceipt({
    required this.transactionId,
    required this.monto,
    required this.fecha,
  });

  final String transactionId;
  final Money monto;

  /// Instante en UTC (`isUtc == true`); convertir con `toLocal()` al mostrarlo.
  final DateTime fecha;
}
