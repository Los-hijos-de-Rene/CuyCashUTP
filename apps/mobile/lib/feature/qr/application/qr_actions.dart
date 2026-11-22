import 'package:core_kernel/core_kernel.dart';

import '../../account/domain/account.dart';
import '../domain/qr_charge.dart';
import '../domain/qr_failure.dart';
import '../domain/qr_payment_preview.dart';
import '../domain/qr_receipt.dart';
import '../domain/qr_repository.dart';
import '../domain/qr_static.dart';

/// Operaciones de QR que consumen los blocs. Nunca tocan el repositorio directo.
class QrActions {
  const QrActions(this._repo);

  final QrRepository _repo;

  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  }) =>
      _repo.emitir(
        cuentaId: cuentaId,
        monto: monto,
        concepto: concepto,
        idempotencyKey: idempotencyKey,
      );

  FutureResult<QrFailure, QrStatic> miQr(Account cuenta) => _repo.miQr(cuenta);

  FutureResult<QrFailure, QrStatic> regenerarMiQr(Account cuenta) =>
      _repo.regenerarMiQr(cuenta);

  FutureResult<QrFailure, QrPaymentPreview> leer(String payload) =>
      _repo.leer(payload);

  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
    Money? monto,
    String? mensaje,
  }) =>
      _repo.pagar(
        payload: payload,
        cuentaOrigenId: cuentaOrigenId,
        pin: pin,
        idempotencyKey: idempotencyKey,
        monto: monto,
        mensaje: mensaje,
      );
}
