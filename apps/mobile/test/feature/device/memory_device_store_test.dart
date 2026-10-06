import 'package:cuycash/feature/lockout/domain/lockout_state.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user save/read/clear', () async {
    final store = MemoryDeviceStore();
    expect(await store.readUser(), isNull);
    const user = RememberedUser(dni: '12345678', fullName: 'Juan Pérez', alias: '@juan');
    await store.saveUser(user);
    expect(await store.readUser(), user);
    await store.clearUser();
    expect(await store.readUser(), isNull);
  });

  test('lockout save/read/clear', () async {
    final store = MemoryDeviceStore();
    expect(await store.readLockout(), const LockoutState());
    final locked = LockoutState(failedAttempts: 1, level: 0, lockedUntil: DateTime(2030));
    await store.saveLockout(locked);
    expect(await store.readLockout(), locked);
    await store.clearLockout();
    expect(await store.readLockout(), const LockoutState());
  });

  test('clearUser también borra la credencial biométrica', () async {
    final store = MemoryDeviceStore();
    expect(await store.saveBiometricCredential('s3cr3t'), isTrue);
    expect(await store.readBiometricCredential(), 's3cr3t');

    await store.clearUser();

    expect(await store.readBiometricCredential(), isNull);
  });

  test('RememberedUser.initials', () {
    expect(const RememberedUser(dni: '1', fullName: 'Juan Pérez', alias: '@j').initials, 'JP');
    expect(const RememberedUser(dni: '1', fullName: 'Juan', alias: '@j').initials, 'J');
  });
}
