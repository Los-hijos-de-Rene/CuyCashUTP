import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/presentation/quick_access/bloc/quick_access_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = RememberedUser(dni: '12345678', fullName: 'Juan Pérez', alias: '@juan');
  DateTime clock() => DateTime(2026, 1, 1, 10);

  QuickAccessBloc build({MemoryAuthRepository? auth, MemoryDeviceStore? device}) =>
      QuickAccessBloc(
        auth: AuthActions(auth ?? MemoryAuthRepository()),
        device: DeviceActions(device ?? MemoryDeviceStore()),
        user: user,
        clock: clock,
      );

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
    build: () {
      final device = MemoryDeviceStore();
      return QuickAccessBloc(
        auth: AuthActions(MemoryAuthRepository()),
        device: DeviceActions(device),
        user: user,
        clock: clock,
      );
    },
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
    build: () {
      final device = MemoryDeviceStore();
      return QuickAccessBloc(
        auth: AuthActions(MemoryAuthRepository()),
        device: DeviceActions(device),
        user: user,
        clock: clock,
      );
    },
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

  late MemoryAuthRepository biometricRepo;
  blocTest<QuickAccessBloc, QuickAccessState>(
    'biométrico autentica (activa sesión del recordado)',
    build: () {
      biometricRepo = MemoryAuthRepository();
      return QuickAccessBloc(
        auth: AuthActions(biometricRepo),
        device: DeviceActions(MemoryDeviceStore()),
        user: user,
        clock: clock,
      );
    },
    act: (b) => b.add(const QuickAccessEvent.biometric()),
    wait: const Duration(milliseconds: 10),
    verify: (_) => expect(biometricRepo.currentSession?.identifier, user.dni),
  );
}
