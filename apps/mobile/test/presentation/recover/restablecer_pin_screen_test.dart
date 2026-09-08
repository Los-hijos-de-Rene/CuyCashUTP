import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/recover/bloc/reset_pin_bloc.dart';
import 'package:cuycash/presentation/recover/restablecer_pin_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const currentPin = '482913';

  late MemoryAuthRepository repo;
  late ResetPinBloc bloc;

  Future<void> pumpScreen(WidgetTester tester) async {
    // Pantalla de teléfono real: el rediseño existe justamente porque en 390x844
    // no cabían dos filas de casillas más teclado más botón.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    repo = MemoryAuthRepository(validPin: currentPin);
    bloc = ResetPinBloc(
        actions: AuthActions(repo), identifier: 'juan.perez@gmail.com');
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RestablecerPinScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.text(digit).first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('el paso 1 cabe: sin botón y con el teclado completo',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Crea tu nuevo PIN'), findsOneWidget);
    expect(find.text('6 dígitos, distinto al que usabas antes.'),
        findsOneWidget);
    // Sin botón primario: el sexto dígito es el commit.
    expect(find.byType(PrimaryButton), findsNothing);
    // El teclado entero es visible, el 0 incluido.
    expect(find.byType(PinKeypad), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    // Una sola fila de seis casillas.
    expect(find.byType(PinBoxes), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el sexto dígito avanza solo al paso de confirmación',
      (tester) async {
    await pumpScreen(tester);

    await tapDigits(tester, '314159');

    expect(find.text('Confirma tu PIN'), findsOneWidget);
    expect(find.text('Vuelve a escribir los 6 dígitos.'), findsOneWidget);
    expect(bloc.state.pin, isEmpty);
  });

  testWidgets('el PIN actual se rechaza sin salir del paso 1', (tester) async {
    await pumpScreen(tester);

    await tapDigits(tester, currentPin);

    expect(find.text('Ese es tu PIN actual. Elige uno distinto.'),
        findsOneWidget);
    expect(find.text('Crea tu nuevo PIN'), findsOneWidget);
  });

  testWidgets('la confirmación distinta avisa sin perder el PIN elegido',
      (tester) async {
    await pumpScreen(tester);

    await tapDigits(tester, '314159');
    await tapDigits(tester, '222222');

    expect(find.text('No coincide con el PIN que elegiste.'), findsOneWidget);
    expect(find.text('Confirma tu PIN'), findsOneWidget);
    expect(bloc.state.chosenPin, '314159');
  });

  testWidgets('el paso 2 muestra flecha, no X, y retrocede en vez de salir',
      (tester) async {
    await pumpScreen(tester);
    await tapDigits(tester, '314159');

    // El ícono cambia con el paso: ahí ya no se abandona el flujo.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Vuelve al paso 1 con las casillas vacías, sin diálogo de salida.
    expect(find.text('Crea tu nuevo PIN'), findsOneWidget);
    expect(find.text('¿Salir sin cambiar tu PIN?'), findsNothing);
    expect(bloc.state.pin, isEmpty);
    // De vuelta en el paso 1, la barra vuelve a ofrecer la salida.
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('el paso 1 muestra X y pide confirmación antes de abandonar',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('¿Salir sin cambiar tu PIN?'), findsOneWidget);
  });
}
