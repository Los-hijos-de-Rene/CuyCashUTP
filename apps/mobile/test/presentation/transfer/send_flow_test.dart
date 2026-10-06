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
import 'package:cuycash/presentation/transfer/recipient_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Recorre la tabla de rutas REAL (`createAppRouter`) con los repositorios en
/// memoria del flavor `mock`: del inicio a la constancia.
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

  testWidgets('"Enviar" del inicio abre el flujo real, ya no el aviso', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipientScreen), findsOneWidget);
    expect(find.text('¿A quién le envías?'), findsOneWidget);
    expect(find.text('Disponible en una próxima versión.'), findsNothing);
  });

  testWidgets('recorrido completo: DNI, monto, PIN y constancia', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '87654321');
    await tester.pumpAndSettle();
    expect(find.text('J*** M*** R***'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '50');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    for (final d in '000000'.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Confirmar transferencia'),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Envío realizado!'), findsOneWidget);
    expect(find.textContaining('J*** M*** R***'), findsOneWidget);

    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Últimos movimientos'), findsOneWidget);
    // El inicio se refresca solo: S/ 1,250.40 - S/ 50.00.
    expect(find.text('S/ 1,200.40'), findsOneWidget);
    expect(find.text('S/ 1,250.40'), findsNothing);
  });

  testWidgets('un DNI inexistente se explica y no deja continuar', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '11111111');
    await tester.pumpAndSettle();

    expect(
      find.text('No encontramos a nadie con ese DNI en CuyCash.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Continuar'),
          )
          .onPressed,
      isNull,
    );
  });
}
