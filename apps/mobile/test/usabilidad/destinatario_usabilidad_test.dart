// APF3 · Usabilidad del paso "¿A quién?" del envío (ISO 25010).
// Spec: docs/apf3/spec-jheampierre-usabilidad-ui.md
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:cuycash/presentation/transfer/recipient_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../presentation/transfer/fake_transfer_repositories.dart';
import '_harness.dart';

const _origen = Account(
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

  tearDown(() => bloc.close());

  Future<void> pump(
    WidgetTester tester, {
    FakeTransferRepository? repo,
    double textScale = 1,
  }) async {
    bloc = TransferBloc(
      TransferActions(repo ?? FakeTransferRepository()),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.enviar,
      routes: [
        GoRoute(
          path: AppRoutes.enviar,
          builder: (_, _) => RecipientScreen(cuenta: _origen),
        ),
        GoRoute(
          path: AppRoutes.enviarMonto,
          builder: (_, _) => const Text('MONTO'),
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

  group('UX-DESTINATARIO · accesibilidad', () {
    testWidgets('UX-DEST-01 áreas táctiles y etiquetas accesibles', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);
      await verificarAccesibilidad(t);
    });
  });

  group('UX-DESTINATARIO · adaptabilidad', () {
    testWidgets('UX-DEST-02 con texto al 200 % no hay desbordes', (t) async {
      fijarPantalla(t);
      await pump(t, textScale: 2);
      verificarSinDesbordes(t);
    });

    testWidgets('UX-DEST-03 en un teléfono de 320×568 no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(t);
      verificarSinDesbordes(t);
    });
  });

  group('UX-DESTINATARIO · protección contra errores', () {
    testWidgets('UX-DEST-04 "Buscar" solo aparece con un alias válido', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);

      expect(find.widgetWithText(OutlinedButton, 'Buscar'), findsNothing);
      await t.enterText(find.byType(TextField), 'JMRosa');
      await t.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Buscar'), findsOneWidget);
    });

    testWidgets('UX-DEST-05 un DNI desconocido explica qué pasó y qué hacer', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(
        t,
        repo: FakeTransferRepository(
          alResolver: (_) async => left(
            GlobalFailure.server(const TransferFailure.recipientNotFound()),
          ),
        ),
      );

      await t.enterText(find.byType(TextField), '87654321');
      await t.pumpAndSettle();

      const mensaje =
          'No encontramos a nadie con ese DNI o alias en CuyCash.';
      expect(find.text(mensaje), findsOneWidget);
      verificarSinCodigosTecnicos(mensaje);
    });
  });
}
