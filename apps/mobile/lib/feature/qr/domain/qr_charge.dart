import 'package:core_kernel/core_kernel.dart';

/// Un cobro publicado como QR: monto, concepto y caducidad.
class QrCharge {
  const QrCharge({
    required this.id,
    required this.payload,
    required this.monto,
    required this.concepto,
    required this.expira,
    required this.cuentaId,
  });

  final String id;

  /// Contenido que se dibuja en el QR (URI firmada).
  final String payload;

  final Money monto;
  final String concepto;

  /// Instante en UTC en que el QR deja de aceptarse.
  final DateTime expira;

  /// Cuenta que recibe el dinero.
  final String cuentaId;
}
