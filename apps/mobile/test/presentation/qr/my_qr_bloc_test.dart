import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/presentation/qr/bloc/my_qr_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'qr_test_support.dart';

const cuentaDePrueba = Account(
  id: 'acc-demo-1',
  numero: '19100000008830',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(0),
  saldoContable: Money.soles(0),
);

MyQrBloc _bloc(FakeQrRepository repo) =>
    MyQrBloc(actions: QrActions(repo), cuenta: cuentaDePrueba);

void main() {
  blocTest<MyQrBloc, MyQrState>(
    'carga el QR de la cuenta',
    build: () => _bloc(FakeQrRepository()),
    act: (bloc) => bloc.add(const MyQrRequested()),
    expect: () => [
      isA<MyQrLoading>(),
      isA<MyQrReady>().having((s) => s.qr, 'qr', staticDePrueba),
    ],
  );

  blocTest<MyQrBloc, MyQrState>(
    'si no se puede cargar, lo explica',
    build: () => _bloc(
      FakeQrRepository(
        alMiQr: () async => left(GlobalFailure.server(const QrFailure.network())),
      ),
    ),
    act: (bloc) => bloc.add(const MyQrRequested()),
    expect: () => [
      isA<MyQrLoading>(),
      isA<MyQrError>().having((s) => s.failure, 'failure', isA<QrNetworkFailure>()),
    ],
  );

  blocTest<MyQrBloc, MyQrState>(
    'cambiar el QR muestra el nuevo y lo avisa',
    build: () => _bloc(FakeQrRepository()),
    seed: () => const MyQrReady(staticDePrueba),
    act: (bloc) => bloc.add(const MyQrRegenerateRequested()),
    expect: () => [
      isA<MyQrReady>()
          .having((s) => s.regenerando, 'regenerando', isTrue)
          .having((s) => s.qr, 'qr', staticDePrueba),
      isA<MyQrReady>()
          .having((s) => s.regenerado, 'regenerado', isTrue)
          .having((s) => s.qr, 'qr', staticNuevoDePrueba),
    ],
  );

  blocTest<MyQrBloc, MyQrState>(
    'si cambiarlo falla, el QR actual sigue a la vista',
    build: () => _bloc(
      FakeQrRepository(
        alRegenerar: () async =>
            left(GlobalFailure.server(const QrFailure.network())),
      ),
    ),
    seed: () => const MyQrReady(staticDePrueba),
    act: (bloc) => bloc.add(const MyQrRegenerateRequested()),
    expect: () => [
      isA<MyQrReady>().having((s) => s.regenerando, 'regenerando', isTrue),
      isA<MyQrReady>()
          .having((s) => s.qr, 'qr', staticDePrueba)
          .having((s) => s.failure, 'failure', isA<QrNetworkFailure>()),
    ],
  );

  test('dos toques seguidos no regeneran dos veces', () async {
    // Tarda: el segundo toque llega mientras el primero sigue en curso.
    final repo = FakeQrRepository(
      alRegenerar: () => Future.delayed(
        const Duration(milliseconds: 10),
        () => right(staticNuevoDePrueba),
      ),
    );
    final bloc = _bloc(repo)..emit(const MyQrReady(staticDePrueba));
    bloc
      ..add(const MyQrRegenerateRequested())
      ..add(const MyQrRegenerateRequested());
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(repo.regeneraciones, 1);
    await bloc.close();
  });
}
