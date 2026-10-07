import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/recipient_account.dart';
import 'package:cuycash/feature/transfer/domain/recipient_directory.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:cuycash/presentation/transfer/recipient_screen.dart';
import 'package:cuycash/presentation/transfer/widgets/frequent_row.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'fake_transfer_repositories.dart';

const _origen = Account(
  id: 'acc-demo-1',
  numero: '19100000004521',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(125040),
  saldoContable: Money.soles(125040),
);

const _miDirectorio = RecipientDirectory(
  dni: '70123456',
  nombreEnmascarado: 'J*** C*** L***',
  cuentas: [
    RecipientAccount(
      cuentaId: 'acc-demo-1',
      tipo: AccountType.ahorro,
      moneda: Currency.pen,
      numeroMasked: '••••4521',
    ),
    RecipientAccount(
      cuentaId: 'acc-demo-2',
      tipo: AccountType.sueldo,
      moneda: Currency.pen,
      numeroMasked: '••••8800',
      nombre: 'Planilla',
    ),
    RecipientAccount(
      cuentaId: 'acc-demo-3',
      tipo: AccountType.ahorro,
      moneda: Currency.usd,
      numeroMasked: '••••3300',
    ),
  ],
);

const _soloDolares = RecipientDirectory(
  dni: '87654321',
  nombreEnmascarado: 'J*** M*** R***',
  cuentas: [
    RecipientAccount(
      cuentaId: 'acc-ext-3',
      tipo: AccountType.ahorro,
      moneda: Currency.usd,
      numeroMasked: '••••0419',
    ),
  ],
);

Beneficiary _frecuente({RecipientAccount? cuenta}) => Beneficiary(
  id: 'b1',
  dni: '87654321',
  apodo: 'Mamá',
  nombreEnmascarado: 'J*** M*** R***',
  cuenta: cuenta,
);

void main() {
  late TransferBloc bloc;

  tearDown(() => bloc.close());

  Future<TransferBloc> pump(
    WidgetTester t, {
    FakeTransferRepository? repo,
    FutureResult<TransferFailure, RecipientDirectory> Function(String)?
    resolver,
    List<Beneficiary>? frecuentes,
  }) async {
    await t.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    bloc = TransferBloc(
      TransferActions(repo ?? FakeTransferRepository(alResolver: resolver)),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.enviar,
      routes: [
        GoRoute(
          path: AppRoutes.enviar,
          builder: (_, _) => RecipientScreen(
            cuenta: _origen,
            frecuentes: frecuentes == null
                ? null
                : (onSelected) => FrequentRow(
                    beneficiarios: frecuentes,
                    onSelected: onSelected,
                  ),
          ),
        ),
        GoRoute(
          path: AppRoutes.enviarMonto,
          builder: (_, _) => const Text('MONTO'),
        ),
      ],
    );
    await t.pumpWidget(
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
    await t.pump();
    return bloc;
  }

  testWidgets('al completar el DNI aparece una tarjeta por cuenta y no hay '
      'Continuar', (t) async {
    await pump(t);
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    expect(find.text('J*** M*** R***'), findsOneWidget);
    expect(find.text('Ahorros · S/ · ••••7732'), findsOneWidget);
    expect(find.text('Corriente · S/ · ••••5510'), findsOneWidget);
    expect(find.text('Ahorros · US\$ · ••••0419'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Continuar'), findsNothing);
  });

  testWidgets('tocar una tarjeta lleva al monto con esa cuenta', (t) async {
    final bloc = await pump(t);
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    await t.tap(find.text('Corriente · S/ · ••••5510'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsOneWidget);
    expect(bloc.state.destinatario?.cuenta.cuentaId, 'acc-ext-2');
  });

  testWidgets('la cuenta de otra moneda está apagada y dice por qué', (
    t,
  ) async {
    await pump(t);
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    expect(find.text('Solo recibe US\$'), findsOneWidget);
    await t.tap(find.text('Ahorros · US\$ · ••••0419'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsNothing);
  });

  testWidgets('el propio DNI lista mis otras cuentas con nombre y sin la de '
      'origen', (t) async {
    await pump(t, resolver: (_) async => right(_miDirectorio));
    await t.enterText(find.byType(TextField), '70123456');
    await t.pumpAndSettle();
    expect(find.textContaining('••••4521'), findsNothing);
    expect(find.text('Planilla'), findsOneWidget);
  });

  testWidgets('sin cuentas elegibles, aviso', (t) async {
    await pump(t, resolver: (_) async => right(_soloDolares));
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    expect(
      find.text('No tiene cuentas en S/ para recibir desde esta cuenta.'),
      findsOneWidget,
    );
  });

  testWidgets('un frecuente con cuenta lleva directo al monto, sin buscar', (
    t,
  ) async {
    final repo = FakeTransferRepository();
    await pump(
      t,
      repo: repo,
      frecuentes: [_frecuente(cuenta: cuentaDeDestinoDePrueba)],
    );
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsOneWidget);
    expect(repo.busquedas, isEmpty);
  });

  testWidgets('un frecuente de otra moneda avisa y se queda', (t) async {
    await pump(
      t,
      frecuentes: [_frecuente(cuenta: directorioDePrueba.cuentas[2])],
    );
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(
      find.text('Ese frecuente recibe en US\$. Envía desde una cuenta en US\$.'),
      findsOneWidget,
    );
    expect(find.text('MONTO'), findsNothing);
  });

  testWidgets('un frecuente sin cuenta rellena el DNI y busca', (t) async {
    final repo = FakeTransferRepository();
    await pump(t, repo: repo, frecuentes: [_frecuente(cuenta: null)]);
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(repo.busquedas, ['87654321']);
    expect(find.text('Ahorros · S/ · ••••7732'), findsOneWidget);
  });

  testWidgets('un frecuente que es la cuenta de origen avisa y se queda', (
    t,
  ) async {
    await pump(
      t,
      frecuentes: [
        _frecuente(
          cuenta: const RecipientAccount(
            cuentaId: 'acc-demo-1',
            tipo: AccountType.ahorro,
            moneda: Currency.pen,
            numeroMasked: '••••4521',
          ),
        ),
      ],
    );
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(
      find.text('Ese frecuente es la cuenta desde la que envías. Elige otra.'),
      findsOneWidget,
    );
    expect(find.text('MONTO'), findsNothing);
  });

  testWidgets('tras un frecuente directo, al volver no quedan tarjetas viejas', (
    t,
  ) async {
    await pump(t, frecuentes: [_frecuente(cuenta: cuentaDeDestinoDePrueba)]);
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    expect(find.text('Corriente · S/ · ••••5510'), findsOneWidget);
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsOneWidget);
    expect(bloc.state.destinatario?.cuenta.cuentaId, 'acc-ext-1');
    final contexto = t.element(find.text('MONTO'));
    GoRouter.of(contexto).pop();
    await t.pumpAndSettle();
    expect(find.text('Corriente · S/ · ••••5510'), findsNothing);
    expect(find.widgetWithText(TextField, '87654321'), findsNothing);
  });

  testWidgets('con el envío sellado, tocar una tarjeta o un frecuente no hace '
      'nada', (t) async {
    final repo = FakeTransferRepository(
      alEnviar: (_) async => left(const GlobalFailure.server(
        TransferFailure.network(),
      )),
    );
    final bloc = await pump(
      t,
      repo: repo,
      frecuentes: [_frecuente(cuenta: cuentaDeDestinoDePrueba)],
    );
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    bloc
      ..add(TransferEvent.recipientSelected(destinatarioDePrueba))
      ..add(const TransferEvent.amountEntered(monto: Money.soles(5000)))
      ..add(const TransferEvent.confirmationOpened());
    await t.pumpAndSettle();
    bloc.add(const TransferEvent.submitted(pin: '000000'));
    await t.pumpAndSettle();
    expect(bloc.state.outcomeUnknown, isTrue);

    await t.tap(find.text('Corriente · S/ · ••••5510'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsNothing);
    expect(find.widgetWithText(TextField, '87654321'), findsOneWidget);
    expect(bloc.state.destinatario?.cuenta.cuentaId, 'acc-ext-1');
  });
}
