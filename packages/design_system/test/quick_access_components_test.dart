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
    await tester.pumpWidget(_wrap(PinKeypad(
      onDigit: digits.add,
      onBackspace: () => back++,
      onBiometric: () {},
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(digits, [5]);
  });

  testWidgets('InitialsAvatar muestra iniciales', (tester) async {
    await tester.pumpWidget(_wrap(const InitialsAvatar(initials: 'JP')));
    expect(find.text('JP'), findsOneWidget);
  });
}
