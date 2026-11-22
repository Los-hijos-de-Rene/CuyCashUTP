import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/feature/qr/domain/qr_payment_preview.dart';
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
          .having(
            (s) => switch (s.preview?.cobro) {
              QrCobroFijo(:final monto) => monto,
              _ => null,
            },
            'monto',
            const Money.soles(1000),
          ),
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

  group('"Mi QR" (monto libre)', () {
    FakeQrRepository libre() =>
        FakeQrRepository(alLeer: (_) async => right(previewLibreDePrueba));

    Future<void> leerYEscribir(QrPayBloc bloc, String monto,
        {String mensaje = ''}) async {
      bloc.add(const QrPayloadDetected('cuycash://qr?tipo=libre&demo=1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(QrPayAmountSubmitted(monto: monto, mensaje: mensaje));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    blocTest<QrPayBloc, QrPayState>(
      'continuar sin monto no pasa al PIN',
      build: () => _bloc(libre()),
      act: (bloc) async {
        bloc.add(const QrPayloadDetected('cuycash://qr?tipo=libre&demo=1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const QrPaySubmitted());
      },
      wait: const Duration(milliseconds: 30),
      verify: (bloc) => expect(bloc.state.status, QrPayStatus.preview),
    );

    for (final (texto, tipo) in [
      ('', QrAmountInvalid),
      ('0', QrAmountInvalid),
      ('abc', QrAmountInvalid),
      ('2000.01', QrAmountAboveMax),
    ]) {
      blocTest<QrPayBloc, QrPayState>(
        'el monto "$texto" se rechaza antes del PIN ($tipo)',
        build: () => _bloc(
          FakeQrRepository(
            alLeer: (_) async => right(
              const QrPaymentPreview(
                payload: 'p',
                nombreEnmascarado: 'L*** Q***',
                cuentaDestinoId: 'acc-demo-1',
                moneda: Currency.pen,
                cobro: QrCobroLibre(),
              ),
            ),
          ),
        ),
        act: (bloc) => leerYEscribir(bloc, texto),
        wait: const Duration(milliseconds: 30),
        verify: (bloc) {
          expect(bloc.state.status, QrPayStatus.preview);
          expect(bloc.state.amountError.runtimeType, tipo);
        },
      );
    }

    blocTest<QrPayBloc, QrPayState>(
      'más de lo que queda hoy se avisa antes del PIN, con lo que queda',
      build: () => _bloc(libre()),
      act: (bloc) => leerYEscribir(bloc, '30.01'),
      wait: const Duration(milliseconds: 30),
      verify: (bloc) => expect(switch (bloc.state.amountError) {
        QrAmountAboveDaily(:final disponible) => disponible,
        _ => null,
      }, const Money.soles(3000)),
    );

    blocTest<QrPayBloc, QrPayState>(
      'con monto válido pide el PIN y paga lo escrito, con el mensaje',
      build: () => _bloc(libre()),
      act: (bloc) async {
        await leerYEscribir(bloc, '12.50', mensaje: '  Menú del día ');
        expect(bloc.state.status, QrPayStatus.pin);
        expect(bloc.state.monto, const Money.soles(1250));
        for (var i = 0; i < 6; i++) {
          bloc.add(const QrPayPinDigit(0));
        }
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, QrPayStatus.done),
    );
  });

  test('el pago libre manda monto y mensaje; el fijo, ninguno', () async {
    final libre = FakeQrRepository(alLeer: (_) async => right(previewLibreDePrueba));
    final blocLibre = _bloc(libre);
    blocLibre.add(const QrPayloadDetected('libre'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    blocLibre.add(const QrPayAmountSubmitted(monto: '12.50', mensaje: ' Menú '));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    for (var i = 0; i < 6; i++) {
      blocLibre.add(const QrPayPinDigit(0));
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(blocLibre.state.status, QrPayStatus.done);
    expect(libre.montoPagado, const Money.soles(1250));
    expect(libre.mensajePagado, 'Menú');

    final fijo = FakeQrRepository();
    final blocFijo = _bloc(fijo);
    blocFijo.add(const QrPayloadDetected('fijo'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // En un cobro fijo el monto escrito se ignora: no hay campo.
    blocFijo.add(const QrPayAmountSubmitted(monto: '99'));
    blocFijo.add(const QrPaySubmitted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    for (var i = 0; i < 6; i++) {
      blocFijo.add(const QrPayPinDigit(0));
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(blocFijo.state.status, QrPayStatus.done);
    expect(fijo.montoPagado, isNull);
    expect(fijo.mensajePagado, isNull);
    await blocLibre.close();
    await blocFijo.close();
  });
}
