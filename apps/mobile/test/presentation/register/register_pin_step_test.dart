import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_pin_confirm_step.dart';
import 'package:cuycash/presentation/register/widgets/register_pin_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_test_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RegisterBloc bloc;

  Future<void> pumpStep(WidgetTester tester, Widget step) async {
    // Tamaño de teléfono real: el paso 4 se dividió justamente porque la
    // checklist, la tarjeta, el teclado y el botón no cabían juntos.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: step),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.text(digit).first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('el PIN se teclea con el teclado propio, no con el del sistema',
      (tester) async {
    await pumpStep(tester, const RegisterPinStep());

    // Aquí NACE el secreto: ningún campo de texto que el teclado del sistema
    // pueda capturar.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(PinKeypad), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las reglas no se dan por cumplidas antes de tiempo',
      (tester) async {
    await pumpStep(tester, const RegisterPinStep());

    // Sin nada escrito no puede haber ninguna regla en verde.
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tapDigits(tester, '024');
    // Con 3 dígitos, "6 dígitos" sigue sin cumplirse.
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(bloc.state.pinHasSixDigits, isFalse);
  });

  testWidgets('un PIN válido marca las dos reglas y pasa a confirmar',
      (tester) async {
    await pumpStep(tester, const RegisterPinStep());

    await tapDigits(tester, '024689');

    expect(bloc.state.draft.pin, '024689');
    expect(bloc.state.securityStep, SecurityStep.confirmar);
  });

  testWidgets('una secuencia no avanza y deja su regla sin marcar',
      (tester) async {
    await pumpStep(tester, const RegisterPinStep());

    await tapDigits(tester, '123456');

    // Seis dígitos y sin repetición sí; secuencia no. La checklist señala
    // exactamente cuál falta y no se avanza.
    expect(bloc.state.pinHasSixDigits, isTrue);
    expect(bloc.state.pinHasNoRepeatedDigit, isTrue);
    expect(bloc.state.pinHasNoSequence, isFalse);
    expect(bloc.state.securityStep, SecurityStep.crear);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.text('Sin secuencias como 123456'), findsOneWidget);
  });

  testWidgets('los seis dígitos iguales tienen SU propia regla', (tester) async {
    await pumpStep(tester, const RegisterPinStep());

    await tapDigits(tester, '111111');

    // Sin una regla propia, el usuario se quedaría atascado sin saber qué
    // corregir: no es una secuencia, así que esa regla no lo explica.
    expect(bloc.state.pinHasNoRepeatedDigit, isFalse);
    expect(bloc.state.pinHasNoSequence, isTrue);
    expect(bloc.state.securityStep, SecurityStep.crear);
    expect(find.text('Sin repetir el mismo dígito seis veces'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });

  testWidgets('un PIN válido marca las TRES reglas', (tester) async {
    await pumpStep(tester, const RegisterPinStep());

    await tapDigits(tester, '02468');
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tapDigits(tester, '9');
    // Con el sexto dígito se cumplen las tres a la vez.
    expect(bloc.state.pinHasSixDigits, isTrue);
    expect(bloc.state.pinHasNoRepeatedDigit, isTrue);
    expect(bloc.state.pinHasNoSequence, isTrue);
  });

  testWidgets('la confirmación distinta avisa y conserva el PIN elegido',
      (tester) async {
    // Se monta el paso 4 completo, que cambia de subpantalla como en el
    // wizard real: crear → confirmar.
    await pumpStep(
      tester,
      BlocBuilder<RegisterBloc, RegisterState>(
        builder: (context, state) => switch (state.securityStep) {
          SecurityStep.crear => const RegisterPinStep(),
          SecurityStep.confirmar => const RegisterPinConfirmStep(),
          SecurityStep.biometria => const SizedBox.shrink(),
        },
      ),
    );

    await tapDigits(tester, '024689');
    expect(find.text('Confírmalo'), findsOneWidget);

    await tapDigits(tester, '111111');

    expect(bloc.state.pinMismatch, isTrue);
    // Se limpia SOLO la confirmación; el PIN elegido se conserva.
    expect(bloc.state.draft.confirmPin, isEmpty);
    expect(bloc.state.draft.pin, '024689');
    expect(find.text('No coincide con el PIN que elegiste.'), findsOneWidget);
  });

  testWidgets('confirmar bien lleva al paso de biometría', (tester) async {
    await pumpStep(
      tester,
      BlocBuilder<RegisterBloc, RegisterState>(
        builder: (context, state) => switch (state.securityStep) {
          SecurityStep.crear => const RegisterPinStep(),
          SecurityStep.confirmar => const RegisterPinConfirmStep(),
          SecurityStep.biometria => const SizedBox.shrink(),
        },
      ),
    );

    await tapDigits(tester, '024689');
    await tapDigits(tester, '024689');

    expect(bloc.state.securityStep, SecurityStep.biometria);
    expect(bloc.state.draft.confirmPin, '024689');
    expect(bloc.state.pinMismatch, isFalse);
  });
}
