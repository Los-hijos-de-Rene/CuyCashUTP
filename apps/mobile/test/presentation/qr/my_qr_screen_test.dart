import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/qr/bloc/my_qr_bloc.dart';
import 'package:cuycash/presentation/qr/my_qr_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'my_qr_bloc_test.dart' show cuentaDePrueba;
import 'qr_test_support.dart';

void main() {
  Future<FakeQrRepository> pump(WidgetTester tester) async {
    final repo = FakeQrRepository();
    final bloc = MyQrBloc(actions: QrActions(repo), cuenta: cuentaDePrueba)
      ..add(const MyQrRequested());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MyQrScreen(cuenta: cuentaDePrueba),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('muestra el QR en una tarjeta para compartir, sin el token', (
    t,
  ) async {
    await pump(t);
    expect(find.text('Cobra con tu QR'), findsOneWidget);
    expect(find.text('Escanea y elige cuánto pagar'), findsOneWidget);
    expect(find.text('Cuenta ••••8830 · S/'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Compartir mi QR'), 200);
    expect(find.text('Compartir mi QR'), findsOneWidget);
    final qr = t.widget<QrImageView>(find.byType(QrImageView));
    expect(
      find.ancestor(
        of: find.byWidget(qr),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
    expect(find.textContaining(staticDePrueba.payload), findsNothing);
  });

  testWidgets('cambiar el QR pide confirmación y avisa al terminar', (t) async {
    final repo = await pump(t);
    await t.scrollUntilVisible(find.text('Cambiar mi QR'), 200);
    await t.tap(find.text('Cambiar mi QR'));
    await t.pumpAndSettle();
    expect(find.text('¿Cambiar tu QR?'), findsOneWidget);

    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(repo.regeneraciones, 0);

    await t.scrollUntilVisible(find.text('Cambiar mi QR'), 200);
    await t.tap(find.text('Cambiar mi QR'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cambiar QR'));
    await t.pumpAndSettle();
    expect(repo.regeneraciones, 1);
    expect(find.textContaining('tu QR nuevo ya está activo'), findsOneWidget);
  });
}
