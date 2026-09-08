import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/lockout/access_blocked_screen.dart';
import 'package:cuycash/presentation/lockout/blocked_args.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Al agotarse el bloqueo la app debe REGRESAR al punto de entrada del que
/// vino, no quedarse con el contador en cero. Se monta un router mínimo con el
/// mismo cableado que usa `createAppRouter` para verificar el destino real.
void main() {
  final t0 = DateTime(2026, 3, 1, 10);
  late DateTime now;

  setUp(() => now = t0);

  Future<GoRouter> pumpRouter(WidgetTester tester, BlockedOrigin origin) async {
    final router = GoRouter(
      initialLocation: AppRoutes.blocked,
      routes: [
        GoRoute(
          path: AppRoutes.blocked,
          builder: (context, state) => AccessBlockedScreen(
            lockedUntil: t0.add(const Duration(seconds: 10)),
            origin: origin,
            clock: () => now,
            onExpired: (origin) =>
                context.go(origin.entryRoute, extra: '12345678'),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          // Refleja el cableado real: el DNI vuelve como `extra`.
          builder: (context, state) => Text('login:${state.extra}'),
        ),
        GoRoute(
          path: AppRoutes.quickAccess,
          builder: (context, state) => const Text('acceso rápido'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ));
    await tester.pump();
    return router;
  }

  testWidgets('bloqueo del acceso rápido → vuelve a acceso rápido',
      (tester) async {
    await pumpRouter(tester, BlockedOrigin.quickAccess);
    expect(find.text('Tu acceso está bloqueado'), findsOneWidget);

    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text('acceso rápido'), findsOneWidget);
    expect(find.text('Tu acceso está bloqueado'), findsNothing);
  });

  testWidgets('bloqueo del login → vuelve al login', (tester) async {
    await pumpRouter(tester, BlockedOrigin.login);

    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    // Vuelve al login CON el DNI: esperar el bloqueo ya fue suficiente castigo.
    expect(find.text('login:12345678'), findsOneWidget);
    expect(find.text('Tu acceso está bloqueado'), findsNothing);
  });
}
