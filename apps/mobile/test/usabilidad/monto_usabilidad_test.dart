// APF3 · Usabilidad del paso "¿Cuánto?" del envío (ISO 25010).
// Spec: docs/apf3/spec-jheampierre-usabilidad-ui.md
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/transfer/amount_screen.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
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

void main() {
  late TransferBloc bloc;

  Future<void> prepararBloc() async {
    bloc = TransferBloc(
      TransferActions(FakeTransferRepository()),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    bloc.add(const TransferEvent.started(_cuenta));
    bloc.add(const TransferEvent.recipientSelected(destinatarioDePrueba));
    await bloc.stream.firstWhere((s) => s.status == TransferStatus.ready);
  }

  setUp(prepararBloc);
  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    final router = GoRouter(
      initialLocation: AppRoutes.enviarMonto,
      routes: [
        GoRoute(
          path: AppRoutes.enviarMonto,
          builder: (_, _) => const AmountScreen(),
        ),
        GoRoute(
          path: AppRoutes.enviarConfirmar,
          builder: (_, _) => const Text('CONFIRMAR'),
        ),
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

  Finder continuar() => find.widgetWithText(ElevatedButton, 'Continuar');
  bool habilitado(WidgetTester t) =>
      t.widget<ElevatedButton>(continuar()).onPressed != null;

  group('UX-MONTO · accesibilidad', () {
    testWidgets('UX-MONTO-01 áreas táctiles y etiquetas accesibles', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);
      await verificarAccesibilidad(t);
    });
  });

  group('UX-MONTO · adaptabilidad', () {
    testWidgets('UX-MONTO-02 con texto al 200 % no hay desbordes', (t) async {
      fijarPantalla(t);
      await pump(t, textScale: 2);
      verificarSinDesbordes(t);
    });

    testWidgets('UX-MONTO-03 en un teléfono de 320×568 no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(t);
      verificarSinDesbordes(t);
    });
  });

  group('UX-MONTO · protección contra errores', () {
    testWidgets('UX-MONTO-04 Continuar está deshabilitado sin un monto válido', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);

      expect(habilitado(t), isFalse);
      await t.enterText(find.byType(TextField).first, '10');
      await t.pump();
      expect(habilitado(t), isTrue);
    });

    testWidgets('UX-MONTO-05 un monto fuera del límite dice cuál es el máximo', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);

      await t.enterText(find.byType(TextField).first, '2001');
      await t.pump();

      expect(find.textContaining('máximo por envío'), findsOneWidget);
      expect(habilitado(t), isFalse);
    });
  });
}
