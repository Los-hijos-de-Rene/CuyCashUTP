import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/app/router.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/topup/topup_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Recarga por la tabla de rutas REAL (`createAppRouter`) con los repositorios
/// en memoria del flavor `mock`.
void main() {
  late AuthBloc auth;

  setUp(() {
    auth = AuthBloc(
      AuthActions(
        MemoryAuthRepository(
          initial: const AuthSession(userId: 'u', identifier: '70123456'),
        ),
      ),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
  });
  tearDown(() => auth.close());

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deps = await buildMockDependencies();
    final router = createAppRouter(deps, auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider<DeviceActions>.value(
        value: DeviceActions(MemoryDeviceStore()),
        child: BlocProvider.value(
          value: auth,
          child: MaterialApp.router(
            routerConfig: router,
            theme: CuyCashTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('"Recargar" del inicio abre la pantalla real, ya no el aviso', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();

    expect(find.byType(TopUpScreen), findsOneWidget);
    expect(find.text('¿Cuánto quieres recargar?'), findsOneWidget);
    expect(find.text('Disponible en una próxima versión.'), findsNothing);
  });

  testWidgets(
    'recorrido completo: monto, PIN, constancia y de vuelta al inicio',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Recargar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '100');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
      await tester.pumpAndSettle();
      for (final d in '000000'.split('')) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmar recarga'),
      );
      await tester.pumpAndSettle();
      expect(find.text('¡Recarga realizada!'), findsOneWidget);

      await tester.tap(find.text('Volver al inicio'));
      await tester.pumpAndSettle();
      expect(find.byType(TopUpScreen), findsNothing);
      expect(find.text('Últimos movimientos'), findsOneWidget);
      // El saldo sube sin tirar para refrescar: S/ 1,250.40 + S/ 100.00.
      expect(find.text('S/ 1,350.40'), findsOneWidget);
      expect(find.text('S/ 1,250.40'), findsNothing);
    },
  );

  testWidgets('recarga en dólares: chip, PIN, constancia y saldo en US\$', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('US\$ 120.00'), findsOneWidget);

    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('US\$ 20.00'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    for (final d in '000000'.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar recarga'));
    await tester.pumpAndSettle();
    expect(find.text('¡Recarga realizada!'), findsOneWidget);
    expect(find.text('US\$ 20.00'), findsWidgets);

    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('US\$ 140.00'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('S/ 1,250.40'), findsOneWidget);
  });

  testWidgets('abrir /recargar sin cuenta (deep link) lleva al inicio', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    router.go(AppRoutes.recargar);
    await tester.pumpAndSettle();

    expect(find.byType(TopUpScreen), findsNothing);
    expect(find.text('Últimos movimientos'), findsOneWidget);
  });
}
