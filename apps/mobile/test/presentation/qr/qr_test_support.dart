import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/qr/domain/qr_charge.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/feature/qr/domain/qr_payment_preview.dart';
import 'package:cuycash/feature/qr/domain/qr_receipt.dart';
import 'package:cuycash/feature/qr/domain/qr_repository.dart';
import 'package:cuycash/feature/qr/domain/qr_static.dart';
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
  cuentaDestinoId: 'acc-demo-1',
  moneda: Currency.pen,
  cobro: QrCobroFijo(
    monto: const Money.soles(1000),
    concepto: 'Almuerzo',
    expira: DateTime.utc(2026, 11, 4, 13),
  ),
  disponibleHoy: const Money.soles(500000),
);

/// Un "Mi QR": el pagador pone el monto. Le quedan S/ 30.00 hoy.
const previewLibreDePrueba = QrPaymentPreview(
  payload: 'cuycash://qr?tipo=libre&demo=1',
  nombreEnmascarado: 'L*** Q***',
  cuentaDestinoId: 'acc-demo-1',
  moneda: Currency.pen,
  cobro: QrCobroLibre(),
  disponibleHoy: Money.soles(3000),
);

const staticDePrueba = QrStatic(
  payload: 'AAAAAAAAAAAAAAAAAAAAAA.BBBBBBBBBBBBBBBBBBBBBB',
  cuentaId: 'acc-demo-1',
  moneda: Currency.pen,
);

const staticNuevoDePrueba = QrStatic(
  payload: 'CCCCCCCCCCCCCCCCCCCCCC.DDDDDDDDDDDDDDDDDDDDDD',
  cuentaId: 'acc-demo-1',
  moneda: Currency.pen,
);

final receiptDePrueba = QrReceipt(
  transactionId: 'tx-qr-1',
  monto: const Money.soles(1000),
  fecha: DateTime.utc(2026, 11, 4, 12, 30),
);

/// Repositorio de QR con respuestas controladas por el test.
class FakeQrRepository implements QrRepository {
  FakeQrRepository({
    this.alEmitir,
    this.alLeer,
    this.alPagar,
    this.alMiQr,
    this.alRegenerar,
  });

  final FutureResult<QrFailure, QrCharge> Function()? alEmitir;
  final FutureResult<QrFailure, QrPaymentPreview> Function(String)? alLeer;
  final FutureResult<QrFailure, QrReceipt> Function(String)? alPagar;
  final FutureResult<QrFailure, QrStatic> Function()? alMiQr;
  final FutureResult<QrFailure, QrStatic> Function()? alRegenerar;

  /// Lo que llegó en el último `pagar`, para verificar qué se mandó.
  Money? montoPagado;
  String? mensajePagado;
  int regeneraciones = 0;

  @override
  FutureResult<QrFailure, QrStatic> miQr(Account cuenta) =>
      alMiQr?.call() ?? Future.value(right(staticDePrueba));

  @override
  FutureResult<QrFailure, QrStatic> regenerarMiQr(Account cuenta) {
    regeneraciones++;
    return alRegenerar?.call() ?? Future.value(right(staticNuevoDePrueba));
  }

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
    Money? monto,
    String? mensaje,
  }) {
    montoPagado = monto;
    mensajePagado = mensaje;
    return alPagar?.call(payload) ?? Future.value(right(receiptDePrueba));
  }
}
