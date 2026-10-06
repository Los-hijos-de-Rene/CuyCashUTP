import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/biometric/domain/biometric_gate.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/biometric_sign_in_use_case.dart';
import 'package:cuycash/feature/security/application/disable_biometric_use_case.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemorySecurityState estado;
  late MemoryDeviceStore store;
  late MemoryBiometricGate gate;
  late EnableBiometricUseCase activar;
  late BiometricSignInUseCase entrar;

  setUp(() {
    estado = MemorySecurityState.demo(clock: DateTime.now);
    store = MemoryDeviceStore();
    gate = MemoryBiometricGate();
    final repo = MemorySecurityRepository(estado, clock: DateTime.now);
    activar = EnableBiometricUseCase(repo: repo, gate: gate, store: store);
    entrar = BiometricSignInUseCase(
      auth: MemoryAuthRepository(security: estado),
      gate: gate,
      store: store,
    );
  });

  test('activar: huella, servidor y secreto guardado', () async {
    final r = await activar(pin: '000000', reason: 'r');

    expect(r.getRight().toNullable(), isTrue);
    expect(await store.readBiometricCredential(), isNotNull);
    expect(estado.credentials.values, [estado.thisDeviceId]);
    expect(await entrar.canUse(), isTrue);
  });

  test('cancelar el diálogo no llama al servidor', () async {
    gate.outcome = BiometricOutcome.cancelled;

    final r = await activar(pin: '000000', reason: 'r');

    expect(r.getRight().toNullable(), isFalse);
    expect(estado.credentials, isEmpty);
  });

  test('sin sensor es biometricUnavailable', () async {
    gate.available = false;

    final r = await activar(pin: '000000', reason: 'r');

    expect(switch (r.getLeft().toNullable()) {
      ServerFailure(:final failure) => failure,
      _ => null,
    }, isA<SecurityBiometricUnavailable>());
  });

  test('si no se puede guardar el secreto, se revoca en el servidor', () async {
    store.failCredentialWrites = true;

    final r = await activar(pin: '000000', reason: 'r');

    expect(r.isLeft(), isTrue);
    expect(estado.credentials, isEmpty);
  });

  test('entrar con huella abre sesión', () async {
    await activar(pin: '000000', reason: 'r');

    expect(
      await entrar(dni: estado.dni, reason: 'r'),
      isA<BiometricSignInSuccess>(),
    );
  });

  test(
    'credencial revocada: se borra del teléfono y canUse es false',
    () async {
      await activar(pin: '000000', reason: 'r');
      estado.credentials.clear();

      expect(
        await entrar(dni: estado.dni, reason: 'r'),
        isA<BiometricSignInRevoked>(),
      );
      expect(await store.readBiometricCredential(), isNull);
      expect(await entrar.canUse(), isFalse);
    },
  );

  test(
    'sin huellas en el sistema el botón no aplica aunque haya credencial',
    () async {
      await activar(pin: '000000', reason: 'r');
      gate.available = false;

      expect(await entrar.canUse(), isFalse);
    },
  );

  test('desactivar borra local y servidor', () async {
    await activar(pin: '000000', reason: 'r');

    await DisableBiometricUseCase(
      repo: MemorySecurityRepository(estado, clock: DateTime.now),
      store: store,
    )();

    expect(await store.readBiometricCredential(), isNull);
    expect(estado.credentials, isEmpty);
  });
}
