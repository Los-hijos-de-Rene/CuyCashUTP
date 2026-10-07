import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/home/widgets/accounts_header.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('muestra "Mis cuentas" y un botón para abrir otra', (t) async {
    var abrio = false;
    await t.pumpWidget(_app(AccountsHeader(cuentas: 2, onOpenAccount: () => abrio = true)));

    expect(find.text('Mis cuentas'), findsOneWidget);
    await t.tap(find.widgetWithText(GhostButton, 'Abrir cuenta'));
    expect(abrio, isTrue);
  });

  testWidgets('en el tope (sin onOpenAccount) no hay botón', (t) async {
    await t.pumpWidget(_app(const AccountsHeader(cuentas: 5, onOpenAccount: null)));

    expect(find.text('Mis cuentas'), findsOneWidget);
    expect(find.text('Abrir cuenta'), findsNothing);
  });

  testWidgets('con una sola cuenta dice "Mi cuenta", en singular', (t) async {
    await t.pumpWidget(_app(AccountsHeader(cuentas: 1, onOpenAccount: () {})));

    expect(find.text('Mi cuenta'), findsOneWidget);
    expect(find.text('Mis cuentas'), findsNothing);
  });
}
