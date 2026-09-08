import 'lockout_state.dart';
import 'remembered_user.dart';

/// Almacén local del dispositivo (usuario recordado + bloqueo). Nunca lanza:
/// ante error de lectura devuelve null / `const LockoutState()`.
abstract interface class DeviceStore {
  Future<RememberedUser?> readUser();
  Future<void> saveUser(RememberedUser user);
  Future<void> clearUser();

  Future<LockoutState> readLockout();
  Future<void> saveLockout(LockoutState state);
  Future<void> clearLockout();
}
