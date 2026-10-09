import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/lockout/access_blocked_screen.dart';
import 'package:cuycash/presentation/lockout/blocked_args.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 3, 1, 10);
  late DateTime now;

  setUp(() => now = t0);

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Duration remaining,
    required BlockedOrigin origin,
    ValueChanged<BlockedOrigin>? onExpired,
  }) =>
      tester.pumpWidget(MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccessBlockedScreen(
          lockedUntil: t0.add(remaining),
          origin: origin,
          onExpired: onExpired,
          clock: () => now,
        ),
      ));

  /// Adelanta el reloj de la pantalla y deja correr su Timer.periodic.
  Future<void> advance(WidgetTester tester, Duration by) async {
    now = now.add(by);
    await tester.pump(by);
  }

  testWidgets('muestra título y cuenta regresiva', (tester) async {
    await pumpScreen(
      tester,
      remaining: const Duration(minutes: 15),
      origin: BlockedOrigin.quickAccess,
    );
    await tester.pump();

    expect(find.text('Tu acceso está bloqueado'), findsOneWidget);
    expect(find.textContaining(':'), findsWidgets); // countdown mm:ss / hh:mm
  });

  // El contador del login es del servidor: el último intento pudo venir tras
  // fallar en otro teléfono, y el bloqueo llega sin el aviso de "1 intento".
  testWidgets('desde el login explica que los fallos pudieron ser en otro '
      'teléfono', (tester) async {
    await pumpScreen(
      tester,
      remaining: const Duration(minutes: 15),
      origin: BlockedOrigin.login,
    );

    expect(find.textContaining('en este u otro teléfono'), findsOneWidget);
  });

  testWidgets('desde el acceso rápido no menciona otros teléfonos',
      (tester) async {
    await pumpScreen(
      tester,
      remaining: const Duration(minutes: 15),
      origin: BlockedOrigin.quickAccess,
    );

    expect(
      find.text(
        'Ingresaste un PIN incorrecto 3 veces. Por tu seguridad, pausamos '
        'el ingreso.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('al llegar a 00:00 avisa con su origen: acceso rápido',
      (tester) async {
    BlockedOrigin? expired;
    await pumpScreen(
      tester,
      remaining: const Duration(seconds: 10),
      origin: BlockedOrigin.quickAccess,
      onExpired: (origin) => expired = origin,
    );

    // No se queda con el contador en cero: avisa para volver.
    await advance(tester, const Duration(seconds: 10));

    expect(expired, BlockedOrigin.quickAccess);
    expect(expired?.entryRoute, '/acceso-rapido');
  });

  testWidgets('al llegar a 00:00 avisa con su origen: iniciar sesión',
      (tester) async {
    BlockedOrigin? expired;
    await pumpScreen(
      tester,
      remaining: const Duration(seconds: 10),
      origin: BlockedOrigin.login,
      onExpired: (origin) => expired = origin,
    );

    await advance(tester, const Duration(seconds: 10));

    expect(expired, BlockedOrigin.login);
    expect(expired?.entryRoute, '/login');
  });

  testWidgets('no avisa mientras el bloqueo sigue vigente', (tester) async {
    var avisos = 0;
    await pumpScreen(
      tester,
      remaining: const Duration(minutes: 15),
      origin: BlockedOrigin.login,
      onExpired: (_) => avisos++,
    );

    await advance(tester, const Duration(seconds: 3));

    expect(avisos, 0);
  });
}
