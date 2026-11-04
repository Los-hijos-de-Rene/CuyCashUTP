import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/qr/bloc/qr_charge_bloc.dart';
import 'package:cuycash/presentation/qr/qr_charge_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'qr_test_support.dart';

const _cuenta = Account(
  id: 'acc-demo-1',
  numero: '19100000004521',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(125040),
  saldoContable: Money.soles(125040),
);

void main() {
  Future<void> pump(WidgetTester tester) async {
    // El bloc se crea dentro del test para que su cola viva en FakeAsync.
    final bloc = QrChargeBloc(QrActions(FakeQrRepository()));
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const QrChargeScreen(cuenta: _cuenta),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin monto no genera y explica qué falta', (t) async {
    await pump(t);
    await t.tap(find.text('Generar QR'));
    await t.pumpAndSettle();

    expect(find.text('Escribe un monto mayor a cero.'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('con monto y concepto muestra el QR y el monto', (t) async {
    await pump(t);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '10');
    await t.enterText(fields.at(1), 'Almuerzo');
    await t.tap(find.text('Generar QR'));
    await t.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('S/ 10.00'), findsOneWidget);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Tu QR está listo'), findsOneWidget);
  });
}
