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
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Abrir otra cuenta desde el carrusel, con el grafo `mock` real.
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

  testWidgets('abrir una cuenta en dólares desde el carrusel', (tester) async {
    await pumpApp(tester);
    // Deslizar hasta la última página (3 cuentas + abrir).
    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Abrir otra cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué cuenta quieres abrir?'), findsOneWidget);
    // Sueldo deshabilitada: la demo ya tiene una.
    expect(find.text('Ya tienes una cuenta sueldo.'), findsOneWidget);
    await tester.tap(find.text('Corriente'));
    await tester.tap(find.text('Dólares'));
    await tester.enterText(find.byType(TextField), 'Viaje');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    for (final d in '000000'.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir cuenta'));
    await tester.pumpAndSettle();

    // De vuelta en el inicio, con la cuenta nueva a la vista.
    expect(find.text('Viaje'), findsOneWidget);
    expect(find.text(r'US$ 0.00'), findsOneWidget);
  });
}
