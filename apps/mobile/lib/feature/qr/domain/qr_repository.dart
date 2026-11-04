import 'package:core_kernel/core_kernel.dart';

import 'qr_charge.dart';
import 'qr_failure.dart';
import 'qr_payment_preview.dart';
import 'qr_receipt.dart';

/// Contrato del cobro y pago con QR. La implementación `Memory*` es la que
/// usan el flavor `mock` y las pruebas; la real llegará con la API #77.
abstract interface class QrRepository {
  /// Publica un cobro firmado con caducidad.
  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  });

  /// Lee y valida un QR. No mueve dinero.
  FutureResult<QrFailure, QrPaymentPreview> leer(String payload);

  /// Paga el QR. Vuelve a validar el payload antes de mover dinero y usa una
  /// `idempotencyKey` para que un reintento no cobre dos veces.
  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
  });
}
