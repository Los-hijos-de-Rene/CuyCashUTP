import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: CuyCashTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('PinDots rellena los primeros N', (tester) async {
    await tester.pumpWidget(_wrap(const PinDots(filled: 2)));
    expect(find.byType(Container), findsNWidgets(6));
  });

  testWidgets('PinKeypad dispara dígito y backspace', (tester) async {
    final digits = <int>[];
    var back = 0;
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(PinKeypad(
      onDigit: digits.add,
      onBackspace: () => back++,
      onBiometric: () {},
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(digits, [5]);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pumpAndSettle();
    expect(digits, [5]);
    expect(back, 1);
  });

  testWidgets('InitialsAvatar muestra iniciales', (tester) async {
    await tester.pumpWidget(_wrap(const InitialsAvatar(initials: 'JP')));
    expect(find.text('JP'), findsOneWidget);
  });

  testWidgets('PinKeypad no muestra letras bajo los dígitos', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      home: Scaffold(
        body: PinKeypad(onDigit: (_) {}, onBackspace: () {}),
      ),
    ));

    // Solo dígitos: las letras del marcado telefónico no aportan a un PIN.
    for (final letras in ['ABC', 'DEF', 'GHI', 'JKL', 'MNO', 'PQRS', 'TUV',
        'WXYZ']) {
      expect(find.text(letras), findsNothing);
    }
    for (var digito = 0; digito <= 9; digito++) {
      expect(find.text('$digito'), findsOneWidget);
    }
  });

  testWidgets('PinKeypad mantiene el orden fijo de las teclas', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      home: Scaffold(
        body: PinKeypad(onDigit: (_) {}, onBackspace: () {}),
      ),
    ));

    // El orden no se baraja: la memoria muscular es lo que hace rápida la
    // operación más repetida de la app.
    double y(String digito) => tester.getCenter(find.text(digito)).dy;
    double x(String digito) => tester.getCenter(find.text(digito)).dx;
    expect(y('1'), lessThan(y('4')));
    expect(y('4'), lessThan(y('7')));
    expect(y('7'), lessThan(y('0')));
    expect(x('1'), lessThan(x('2')));
    expect(x('2'), lessThan(x('3')));
  });
}
