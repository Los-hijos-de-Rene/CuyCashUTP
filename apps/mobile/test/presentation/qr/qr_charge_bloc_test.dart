import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/presentation/qr/bloc/qr_charge_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:bloc_test/bloc_test.dart';

import 'qr_test_support.dart';

void main() {
  blocTest<QrChargeBloc, QrChargeState>(
    'generar un cobro queda listo con el QR',
    build: () => QrChargeBloc(QrActions(FakeQrRepository())),
    act: (bloc) => bloc.add(
      const QrChargeRequested(
        cuentaId: 'acc-demo-1',
        monto: Money.soles(1000),
        concepto: 'Almuerzo',
        idempotencyKey: 'k-1',
      ),
    ),
    expect: () => [
      isA<QrChargeState>()
          .having((s) => s.status, 'status', QrChargeStatus.generating),
      isA<QrChargeState>()
          .having((s) => s.status, 'status', QrChargeStatus.ready)
          .having((s) => s.charge?.monto, 'monto', const Money.soles(1000)),
    ],
  );

  blocTest<QrChargeBloc, QrChargeState>(
    'un fallo al emitir deja el estado de error',
    build: () => QrChargeBloc(
      QrActions(
        FakeQrRepository(
          alEmitir: () async => left(
            GlobalFailure.server(const QrFailure.tampered()),
          ),
        ),
      ),
    ),
    act: (bloc) => bloc.add(
      const QrChargeRequested(
        cuentaId: 'acc-demo-1',
        monto: Money.soles(1000),
        concepto: 'Almuerzo',
        idempotencyKey: 'k-2',
      ),
    ),
    expect: () => [
      isA<QrChargeState>()
          .having((s) => s.status, 'status', QrChargeStatus.generating),
      isA<QrChargeState>()
          .having((s) => s.status, 'status', QrChargeStatus.error)
          .having((s) => s.failure, 'failure', isA<QrTampered>()),
    ],
  );

  blocTest<QrChargeBloc, QrChargeState>(
    'reset vuelve al formulario',
    build: () => QrChargeBloc(QrActions(FakeQrRepository())),
    seed: () => const QrChargeState.error(QrFailure.unexpected()),
    act: (bloc) => bloc.add(const QrChargeReset()),
    expect: () => [
      isA<QrChargeState>()
          .having((s) => s.status, 'status', QrChargeStatus.idle),
    ],
  );
}
