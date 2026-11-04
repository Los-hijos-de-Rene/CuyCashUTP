// HU03 CA4 · Cierre de sesión por inactividad.
// Prueba de widget del vigilante: positiva (se agota) y negativas (hay uso,
// está deshabilitado, vuelve antes de tiempo).
import 'package:cuycash/presentation/session/inactivity_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required VoidCallback onTimeout, bool enabled = true}) =>
    InactivityWatcher(
      timeout: const Duration(minutes: 5),
      enabled: enabled,
      onTimeout: onTimeout,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(onPressed: () {}, child: const Text('tocar')),
          ),
        ),
      ),
    );

void main() {
  testWidgets('sin uso, avisa al agotarse el tiempo y una sola vez', (
    t,
  ) async {
    var avisos = 0;
    await t.pumpWidget(_app(onTimeout: () => avisos++));

    await t.pump(const Duration(minutes: 4, seconds: 59));
    expect(avisos, 0, reason: 'Todavía no se cumplió el plazo.');

    await t.pump(const Duration(seconds: 2));
    expect(avisos, 1);

    // No vuelve a avisar hasta que haya una interacción que reinicie la cuenta.
    await t.pump(const Duration(minutes: 10));
    expect(avisos, 1);
  });

  testWidgets('un toque reinicia el temporizador', (t) async {
    var avisos = 0;
    await t.pumpWidget(_app(onTimeout: () => avisos++));

    await t.pump(const Duration(minutes: 4));
    await t.tap(find.text('tocar'));
    await t.pump();

    // 4 minutos desde el toque: aún no.
    await t.pump(const Duration(minutes: 4));
    expect(avisos, 0);

    await t.pump(const Duration(minutes: 1, seconds: 1));
    expect(avisos, 1);
  });

  testWidgets('deshabilitado no avisa aunque pase el tiempo', (t) async {
    var avisos = 0;
    await t.pumpWidget(_app(onTimeout: () => avisos++, enabled: false));

    await t.pump(const Duration(minutes: 30));
    expect(avisos, 0);
  });

  testWidgets('al volver del segundo plano tras el plazo, avisa', (t) async {
    var avisos = 0;
    var ahora = DateTime(2026, 11, 4, 12);
    await t.pumpWidget(
      InactivityWatcher(
        timeout: const Duration(minutes: 5),
        clock: () => ahora,
        onTimeout: () => avisos++,
        child: const MaterialApp(home: Scaffold(body: Text('app'))),
      ),
    );

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    ahora = ahora.add(const Duration(minutes: 6));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();

    expect(avisos, 1);
  });

  testWidgets('al volver del segundo plano antes del plazo, no avisa', (
    t,
  ) async {
    var avisos = 0;
    var ahora = DateTime(2026, 11, 4, 12);
    await t.pumpWidget(
      InactivityWatcher(
        timeout: const Duration(minutes: 5),
        clock: () => ahora,
        onTimeout: () => avisos++,
        child: const MaterialApp(home: Scaffold(body: Text('app'))),
      ),
    );

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    ahora = ahora.add(const Duration(minutes: 2));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();

    expect(avisos, 0);
  });
}
