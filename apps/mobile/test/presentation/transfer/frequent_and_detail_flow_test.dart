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
import 'package:cuycash/presentation/transfer/widgets/frequent_row.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Frecuentes y detalle del movimiento, recorriendo la tabla de rutas REAL
/// (`createAppRouter`) con los repositorios en memoria del flavor `mock`.
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

  Future<void> enviarCincuenta(
    WidgetTester tester, {
    bool guardar = false,
  }) async {
    await tester.enterText(find.byType(TextField), '87654321');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '50');
    await tester.pump();
    if (guardar) {
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pump();
    }
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
  }

  testWidgets('la pantalla de monto ofrece guardar como frecuente', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '87654321');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Guardar como frecuente'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('guardar como frecuente: aparece la próxima vez y un toque '
      'rellena el DNI', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    // Sin frecuentes todavía no hay fila.
    expect(find.text('Frecuentes'), findsNothing);

    await enviarCincuenta(tester, guardar: true);
    expect(find.text('¡Envío realizado!'), findsOneWidget);
    expect(
      find.text(
        'El envío se realizó, pero no pudimos guardar a esta persona como '
        'frecuente.',
      ),
      findsNothing,
    );

    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Frecuentes'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(FrequentRow),
        matching: find.text('J*** M*** R***'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '87654321'), findsOneWidget);
    expect(find.text('Cuenta ••••7732'), findsOneWidget);
  });

  testWidgets('sin encender el interruptor el destinatario no se guarda', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    await enviarCincuenta(tester);
    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Frecuentes'), findsNothing);
  });

  testWidgets('tocar un movimiento del inicio abre su detalle', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Bodega Don Aurelio'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle del movimiento'), findsOneWidget);
    expect(find.text('Enviaste'), findsOneWidget);
    expect(find.text('S/ 45.00'), findsOneWidget);
    expect(find.text('tx-demo-1'), findsOneWidget);
    expect(find.text('Compartir constancia'), findsOneWidget);
  });

  testWidgets('un movimiento que no existe dice que no existe', (tester) async {
    final router = await pumpApp(tester);

    router.push(AppRoutes.movimientoDe('tx-ajena'));
    await tester.pumpAndSettle();

    expect(find.text('No encontramos este movimiento.'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });
}
