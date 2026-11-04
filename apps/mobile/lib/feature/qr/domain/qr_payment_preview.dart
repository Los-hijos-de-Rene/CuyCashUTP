import 'package:core_kernel/core_kernel.dart';

/// Lo que el pagador ve ANTES de confirmar: quién cobra, cuánto y por qué.
class QrPaymentPreview {
  const QrPaymentPreview({
    required this.payload,
    required this.nombreEnmascarado,
    required this.monto,
    required this.concepto,
    required this.cuentaDestinoId,
    required this.expira,
  });

  final String payload;
  final String nombreEnmascarado;
  final Money monto;
  final String concepto;
  final String cuentaDestinoId;
  final DateTime expira;
}
