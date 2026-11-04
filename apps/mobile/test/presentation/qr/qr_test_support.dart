import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/qr/domain/qr_charge.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/feature/qr/domain/qr_payment_preview.dart';
import 'package:cuycash/feature/qr/domain/qr_receipt.dart';
import 'package:cuycash/feature/qr/domain/qr_repository.dart';
import 'package:fpdart/fpdart.dart';

final chargeDePrueba = QrCharge(
  id: 'qr-1',
  payload: 'cuycash://qr?demo=1',
  monto: const Money.soles(1000),
  concepto: 'Almuerzo',
  expira: DateTime.utc(2026, 11, 4, 13),
  cuentaId: 'acc-demo-1',
);

final previewDePrueba = QrPaymentPreview(
  payload: 'cuycash://qr?demo=1',
  nombreEnmascarado: 'J*** M*** R***',
  monto: const Money.soles(1000),
  concepto: 'Almuerzo',
  cuentaDestinoId: 'acc-demo-1',
  expira: DateTime.utc(2026, 11, 4, 13),
);

final receiptDePrueba = QrReceipt(
  transactionId: 'tx-qr-1',
  monto: const Money.soles(1000),
  fecha: DateTime.utc(2026, 11, 4, 12, 30),
);

/// Repositorio de QR con respuestas controladas por el test.
class FakeQrRepository implements QrRepository {
  FakeQrRepository({this.alEmitir, this.alLeer, this.alPagar});

  final FutureResult<QrFailure, QrCharge> Function()? alEmitir;
  final FutureResult<QrFailure, QrPaymentPreview> Function(String)? alLeer;
  final FutureResult<QrFailure, QrReceipt> Function(String)? alPagar;

  @override
  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  }) =>
      alEmitir?.call() ?? Future.value(right(chargeDePrueba));

  @override
  FutureResult<QrFailure, QrPaymentPreview> leer(String payload) =>
      alLeer?.call(payload) ?? Future.value(right(previewDePrueba));

  @override
  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
  }) =>
      alPagar?.call(payload) ?? Future.value(right(receiptDePrueba));
}
