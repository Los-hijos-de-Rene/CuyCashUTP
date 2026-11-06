import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/presentation/qr/bloc/qr_pay_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'qr_test_support.dart';

const _cuenta = Account(
  id: 'acc-demo-2',
  numero: '19100000008830',
  tipo: AccountType.sueldo,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(350000),
  saldoContable: Money.soles(350000),
);

QrPayBloc _bloc(FakeQrRepository repo) => QrPayBloc(
      actions: QrActions(repo),
      cuentaOrigen: _cuenta,
      userId: 'u1',
      clock: () => DateTime.utc(2026, 11, 4, 12),
    );

void main() {
  String? leido;

  blocTest<QrPayBloc, QrPayState>(
    'leer un QR muestra nombre y monto antes de confirmar',
    build: () => _bloc(FakeQrRepository()),
    act: (bloc) => bloc.add(const QrPayloadDetected('cuycash://qr?demo=1')),
    expect: () => [
      isA<QrPayState>()
          .having((s) => s.status, 'status', QrPayStatus.reading),
      isA<QrPayState>()
          .having((s) => s.status, 'status', QrPayStatus.preview)
          .having((s) => s.preview?.nombreEnmascarado, 'nombre', 'J*** M*** R***')
          .having((s) => s.preview?.monto, 'monto', const Money.soles(1000)),
    ],
  );

  blocTest<QrPayBloc, QrPayState>(
    'pegar el mensaje compartido lee solo el código',
    build: () => _bloc(
      FakeQrRepository(
        alLeer: (payload) async {
          leido = payload;
          return left(GlobalFailure.server(const QrFailure.expired()));
        },
      ),
    ),
    act: (bloc) => bloc.add(
      const QrPayloadDetected(
        'Cóbralo con CuyCash: S/ 5.00 por «Taxi».\ncuycash://qr?demo=1',
      ),
    ),
    verify: (_) => expect(leido, 'cuycash://qr?demo=1'),
  );

  blocTest<QrPayBloc, QrPayState>(
    'un QR vencido se explica sin llegar a la confirmación',
    build: () => _bloc(
      FakeQrRepository(
        alLeer: (_) async =>
            left(GlobalFailure.server(const QrFailure.expired())),
      ),
    ),
    act: (bloc) => bloc.add(const QrPayloadDetected('vencido')),
    expect: () => [
      isA<QrPayState>()
          .having((s) => s.status, 'status', QrPayStatus.reading),
      isA<QrPayState>()
          .having((s) => s.status, 'status', QrPayStatus.error)
          .having((s) => s.failure, 'failure', isA<QrExpired>()),
    ],
  );

  blocTest<QrPayBloc, QrPayState>(
    'un QR alterado se explica sin llegar a la confirmación',
    build: () => _bloc(
      FakeQrRepository(
        alLeer: (_) async =>
            left(GlobalFailure.server(const QrFailure.tampered())),
      ),
    ),
    act: (bloc) => bloc.add(const QrPayloadDetected('alterado')),
    expect: () => [
      isA<QrPayState>()
          .having((s) => s.status, 'status', QrPayStatus.reading),
      isA<QrPayState>()
          .having((s) => s.status, 'status', QrPayStatus.error)
          .having((s) => s.failure, 'failure', isA<QrTampered>()),
    ],
  );

  blocTest<QrPayBloc, QrPayState>(
    'sin saldo se explica al confirmar',
    build: () => _bloc(
      FakeQrRepository(
        alPagar: (_) async => left(
          GlobalFailure.server(const QrFailure.insufficientFunds()),
        ),
      ),
    ),
    act: (bloc) async {
      bloc.add(const QrPayloadDetected('cuycash://qr?demo=1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const QrPaySubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      for (var i = 0; i < 6; i++) {
        bloc.add(const QrPayPinDigit(0));
      }
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.status, QrPayStatus.error);
      expect(bloc.state.failure, isA<QrInsufficientFunds>());
    },
  );

  blocTest<QrPayBloc, QrPayState>(
    'seis dígitos pagan y dejan la constancia',
    build: () => _bloc(FakeQrRepository()),
    act: (bloc) async {
      bloc.add(const QrPayloadDetected('cuycash://qr?demo=1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const QrPaySubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      for (var i = 0; i < 6; i++) {
        bloc.add(const QrPayPinDigit(0));
      }
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.status, QrPayStatus.done);
      expect(bloc.state.receipt?.transactionId, 'tx-qr-1');
      expect(bloc.state.receipt?.monto, const Money.soles(1000));
    },
  );

  blocTest<QrPayBloc, QrPayState>(
    'un PIN errado limpia el PIN y deja reintentar',
    build: () => _bloc(
      FakeQrRepository(
        alPagar: (_) async =>
            left(GlobalFailure.server(const QrFailure.wrongPin(2))),
      ),
    ),
    act: (bloc) async {
      bloc.add(const QrPayloadDetected('cuycash://qr?demo=1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const QrPaySubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      for (var i = 0; i < 6; i++) {
        bloc.add(const QrPayPinDigit(0));
      }
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.status, QrPayStatus.pin);
      expect(bloc.state.pin, isEmpty);
      expect(bloc.state.failure, isA<QrWrongPin>());
    },
  );
}
