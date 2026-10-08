import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_data_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_test_support.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(RegisterBloc bloc) => BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RegisterDataStep()),
      ),
    );

void main() {
  testWidgets('muestra el encabezado y los 4 campos', (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text('Empecemos por ti'), findsOneWidget);
    expect(find.byType(CuyCashTextField), findsNWidgets(4));
  });

  testWidgets('avanzar con datos inválidos muestra el banner y errores',
      (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    bloc.add(const RegisterEvent.stepAdvanced());
    await tester.pumpAndSettle();
    expect(find.textContaining('Revisa'), findsOneWidget);
    expect(find.text('El DNI debe tener 8 dígitos numéricos.'), findsOneWidget);
  });

  testWidgets('siguiente del teclado pasa al campo siguiente', (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    final fields = find.byType(TextField);
    await tester.tap(fields.at(1));
    await tester.enterText(fields.at(1), 'Ana');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(2)).focusNode!.hasFocus, isTrue);
  });

  testWidgets('el DNI completo salta a Nombres', (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    final fields = find.byType(TextField);
    await tester.tap(fields.at(0));
    await tester.enterText(fields.at(0), '70123456');
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(1)).focusNode!.hasFocus, isTrue);
  });

  testWidgets('listo en Email con datos inválidos muestra los errores',
      (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    final fields = find.byType(TextField);
    await tester.tap(fields.at(3));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('Revisa'), findsOneWidget);
  });

  testWidgets('el botón Continuar está al final del formulario',
      (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    await tester.scrollUntilVisible(find.byType(PrimaryButton), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
      find.descendant(
          of: find.byType(ListView), matching: find.byType(PrimaryButton)),
      findsOneWidget,
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('Revisa'), findsOneWidget);
  });
}
