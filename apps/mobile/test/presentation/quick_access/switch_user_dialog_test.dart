import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/quick_access/widgets/switch_user_dialog.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el copy corregido (DNI y PIN) y confirma con true',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async =>
                  result = await showSwitchUserDialog(context, name: 'Juan'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('su DNI y su PIN de seguridad'), findsOneWidget);
    expect(find.textContaining('correo y contraseña'), findsNothing);
    await tester.tap(find.text('Salir de esta cuenta'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
