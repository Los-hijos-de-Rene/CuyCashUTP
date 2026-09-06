import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: CuyCashTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('PrimaryButton muestra label y dispara onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PrimaryButton(label: 'Ingresar', onPressed: () => tapped = true),
    ));
    expect(find.text('Ingresar'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton loading oculta el label y deshabilita', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PrimaryButton(label: 'Ingresar', loading: true, onPressed: () => tapped = true),
    ));
    expect(find.text('Ingresar'), findsNothing);
    await tester.tap(find.byType(PrimaryButton));
    expect(tapped, isFalse);
  });

  testWidgets('CuyCashTextField muestra label y errorText', (tester) async {
    await tester.pumpWidget(_wrap(
      const CuyCashTextField(label: 'DNI o Alias', errorText: 'Requerido'),
    ));
    expect(find.text('DNI o Alias'), findsOneWidget);
    expect(find.text('Requerido'), findsOneWidget);
  });

  testWidgets('PageDotsIndicator renderiza count dots', (tester) async {
    await tester.pumpWidget(_wrap(
      const PageDotsIndicator(count: 3, activeIndex: 1),
    ));
    expect(find.byType(AnimatedContainer), findsNWidgets(3));
  });
}
