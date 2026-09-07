import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 10, 0, 0);

  test('primer y segundo fallo suben failedAttempts sin bloquear', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    final s1 = await actions.registerFailedAttempt(t0);
    expect(s1.failedAttempts, 1);
    expect(s1.isLocked(t0), isFalse);
    final s2 = await actions.registerFailedAttempt(t0);
    expect(s2.failedAttempts, 2);
    expect(s2.isLocked(t0), isFalse);
  });

  test('tercer fallo bloquea 15 min (nivel 1) y reinicia el contador', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    await actions.registerFailedAttempt(t0);
    await actions.registerFailedAttempt(t0);
    final s3 = await actions.registerFailedAttempt(t0);
    expect(s3.level, 1);
    expect(s3.failedAttempts, 0);
    expect(s3.lockedUntil, t0.add(const Duration(minutes: 15)));
    expect(s3.isLocked(t0), isTrue);
    expect(s3.isLocked(t0.add(const Duration(minutes: 16))), isFalse);
  });

  test('segundo bloqueo escala a 1 h (nivel 2)', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    for (var i = 0; i < 3; i++) {
      await actions.registerFailedAttempt(t0);
    }
    for (var i = 0; i < 2; i++) {
      await actions.registerFailedAttempt(t0);
    }
    final s = await actions.registerFailedAttempt(t0);
    expect(s.level, 2);
    expect(s.lockedUntil, t0.add(const Duration(hours: 1)));
  });

  test('resetLockout limpia', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    await actions.registerFailedAttempt(t0);
    await actions.resetLockout();
    final s = await actions.readLockout();
    expect(s.failedAttempts, 0);
    expect(s.lockedUntil, isNull);
  });
}
