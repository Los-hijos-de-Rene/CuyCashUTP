import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/transfer/amount_screen.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_transfer_repositories.dart';

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

  setUp(() async {
    bloc = TransferBloc(
      TransferActions(FakeTransferRepository()),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    bloc.add(const TransferEvent.started(_cuenta));
    bloc.add(const TransferEvent.recipientRequested('87654321'));
    await bloc.stream.firstWhere((s) => s.status == TransferStatus.ready);
  });
  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(
          routerConfig: router,
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
  }

  Finder campoMonto() => find.byType(TextField).first;
  Finder continuar() => find.widgetWithText(ElevatedButton, 'Continuar');
  bool habilitado(WidgetTester t) =>
      t.widget<ElevatedButton>(continuar()).onPressed != null;

  testWidgets('muestra el disponible real y los montos sugeridos', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Disponible: S/ 1,250.40'), findsOneWidget);
    for (final s in ['S/ 20.00', 'S/ 50.00', 'S/ 100.00', 'S/ 200.00']) {
      expect(find.text(s), findsOneWidget);
    }
    expect(habilitado(tester), isFalse);
  });

  testWidgets('la coma de miles no se puede teclear y se avisa por qué', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(campoMonto(), '1,234');
    await tester.pump();

    // El campo no se queda con "1,234": vuelve a lo último válido (vacío).
    expect(tester.widget<TextField>(campoMonto()).controller!.text, isEmpty);
    expect(
      find.text('Escribe el monto sin comas de miles. Ejemplo: 1250.50'),
      findsOneWidget,
    );
    expect(habilitado(tester), isFalse);
  });

  testWidgets('el pegado de 1,234.56 se rechaza con aviso, no en silencio', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(campoMonto(), '1,234.56');
    await tester.pump();

    expect(tester.widget<TextField>(campoMonto()).controller!.text, isEmpty);
    expect(find.textContaining('sin comas de miles'), findsOneWidget);
  });

  testWidgets('el aviso desaparece al seguir escribiendo bien', (tester) async {
    await pump(tester);
    await tester.enterText(campoMonto(), '1,234');
    await tester.enterText(campoMonto(), '50');
    await tester.pump();

    expect(find.textContaining('sin comas de miles'), findsNothing);
    expect(habilitado(tester), isTrue);
  });

  testWidgets('la coma decimal sí vale: 12,50 son S/ 12.50', (tester) async {
    await pump(tester);
    await tester.enterText(campoMonto(), '12,50');
    await tester.pump();
    await tester.tap(continuar());
    await tester.pumpAndSettle();

    expect(bloc.state.monto, const Money.soles(1250));
  });

  testWidgets('un monto mayor al disponible no deja continuar y lo explica', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(campoMonto(), '1300');
    await tester.pump();

    expect(find.textContaining('Supera tu saldo disponible'), findsOneWidget);
    expect(habilitado(tester), isFalse);
  });

  testWidgets('más de S/ 2,000.00 por envío no deja continuar', (tester) async {
    await pump(tester);
    await tester.enterText(campoMonto(), '2000.01');
    await tester.pump();

    expect(find.text('El máximo por envío es S/ 2,000.00.'), findsOneWidget);
    expect(habilitado(tester), isFalse);
  });

  testWidgets('cero no deja continuar', (tester) async {
    await pump(tester);
    await tester.enterText(campoMonto(), '0');
    await tester.pump();

    expect(find.text('El monto debe ser mayor a S/ 0.00.'), findsOneWidget);
    expect(habilitado(tester), isFalse);
  });

  testWidgets('un separador al final (5.) es una edición a medias, sin error', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(campoMonto(), '5.');
    await tester.pump();

    expect(find.textContaining('monto válido'), findsNothing);
    expect(habilitado(tester), isFalse);
  });

  testWidgets('un monto sugerido rellena el campo', (tester) async {
    await pump(tester);
    await tester.tap(find.text('S/ 100.00'));
    await tester.pump();

    expect(tester.widget<TextField>(campoMonto()).controller!.text, '100');
    expect(habilitado(tester), isTrue);
  });

  testWidgets('el motivo se limita a 40 caracteres en el campo', (
    tester,
  ) async {
    await pump(tester);
    final motivo = find.byType(TextField).last;
    await tester.enterText(motivo, 'x' * 60);
    await tester.pump();

    expect(tester.widget<TextField>(motivo).controller!.text.length, 40);
  });

  testWidgets('continuar guarda monto y motivo y abre la confirmación', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(campoMonto(), '75.5');
    await tester.enterText(find.byType(TextField).last, 'Almuerzo');
    await tester.pump();
    await tester.tap(continuar());
    await tester.pumpAndSettle();

    expect(bloc.state.monto, const Money.soles(7550));
    expect(bloc.state.motivo, 'Almuerzo');
    expect(find.text('CONFIRMAR'), findsOneWidget);
  });

  testWidgets(
    '"Continuar" se apaga mientras el aviso de rechazo está visible',
    (tester) async {
      await pump(tester);
      await tester.enterText(campoMonto(), '50');
      await tester.pump();
      expect(habilitado(tester), isTrue);

      // Un pegado inválido: el campo conserva "50" (válido) pero hay un aviso.
      await tester.enterText(campoMonto(), '1,234');
      await tester.pump();

      expect(find.textContaining('sin comas de miles'), findsOneWidget);
      expect(habilitado(tester), isFalse);
    },
  );

  testWidgets(
    'letras o un tercer decimal NO se explican como "comas de miles"',
    (tester) async {
      await pump(tester);

      await tester.enterText(campoMonto(), 'abc');
      await tester.pump();
      expect(find.textContaining('sin comas de miles'), findsNothing);
      expect(
        find.text('Escribe un monto válido, como 50 o 50.50.'),
        findsOneWidget,
      );

      await tester.enterText(campoMonto(), '1.234');
      await tester.pump();
      expect(find.textContaining('sin comas de miles'), findsNothing);
      expect(find.textContaining('monto válido'), findsOneWidget);
    },
  );
}
