// APF3 · Usabilidad del paso "Datos" del registro (ISO 25010).
// Spec: docs/apf3/spec-jheampierre-usabilidad-ui.md
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_data_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/register/register_test_support.dart';
import '_harness.dart';

void main() {
  late RegisterBloc bloc;

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    // El bloc se crea dentro del test: su cola de eventos debe vivir en el
    // mismo reloj (FakeAsync) que `pumpAndSettle`, igual que el test modelo.
    bloc = RegisterBloc(
      AuthActions(MemoryAuthRepository()),
      biometric: biometricParaTests(),
      kyc: kycParaTests(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: appDePrueba(
          textScale: textScale,
          home: const Scaffold(body: RegisterDataStep()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UX-REGISTRO · accesibilidad', () {
    testWidgets('UX-REG-01 áreas táctiles de al menos 48 dp', (t) async {
      fijarPantalla(t);
      await pump(t);
      await verificarAccesibilidad(t);
    });
  });

  group('UX-REGISTRO · adaptabilidad', () {
    testWidgets('UX-REG-02 con texto al 200 % no hay desbordes', (t) async {
      fijarPantalla(t);
      await pump(t, textScale: 2);
      verificarSinDesbordes(t);
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('UX-REG-03 en un teléfono de 320×568 no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(t);
      verificarSinDesbordes(t);
    });
  });

  group('UX-REGISTRO · protección contra errores', () {
    testWidgets('UX-REG-04 avanzar con datos inválidos explica qué corregir', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);
      bloc.add(const RegisterEvent.stepAdvanced());
      await t.pumpAndSettle();

      expect(find.textContaining('Revisa'), findsOneWidget);
      expect(find.text('El DNI debe tener 8 dígitos numéricos.'), findsOneWidget);
      verificarSinCodigosTecnicos(
        'Revisa El DNI debe tener 8 dígitos numéricos.',
      );
    });

    testWidgets('UX-REG-05 el botón Continuar está al alcance tras el scroll', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(t);
      await t.scrollUntilVisible(
        find.text('Continuar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Continuar'), findsOneWidget);
      verificarSinDesbordes(t);
    });
  });
}
