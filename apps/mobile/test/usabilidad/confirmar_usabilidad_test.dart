// APF3 · Usabilidad del paso "Confirmar con PIN" del envío (ISO 25010).
// Spec: docs/apf3/spec-jheampierre-usabilidad-ui.md
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:cuycash/presentation/transfer/confirm_screen.dart';
import 'package:cuycash/presentation/transfer/receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../presentation/transfer/fake_transfer_repositories.dart';
import '_harness.dart';

const _cuenta = Account(
  id: 'acc-demo-1',
  numero: '19100000004521',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(125040),
  saldoContable: Money.soles(125040),
);
const _monto = Money.soles(5000);

void main() {
  late FakeTransferRepository repo;
  late TransferBloc bloc;

  Future<void> preparar() async {
    repo = FakeTransferRepository();
    bloc = TransferBloc(
      TransferActions(repo),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    bloc.add(const TransferEvent.started(_cuenta));
    bloc.add(const TransferEvent.recipientSelected(destinatarioDePrueba));
    await bloc.stream.firstWhere((s) => s.status == TransferStatus.ready);
    bloc.add(const TransferEvent.amountEntered(monto: _monto, motivo: 'Almuerzo'));
    bloc.add(const TransferEvent.confirmationOpened());
    await bloc.stream.firstWhere((s) => s.idempotencyKey.isNotEmpty);
  }

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    await preparar();
    final router = GoRouter(
      initialLocation: AppRoutes.enviarConfirmar,
      routes: [
        GoRoute(
          path: AppRoutes.enviarConfirmar,
          builder: (_, _) => const ConfirmScreen(),
        ),
        GoRoute(
          path: AppRoutes.enviarConstancia,
          builder: (_, _) => const ReceiptScreen(),
        ),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('INICIO')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: appRouterDePrueba(router: router, textScale: textScale),
      ),
    );
    await tester.pump();
  }

  Future<void> escribirPin(WidgetTester tester, [String pin = '000000']) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  Finder boton() =>
      find.widgetWithText(ElevatedButton, 'Confirmar transferencia');

  group('UX-CONFIRMAR · accesibilidad', () {
    testWidgets('UX-CONF-01 áreas táctiles y etiquetas accesibles', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);
      await verificarAccesibilidad(t);
    });
  });

  group('UX-CONFIRMAR · adaptabilidad', () {
    testWidgets('UX-CONF-02 con texto al 200 % no hay desbordes', (t) async {
      fijarPantalla(t);
      await pump(t, textScale: 2);
      verificarSinDesbordes(t);
    });

    testWidgets('UX-CONF-03 en un teléfono de 320×568 no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(t);
      verificarSinDesbordes(t);
    });
  });

  group('UX-CONFIRMAR · protección contra errores', () {
    testWidgets('UX-CONF-04 no se puede confirmar hasta tener los 6 dígitos', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);

      expect(t.widget<ElevatedButton>(boton()).onPressed, isNull);
      await escribirPin(t, '00000');
      expect(t.widget<ElevatedButton>(boton()).onPressed, isNull);
      await escribirPin(t, '0');
      expect(t.widget<ElevatedButton>(boton()).onPressed, isNotNull);
    });

    testWidgets('UX-CONF-05 el dinero no se mueve sin el PIN completo', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);

      // Tocar "Confirmar" sin PIN no llama al repositorio.
      await t.tap(boton());
      await t.pump();
      expect(repo.llamadas, 0);

      await escribirPin(t);
      await t.tap(boton());
      await t.pumpAndSettle();

      expect(repo.llamadas, 1);
      expect(repo.pines.single, '000000');
    });
  });
}
