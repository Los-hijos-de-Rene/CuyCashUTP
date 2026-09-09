import '../../lockout/domain/lockout_state.dart';
import 'remembered_user.dart';

/// Almacén local del dispositivo (usuario recordado + bloqueo). Nunca lanza:
/// ante error de lectura devuelve null / `const LockoutState()`.
abstract interface class DeviceStore {
  Future<RememberedUser?> readUser();
  Future<void> saveUser(RememberedUser user);
  Future<void> clearUser();

  /// Identificador estable de ESTE teléfono. Lo exige el backend para
  /// reconocer dispositivos de confianza y para su contador de intentos.
  /// Se genera una vez y sobrevive mientras la app siga instalada.
  Future<String> deviceId();

  Future<LockoutState> readLockout();
  Future<void> saveLockout(LockoutState state);
  Future<void> clearLockout();
}
