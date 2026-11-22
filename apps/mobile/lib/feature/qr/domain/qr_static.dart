import 'package:core_kernel/core_kernel.dart';

/// "Mi QR": el QR permanente de una cuenta. Identifica a quien cobra; el
/// pagador elige el monto. Vale hasta que el titular lo regenere.
class QrStatic {
  const QrStatic({
    required this.payload,
    required this.cuentaId,
    required this.moneda,
  });

  /// Contenido que se dibuja en el QR (referencia firmada, opaca).
  final String payload;
  final String cuentaId;
  final Currency moneda;
}
