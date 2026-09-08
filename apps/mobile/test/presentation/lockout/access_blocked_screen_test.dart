import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/quick_access/access_blocked_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra título y cuenta regresiva', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccessBlockedScreen(
        lockedUntil: DateTime.now().add(const Duration(minutes: 15)),
      ),
    ));
    await tester.pump();
    expect(find.text('Tu acceso está bloqueado'), findsOneWidget);
    expect(find.textContaining(':'), findsWidgets); // countdown mm:ss / hh:mm
  });
}
