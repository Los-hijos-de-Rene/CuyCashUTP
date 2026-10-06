import 'package:cuycash/feature/biometric/domain/biometric_gate.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/disable_biometric_use_case.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/biometric/bloc/biometric_settings_bloc.dart';
import 'package:cuycash/presentation/profile/biometric/biometric_settings_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryBiometricGate gate;
  late MemoryDeviceStore store;
  late MemorySecurityState estado;

  Future<void> abrir(WidgetTester tester, {bool available = true}) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    gate = MemoryBiometricGate(available: available);
    store = MemoryDeviceStore();
    estado = MemorySecurityState.demo(clock: DateTime.now);
    final repo = MemorySecurityRepository(estado, clock: DateTime.now);
    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => BiometricSettingsBloc(
            enable: EnableBiometricUseCase(
              repo: repo,
              gate: gate,
              store: store,
            ),
            disable: DisableBiometricUseCase(repo: repo, store: store),
            device: DeviceActions(store),
          )..add(const BiometricSettingsEvent.started()),
          child: BiometricSettingsScreen(onLocked: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> teclear(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('encender pide PIN, luego la huella, y queda activo', (
    tester,
  ) async {
    await abrir(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Confirma con tu PIN'), findsOneWidget);

    await teclear(tester, '000000');

    expect(gate.prompts, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(await store.readBiometricCredential(), isNotNull);
  });

  testWidgets('cancelar la huella deja el interruptor apagado sin error', (
    tester,
  ) async {
    await abrir(tester);
    gate.outcome = BiometricOutcome.cancelled;

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await teclear(tester, '000000');

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(estado.credentials, isEmpty);
  });

  testWidgets('sin sensor lo explica y no deja encender', (tester) async {
    await abrir(tester, available: false);

    expect(find.textContaining('no tiene huella ni rostro'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('apagar borra la credencial', (tester) async {
    await abrir(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await teclear(tester, '000000');

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(await store.readBiometricCredential(), isNull);
    expect(estado.credentials, isEmpty);
  });
}
