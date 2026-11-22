import 'package:core_kernel/core_kernel.dart';

import '../../account/domain/account.dart';
import 'qr_charge.dart';
import 'qr_failure.dart';
import 'qr_payment_preview.dart';
import 'qr_receipt.dart';
import 'qr_static.dart';

/// Contrato del cobro y pago con QR. La implementación `Memory*` es la que
/// usan el flavor `mock` y las pruebas; la real es `HttpQrRepository`.
abstract interface class QrRepository {
  /// Publica un cobro dinámico: monto fijo, un solo pago y caducidad.
  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  });

  /// "Mi QR" de la cuenta: el vigente o, si no tiene, uno nuevo.
  FutureResult<QrFailure, QrStatic> miQr(Account cuenta);

  /// Revoca el "Mi QR" vigente de la cuenta y emite otro. El anterior deja de
  /// aceptar pagos (`QrRevoked`).
  FutureResult<QrFailure, QrStatic> regenerarMiQr(Account cuenta);

  /// Lee y valida un QR. No mueve dinero.
  FutureResult<QrFailure, QrPaymentPreview> leer(String payload);

  /// Paga el QR. [monto] es obligatorio en un QR libre y se ignora en uno
  /// fijo; [mensaje] solo aplica al libre. Repetir la `idempotencyKey`
  /// devuelve el pago original.
  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
    Money? monto,
    String? mensaje,
  });
}
