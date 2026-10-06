import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/biometric/domain/biometric_gate.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/feature/security/application/biometric_sign_in_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/presentation/quick_access/bloc/quick_access_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = RememberedUser(
    dni: '12345678',
    fullName: 'Juan Pérez',
    alias: '@juan',
  );
  DateTime clock() => DateTime(2026, 1, 1, 10);

  BiometricSignInUseCase biometricFor(
    MemoryAuthRepository auth,
    MemoryDeviceStore store, [
    MemoryBiometricGate? gate,
  ]) => BiometricSignInUseCase(
    auth: auth,
    gate: gate ?? MemoryBiometricGate(),
    store: store,
  );

  QuickAccessBloc build({
    MemoryAuthRepository? auth,
    MemoryDeviceStore? device,
  }) {
    final repo = auth ?? MemoryAuthRepository();
    final store = device ?? MemoryDeviceStore();
    return QuickAccessBloc(
      auth: AuthActions(repo),
      device: DeviceActions(store),
      biometric: biometricFor(repo, store),
      user: user,
      clock: clock,
    );
  }

  blocTest<QuickAccessBloc, QuickAccessState>(
    'dígitos acumulan el pin',
    build: build,
    act: (b) => b
      ..add(const QuickAccessEvent.digitPressed(1))
      ..add(const QuickAccessEvent.digitPressed(2)),
    verify: (b) => expect(b.state.pin, '12'),
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'backspace borra el último dígito',
    build: build,
    act: (b) => b
      ..add(const QuickAccessEvent.digitPressed(1))
      ..add(const QuickAccessEvent.backspace()),
    verify: (b) => expect(b.state.pin, ''),
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'PIN correcto (000000) autentica y limpia lockout',
    build: build,
    act: (b) {
      for (final d in [0, 0, 0, 0, 0, 0]) {
        b.add(QuickAccessEvent.digitPressed(d));
      }
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) => expect(b.state.lockedUntil, isNull),
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'PIN incorrecto baja attemptsLeft y limpia el pin',
    build: build,
    act: (b) {
      for (final d in [9, 9, 9, 9, 9, 9]) {
        b.add(QuickAccessEvent.digitPressed(d));
      }
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.pin, '');
      expect(b.state.lastWrong, isTrue);
      expect(b.state.attemptsLeft, 2);
    },
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'tercer PIN incorrecto fija lockedUntil',
    build: build,
    act: (b) async {
      for (var attempt = 0; attempt < 3; attempt++) {
        for (final d in [9, 9, 9, 9, 9, 9]) {
          b.add(QuickAccessEvent.digitPressed(d));
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) => expect(b.state.lockedUntil, isNotNull),
  );

  test('PIN correcto en un teléfono desvinculado: pide verificarlo y NO cuenta '
      'como intento fallido', () async {
    final store = MemoryDeviceStore();
    final b = build(
      auth: MemoryAuthRepository(deviceTrusted: false),
      device: store,
    );
    addTearDown(b.close);

    for (final d in [0, 0, 0, 0, 0, 0]) {
      b.add(QuickAccessEvent.digitPressed(d));
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(b.state.needsDeviceVerification, isTrue);
    expect(b.state.status, QuickAccessStatus.idle);
    expect(b.state.pin, '');
    expect(b.state.lastWrong, isFalse);
    expect(b.state.attemptsLeft, LockoutPolicy.maxAttempts);
    expect(b.state.lockedUntil, isNull);
    expect((await store.readLockout()).failedAttempts, 0);
  });

  group('huella', () {
    late MemorySecurityState estado;
    late MemoryAuthRepository auth;
    late MemoryDeviceStore store;
    late MemoryBiometricGate gate;
    late RememberedUser recordado;

    setUp(() {
      estado = MemorySecurityState.demo(clock: clock);
      auth = MemoryAuthRepository(security: estado);
      store = MemoryDeviceStore();
      gate = MemoryBiometricGate();
      recordado = RememberedUser(
        dni: estado.dni,
        fullName: 'Juan Pérez',
        alias: '@juan',
      );
    });

    Future<QuickAccessBloc> armar({bool guardada = true}) async {
      if (guardada) {
        estado.credentials['ok'] = estado.thisDeviceId;
        await store.saveBiometricCredential('ok');
      }
      final b = QuickAccessBloc(
        auth: AuthActions(auth),
        device: DeviceActions(store),
        biometric: biometricFor(auth, store, gate),
        user: recordado,
        clock: clock,
      )..add(const QuickAccessEvent.started());
      addTearDown(b.close);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return b;
    }

    Future<void> pulsar(QuickAccessBloc b) async {
      b.add(const QuickAccessEvent.biometric(reason: 'r'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    test('started: disponible con credencial y sensor', () async {
      final b = await armar();
      expect(b.state.biometricAvailable, isTrue);
    });

    test('started: no disponible sin credencial', () async {
      final b = await armar(guardada: false);
      expect(b.state.biometricAvailable, isFalse);
    });

    test('éxito: abre sesión real del servidor', () async {
      final b = await armar();
      await pulsar(b);
      expect(auth.currentSession?.identifier, estado.dni);
      expect(b.state.status, QuickAccessStatus.idle);
    });

    test('ignorada si no está disponible', () async {
      final b = await armar(guardada: false);
      await pulsar(b);
      expect(gate.prompts, 0);
      expect(auth.currentSession, isNull);
    });

    test('cancelada: sin cambios y sin sesión', () async {
      gate.outcome = BiometricOutcome.cancelled;
      final b = await armar();
      await pulsar(b);
      expect(auth.currentSession, isNull);
      expect(b.state.biometricAvailable, isTrue);
      expect(b.state.status, QuickAccessStatus.idle);
    });

    test('sensor no disponible al pulsar: oculta la huella', () async {
      final b = await armar();
      gate.available = false;
      await pulsar(b);
      expect(b.state.biometricAvailable, isFalse);
      expect(b.state.biometricRevoked, isFalse);
    });

    test('huella leída pero sin sesión: avisa en vez de callarse', () async {
      gate.outcome = BiometricOutcome.failed;
      final b = await armar();
      await pulsar(b);
      expect(b.state.biometricFailed, isTrue);
      expect(b.state.biometricAvailable, isTrue);
      expect(b.state.status, QuickAccessStatus.idle);
      expect(auth.currentSession, isNull);

      // Un nuevo intento borra el aviso anterior.
      gate.outcome = BiometricOutcome.success;
      await pulsar(b);
      expect(b.state.biometricFailed, isFalse);
    });

    test('revocada: oculta la huella y marca el aviso', () async {
      final b = await armar();
      estado.credentials.clear();
      await pulsar(b);
      expect(b.state.biometricAvailable, isFalse);
      expect(b.state.biometricRevoked, isTrue);
      expect(b.state.status, QuickAccessStatus.idle);
      expect(auth.currentSession, isNull);
    });
  });
}
