import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/feature/security/application/security_actions.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/change_pin/bloc/change_pin_bloc.dart';
import 'package:cuycash/presentation/profile/change_pin/change_pin_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime? bloqueo;

  Future<void> abrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bloqueo = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => ChangePinBloc(
            SecurityActions(
              MemorySecurityRepository(
                MemorySecurityState.demo(clock: DateTime.now),
                clock: DateTime.now,
              ),
            ),
          ),
          child: ChangePinScreen(onLocked: (until) => bloqueo = until),
        ),
      ),
    );
  }

  Future<void> teclear(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('recorre los tres pasos y muestra la constancia', (tester) async {
    await abrir(tester);
    expect(find.text('Ingresa tu PIN actual'), findsOneWidget);

    await teclear(tester, '000000');
    expect(find.text('Crea tu nuevo PIN'), findsOneWidget);
    expect(find.text('Sin secuencias como 123456'), findsOneWidget);

    await teclear(tester, '502718');
    expect(find.text('Confirma tu nuevo PIN'), findsOneWidget);

    await teclear(tester, '502718');
    expect(find.text('Tu PIN cambió'), findsOneWidget);
    expect(find.text('Cerramos tu sesión en 1 dispositivo.'), findsOneWidget);
  });

  testWidgets('la flecha retrocede un paso', (tester) async {
    await abrir(tester);
    await teclear(tester, '000000');
    await teclear(tester, '502718');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu nuevo PIN'), findsOneWidget);
  });

  testWidgets('PIN actual errado avisa los intentos', (tester) async {
    await abrir(tester);
    await teclear(tester, '111222');
    await teclear(tester, '502718');
    await teclear(tester, '502718');

    expect(find.text('Ingresa tu PIN actual'), findsOneWidget);
    expect(
      find.text(
        'PIN actual incorrecto. Te quedan ${LockoutPolicy.maxAttempts - 1} intentos.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('al bloquear avisa a quien abrió la pantalla', (tester) async {
    await abrir(tester);
    for (var i = 0; i < LockoutPolicy.maxAttempts; i++) {
      await teclear(tester, '111222');
      await teclear(tester, '502718');
      await teclear(tester, '502718');
    }
    expect(bloqueo, isNotNull);
  });
}
