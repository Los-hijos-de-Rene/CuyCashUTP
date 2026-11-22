import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/feature/qr/domain/qr_charge.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/feature/qr/domain/qr_payment_preview.dart';
import 'package:cuycash/feature/qr/domain/qr_receipt.dart';
import 'package:cuycash/feature/qr/infrastructure/memory_qr_repository.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late MemoryLedger ledger;
  late MemoryQrRepository qr;

  setUp(() {
    now = DateTime.utc(2026, 11, 4, 12);
    ledger = MemoryLedger(clock: () => now);
    qr = MemoryQrRepository(
      transfer: TransferActions(
        MemoryTransferRepository(clock: () => now, ledger: ledger),
      ),
      clock: () => now,
    );
  });

  Future<QrCharge> emitir({
    Money monto = const Money.soles(5000),
    String cuentaId = MemoryLedger.cuentaId,
  }) async {
    final result = await qr.emitir(
      cuentaId: cuentaId,
      monto: monto,
      concepto: 'Almuerzo',
      idempotencyKey: 'emit-1',
    );
    return result.fold((failure) => fail('No emitió: $failure'), (c) => c);
  }

  QrFailure failureOf(Result<QrFailure, Object?> result) => result.fold(
        (failure) => switch (failure) {
          ServerFailure(failure: final f) => f,
          _ => fail('Se esperaba un fallo de negocio'),
        },
        (_) => fail('Se esperaba fallo'),
      );

  const cuentaQueCobra = Account(
    id: MemoryTransferRepository.cuentaDestinoId,
    numero: '19100000009999',
    tipo: AccountType.ahorro,
    moneda: Currency.pen,
    estado: 'activa',
    saldoDisponible: Money.soles(0),
    saldoContable: Money.soles(0),
  );

  Future<String> miQr() async =>
      (await qr.miQr(cuentaQueCobra)).getOrElse((f) => fail('$f')).payload;

  Future<Result<QrFailure, QrReceipt>> pagarLibre(
    String payload,
    String clave, {
    Money? monto = const Money.soles(1000),
  }) => qr.pagar(
    payload: payload,
    cuentaOrigenId: MemoryLedger.cuentaId,
    pin: '000000',
    idempotencyKey: clave,
    monto: monto,
    mensaje: 'Menú',
  );

  test('"Mi QR" es el mismo cada vez y se lee como monto libre', () async {
    final payload = await miQr();
    expect(await miQr(), payload);
    final preview = (await qr.leer(payload)).getOrElse((f) => fail('$f'));
    expect(preview.cobro, isA<QrCobroLibre>());
    expect(preview.disponibleHoy, const Money.soles(500000));
  });

  test('"Mi QR" admite muchos pagos con el monto del pagador', () async {
    final payload = await miQr();
    final antes = ledger.saldoDe(MemoryLedger.cuentaId);
    expect((await pagarLibre(payload, 'libre-1')).isRight(), isTrue);
    expect(
      (await pagarLibre(payload, 'libre-2', monto: const Money.soles(500)))
          .isRight(),
      isTrue,
    );
    expect(ledger.saldoDe(MemoryLedger.cuentaId), antes - const Money.soles(1500));
  });

  test('"Mi QR" sin monto no paga', () async {
    final payload = await miQr();
    expect(
      failureOf(await pagarLibre(payload, 'libre-sin', monto: null)),
      isA<QrAmountOutOfRange>(),
    );
  });

  test('regenerar revoca el QR anterior', () async {
    final viejo = await miQr();
    final nuevo = (await qr.regenerarMiQr(cuentaQueCobra))
        .getOrElse((f) => fail('$f'))
        .payload;
    expect(nuevo, isNot(viejo));
    expect(failureOf(await qr.leer(viejo)), isA<QrRevoked>());
    expect((await qr.leer(nuevo)).isRight(), isTrue);
  });

  test('el límite diario frena y dice cuánto queda; un reintento no suma',
      () async {
    // S/ 30.00 al día: el saldo de demo no alcanza para el límite real.
    qr = MemoryQrRepository(
      transfer: TransferActions(
        MemoryTransferRepository(clock: () => now, ledger: ledger),
      ),
      clock: () => now,
      limiteDiario: (moneda) => Money(3000, moneda),
    );
    final payload = await miQr();
    expect(
      (await pagarLibre(payload, 'lim-1', monto: const Money.soles(2000)))
          .isRight(),
      isTrue,
    );
    // Reintento con la misma clave: no vuelve a sumar.
    expect(
      (await pagarLibre(payload, 'lim-1', monto: const Money.soles(2000)))
          .isRight(),
      isTrue,
    );
    final fallo = failureOf(
      await pagarLibre(payload, 'lim-2', monto: const Money.soles(1500)),
    );
    expect(switch (fallo) {
      QrDailyLimit(:final disponible) => disponible,
      _ => null,
    }, const Money.soles(1000));
    // Al día siguiente (en Lima) el cupo vuelve.
    now = now.add(const Duration(days: 1));
    expect(
      (await pagarLibre(payload, 'lim-3', monto: const Money.soles(1500)))
          .isRight(),
      isTrue,
    );
  });

  test('emitir y leer devuelve nombre enmascarado y monto', () async {
    final charge = await emitir();
    final result = await qr.leer(charge.payload);
    final preview = result.fold((failure) => fail('$failure'), (p) => p);

    expect(preview.nombreEnmascarado, 'J*** M*** R***');
    expect(switch (preview.cobro) {
      QrCobroFijo(:final monto, :final concepto) => (monto, concepto),
      QrCobroLibre() => null,
    }, (const Money.soles(5000), 'Almuerzo'));
    expect(preview.cuentaDestinoId, MemoryLedger.cuentaId);
  });

  test('un QR alterado se rechaza sin mover dinero', () async {
    final charge = await emitir();
    final alterado = charge.payload.replaceFirst('monto=5000', 'monto=100');
    final result = await qr.leer(alterado);

    expect(failureOf(result), isA<QrTampered>());
  });

  test('un QR vencido se rechaza', () async {
    final charge = await emitir();
    now = now.add(const Duration(minutes: 16));
    final result = await qr.leer(charge.payload);

    expect(failureOf(result), isA<QrExpired>());
  });

  test('pagar mueve el saldo y devuelve constancia', () async {
    final charge = await emitir();
    final antesOrigen = ledger.saldoDe(MemoryLedger.cuentaSueldoId);
    final antesDestino = ledger.saldoDe(MemoryLedger.cuentaId);

    final result = await qr.pagar(
      payload: charge.payload,
      cuentaOrigenId: MemoryLedger.cuentaSueldoId,
      pin: '000000',
      idempotencyKey: 'pay-1',
    );
    final receipt = result.fold((failure) => fail('$failure'), (r) => r);

    expect(receipt.monto, const Money.soles(5000));
    expect(receipt.transactionId, isNotEmpty);
    expect(
      ledger.saldoDe(MemoryLedger.cuentaSueldoId),
      antesOrigen - const Money.soles(5000),
    );
    expect(
      ledger.saldoDe(MemoryLedger.cuentaId),
      antesDestino + const Money.soles(5000),
    );
  });

  test('pagar sin saldo devuelve insufficientFunds', () async {
    final charge = await emitir(
      monto: const Money.soles(150000),
      cuentaId: MemoryLedger.cuentaSueldoId,
    );
    final result = await qr.pagar(
      payload: charge.payload,
      cuentaOrigenId: MemoryLedger.cuentaId,
      pin: '000000',
      idempotencyKey: 'pay-2',
    );

    expect(failureOf(result), isA<QrInsufficientFunds>());
  });

  test('un QR pagado no se paga otra vez, pero el reintento sí pasa', () async {
    final charge = await emitir(cuentaId: MemoryTransferRepository.cuentaDestinoId);
    Future<Result<QrFailure, Object?>> pagar(String clave) => qr.pagar(
      payload: charge.payload,
      cuentaOrigenId: MemoryLedger.cuentaId,
      pin: '000000',
      idempotencyKey: clave,
    );

    expect((await pagar('pago-1')).isRight(), isTrue);
    expect((await pagar('pago-1')).isRight(), isTrue);
    expect(failureOf(await pagar('pago-2')), isA<QrAlreadyPaid>());
    expect(failureOf(await qr.leer(charge.payload)), isA<QrAlreadyPaid>());
  });
}
