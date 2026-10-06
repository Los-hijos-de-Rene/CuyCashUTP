import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/biometric_sign_in_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/quick_access/bloc/quick_access_bloc.dart';
import 'package:cuycash/presentation/quick_access/quick_access_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecurityState estado;
  late MemoryAuthRepository auth;
  late MemoryDeviceStore store;
  late MemoryBiometricGate gate;
  late RememberedUser user;

  setUp(() {
    estado = MemorySecurityState.demo(clock: () => DateTime(2026));
    auth = MemoryAuthRepository(security: estado);
    store = MemoryDeviceStore();
    gate = MemoryBiometricGate();
    // El DNI del recordado debe ser el del estado para la huella.
    user = RememberedUser(
      dni: estado.dni,
      fullName: 'Juan Pérez',
      alias: '@juan',
    );
  });

  Future<QuickAccessBloc> pumpQuickAccess(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = QuickAccessBloc(
      auth: AuthActions(auth),
      device: DeviceActions(store),
      biometric: BiometricSignInUseCase(auth: auth, gate: gate, store: store),
      user: user,
      clock: () => DateTime(2026),
    )..add(const QuickAccessEvent.started());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const QuickAccessScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('saluda y el keypad llena los dots', (tester) async {
    final bloc = await pumpQuickAccess(tester);
    expect(find.text('Hola, Juan'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(bloc.state.pin, '1');
  });

  testWidgets('sin credencial guardada no hay botón de huella', (tester) async {
    await pumpQuickAccess(tester);
    expect(find.byIcon(Icons.fingerprint), findsNothing);
    expect(find.text('0'), findsOneWidget); // el teclado sigue ahí
  });

  testWidgets('con credencial y sensor, la huella abre sesión', (tester) async {
    estado.credentials['ok'] = estado.thisDeviceId;
    await store.saveBiometricCredential('ok');
    await pumpQuickAccess(tester);

    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();

    expect(auth.currentSession?.identifier, estado.dni);
  });

  testWidgets('con credencial pero sin huellas en el sistema, sin botón', (
    tester,
  ) async {
    estado.credentials['ok'] = estado.thisDeviceId;
    await store.saveBiometricCredential('ok');
    gate.available = false;
    await pumpQuickAccess(tester);

    expect(find.byIcon(Icons.fingerprint), findsNothing);
  });

  testWidgets('credencial revocada: la borra, oculta el botón y avisa', (
    tester,
  ) async {
    await store.saveBiometricCredential('vieja');
    await pumpQuickAccess(tester);

    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();

    // El teclado ya no ofrece la huella: queda solo el ícono del aviso.
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(
      find.textContaining('Tu acceso con huella ya no es válido'),
      findsOneWidget,
    );
    expect(await store.readBiometricCredential(), isNull);
    expect(find.text('0'), findsOneWidget);
  });
}
