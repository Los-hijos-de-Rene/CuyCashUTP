import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/lockout/access_blocked_screen.dart';
import 'package:cuycash/presentation/lockout/blocked_args.dart';
import 'package:cuycash/presentation/otp/flujo_cancelado_screen.dart';
import 'package:cuycash/presentation/support/support_whatsapp_button.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ));
    await tester.pump();
  }

  testWidgets('lleva el icono a la izquierda del texto', (tester) async {
    await pump(tester, const Scaffold(body: SupportWhatsAppButton()));

    expect(find.text('Escribir a soporte por WhatsApp'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });

  testWidgets('la pantalla de bloqueo usa el componente compartido',
      (tester) async {
    await pump(
      tester,
      AccessBlockedScreen(
        lockedUntil: DateTime(2026, 3, 1, 10, 15),
        origin: BlockedOrigin.login,
        clock: () => DateTime(2026, 3, 1, 10),
      ),
    );

    expect(find.byType(SupportWhatsAppButton), findsOneWidget);
  });

  testWidgets('el ingreso cancelado usa el MISMO componente', (tester) async {
    await pump(
      tester,
      const FlujoCanceladoScreen(variante: FlujoCanceladoVariante.ingreso),
    );

    expect(find.byType(SupportWhatsAppButton), findsOneWidget);
  });

  testWidgets('la recuperación cancelada NO ofrece soporte, sino reintentar',
      (tester) async {
    await pump(
      tester,
      const FlujoCanceladoScreen(
          variante: FlujoCanceladoVariante.recuperacion),
    );

    expect(find.byType(SupportWhatsAppButton), findsNothing);
    expect(find.text('Intentar de nuevo'), findsOneWidget);
  });
}
