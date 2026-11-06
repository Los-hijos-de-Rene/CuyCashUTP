import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/feature/qr/domain/qr_charge.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
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

  test('emitir y leer devuelve nombre enmascarado y monto', () async {
    final charge = await emitir();
    final result = await qr.leer(charge.payload);
    final preview = result.fold((failure) => fail('$failure'), (p) => p);

    expect(preview.nombreEnmascarado, 'J*** M*** R***');
    expect(preview.monto, const Money.soles(5000));
    expect(preview.concepto, 'Almuerzo');
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
