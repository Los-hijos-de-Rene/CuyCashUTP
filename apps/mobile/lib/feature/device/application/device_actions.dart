import '../domain/device_store.dart';
import '../domain/lockout_policy.dart';
import '../domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// Capa de aplicación del dispositivo. `registerFailedAttempt` encapsula el
/// escalonado de bloqueo (reloj inyectado por el llamador).
class DeviceActions {
  const DeviceActions(this._store);

  final DeviceStore _store;

  Future<RememberedUser?> readUser() => _store.readUser();
  Future<void> saveUser(RememberedUser user) => _store.saveUser(user);
  Future<void> clearUser() => _store.clearUser();
  Future<LockoutState> readLockout() => _store.readLockout();

  /// Registra un intento fallido. Al alcanzar `maxAttempts`, sube de nivel y
  /// fija `lockedUntil = now + duración(nivel)`, reiniciando el contador.
  Future<LockoutState> registerFailedAttempt(DateTime now) async {
    final current = await _store.readLockout();
    final attempts = current.failedAttempts + 1;
    final LockoutState next;
    if (attempts >= LockoutPolicy.maxAttempts) {
      final level = current.level + 1;
      next = LockoutState(
        failedAttempts: 0,
        level: level,
        lockedUntil: now.add(LockoutPolicy.durationForLevel(level)),
      );
    } else {
      next = current.copyWith(failedAttempts: attempts);
    }
    await _store.saveLockout(next);
    return next;
  }

  Future<void> resetLockout() => _store.clearLockout();
}
