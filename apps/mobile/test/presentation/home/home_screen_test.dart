import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/home/bloc/account_bloc.dart';
import 'package:cuycash/presentation/home/home_action.dart';
import 'package:cuycash/presentation/home/home_screen.dart';
import 'package:cuycash/presentation/home/widgets/movements_card.dart';
import 'package:cuycash/presentation/home/widgets/quick_actions_row.dart';
import 'package:cuycash/presentation/home/widgets/balance_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Igual que en el perfil: el bloc se crea fuera de testWidgets para que su
  // suscripción al broadcast del repo no quede pendiente dentro de FakeAsync.
  late AuthBloc bloc;
  late AccountBloc account;
  late DeviceActions device;

  setUp(() async {
    bloc = AuthBloc(
      AuthActions(
        MemoryAuthRepository(
          initial: const AuthSession(userId: 'u', identifier: '12345678'),
        ),
      ),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    account = AccountBloc(AccountActions(MemoryAccountRepository()))
      ..add(const AccountEvent.started());
    // La carga corre en el reloj real: se espera aquí, fuera de FakeAsync.
    await account.stream.firstWhere((s) => s.status == AccountStatus.ready);
    device = DeviceActions(MemoryDeviceStore());
    await device.saveUser(
      const RememberedUser(
        dni: '12345678',
        fullName: 'Jheampierre Ruiz Salas',
        alias: '@jheampierre',
      ),
    );
  });

  tearDown(() async {
    await bloc.close();
    await account.close();
  });

  Widget wrap() => RepositoryProvider<DeviceActions>.value(
    value: device,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: account),
      ],
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );

  testWidgets('saluda por el nombre y ya no muestra el sello de demostración', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Jheampierre'), findsOneWidget);
    expect(find.text('Datos de demostración'), findsNothing);
  });

  testWidgets('mientras carga muestra el indicador y no el saldo', (
    tester,
  ) async {
    final lento = AccountBloc(AccountActions(MemoryAccountRepository()));
    addTearDown(lento.close);
    await tester.pumpWidget(
      RepositoryProvider<DeviceActions>.value(
        value: device,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: lento),
          ],
          child: MaterialApp(
            theme: CuyCashTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(BalanceCard), findsNothing);
  });

  testWidgets(
    'con la cuenta lista muestra el saldo del servidor y los movimientos',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('S/ 1,250.40'), findsOneWidget);
      expect(find.text('Billetera ••••4521'), findsOneWidget);
      expect(find.text('Bodega Don Aurelio'), findsOneWidget);
      // El signo lo pone la UI sobre el valor absoluto.
      expect(find.text('- S/ 45.00'), findsOneWidget);
      expect(find.text('+ S/ 1,200.00'), findsOneWidget);
      expect(find.textContaining('- -'), findsNothing);
    },
  );

  testWidgets('el ojo oculta y vuelve a mostrar el saldo', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('S/ 1,250.40'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BalanceCard),
        matching: find.byIcon(Icons.visibility),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('S/ 1,250.40'), findsNothing);
    expect(find.text('S/ ••••••'), findsOneWidget);
  });

  testWidgets('sin movimientos dice que aún no hay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: MovementsCard(movements: [])),
      ),
    );

    expect(find.text('Aún no tienes movimientos'), findsOneWidget);
  });

  testWidgets('QuickActionsRow emite el HomeAction correcto', (tester) async {
    final emitted = <HomeAction>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: QuickActionsRow(onAction: emitted.add)),
      ),
    );

    for (final label in ['Enviar', 'Cobrar', 'Recargar', 'Retirar']) {
      await tester.tap(find.text(label));
    }

    expect(emitted, [
      HomeAction.send,
      HomeAction.charge,
      HomeAction.topUp,
      HomeAction.withdraw,
    ]);
  });

  testWidgets('las acciones sin pantalla todavía avisan en vez de callar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(find.text('Disponible en una próxima versión.'), findsOneWidget);
  });
}
