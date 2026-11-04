import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/qr/bloc/qr_pay_bloc.dart';
import 'package:cuycash/presentation/qr/qr_pay_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qr_test_support.dart';

const _cuenta = Account(
  id: 'acc-demo-2',
  numero: '19100000008830',
  tipo: AccountType.sueldo,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(350000),
  saldoContable: Money.soles(350000),
);

void main() {
  Future<void> pump(WidgetTester tester) async {
    final bloc = QrPayBloc(
      actions: QrActions(FakeQrRepository()),
      cuentaOrigen: _cuenta,
      userId: 'u1',
      clock: () => DateTime.utc(2026, 11, 4, 12),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QrPayScreen(
            cuentaOrigen: _cuenta,
            cameraBuilder: (onDetected) => TextButton(
              onPressed: () => onDetected('cuycash://qr?demo=1'),
              child: const Text('SIMULAR ESCANEO'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el escaneo muestra nombre y monto antes de confirmar', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('SIMULAR ESCANEO'));
    await t.pumpAndSettle();

    expect(find.text('Revisa antes de pagar'), findsOneWidget);
    expect(find.text('J*** M*** R***'), findsOneWidget);
    expect(find.text('S/ 10.00'), findsOneWidget);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Pagar'), findsOneWidget);
  });

  testWidgets('pagar pide PIN y termina en la constancia', (t) async {
    await pump(t);
    await t.tap(find.text('SIMULAR ESCANEO'));
    await t.pumpAndSettle();
    await t.tap(find.text('Pagar'));
    await t.pumpAndSettle();

    expect(find.text('Confirma con tu PIN'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await t.tap(find.text('0'));
      await t.pump();
    }
    await t.pumpAndSettle();

    expect(find.text('¡Pago realizado!'), findsOneWidget);
    expect(find.textContaining('tx-qr-1'), findsOneWidget);
  });
}
