import 'package:core_kernel/core_kernel.dart';

/// Lo que el pagador ve ANTES de confirmar: a quién paga y, si el QR lo fija,
/// cuánto y por qué.
class QrPaymentPreview {
  const QrPaymentPreview({
    required this.payload,
    required this.nombreEnmascarado,
    required this.cuentaDestinoId,
    required this.moneda,
    required this.cobro,
    this.disponibleHoy,
  });

  final String payload;
  final String nombreEnmascarado;
  final String cuentaDestinoId;

  /// Moneda en que se paga: la de la cuenta que cobra.
  final Currency moneda;

  /// Monto fijo (cobro dinámico) o libre ("Mi QR").
  final QrCobro cobro;

  /// Lo que el pagador aún puede pagar hoy con QR (límite diario). `null` si
  /// el servidor no lo informó: decide `/pagar`, esto solo avisa antes.
  final Money? disponibleHoy;
}

/// Qué fija el QR. Sellado: la UI no puede olvidar uno de los dos casos.
sealed class QrCobro {
  const QrCobro();
}

/// Cobro dinámico: monto, concepto y caducidad los puso quien cobra.
final class QrCobroFijo extends QrCobro {
  const QrCobroFijo({
    required this.monto,
    required this.concepto,
    required this.expira,
  });

  final Money monto;
  final String concepto;

  /// Instante en UTC en que el cobro deja de aceptarse.
  final DateTime expira;
}

/// "Mi QR": el pagador escribe el monto y, si quiere, un mensaje.
final class QrCobroLibre extends QrCobro {
  const QrCobroLibre();
}
