import 'register_test_support.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/register_flow_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Ir a mi cuenta" con la huella encendida y su activación fallida: el aviso
/// "actívala después" tiene que verse, y la sesión (que saca al usuario del
/// registro) solo se abre cuando la pantalla ya lo mostró.
void main() {
  testWidgets('si la huella falla, muestra el aviso y luego abre la sesión', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final estado = MemorySecurityState.demo(clock: DateTime.now, pin: '839201');
    final store = MemoryDeviceStore()..failCredentialWrites = true;
    final auth = MemoryAuthRepository(security: estado);
    final bloc = RegisterBloc(
      AuthActions(auth),
      biometric: EnableBiometricUseCase(
        repo: MemorySecurityRepository(estado, clock: DateTime.now),
        gate: MemoryBiometricGate(),
        store: store,
      ),
      kyc: kycParaTests(),
    );
    addTearDown(bloc.close);

    // Alta hecha, cuenta aún sin abrir: la pantalla de éxito.
    bloc
      ..add(const RegisterEvent.biometricChecked())
      ..add(const RegisterEvent.fieldChanged(RegisterField.dni, '87654321'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.nombres, 'Juan'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.apellidos, 'Pérez'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.email, 'j@p.pe'));
    for (final d in '839201'.split('')) {
      bloc.add(RegisterEvent.pinDigitPressed(int.parse(d)));
    }
    bloc.add(const RegisterEvent.submitted());
    await tester.pump(const Duration(milliseconds: 10));
    expect(bloc.state.createdSession, isNotNull);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RegisterFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ir a mi cuenta'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No pudimos activar tu huella. Puedes hacerlo desde tu perfil, en '
        'Acceso biométrico.',
      ),
      findsOneWidget,
    );
    // La pantalla, tras mostrar el aviso, pidió abrir la cuenta.
    expect(auth.currentSession?.identifier, '87654321');
  });
}
