import '../../lockout/domain/lockout_state.dart';
import 'remembered_user.dart';

/// Almacén local del dispositivo (usuario recordado + bloqueo). Nunca lanza:
/// ante error de lectura devuelve null / `const LockoutState()`.
abstract interface class DeviceStore {
  Future<RememberedUser?> readUser();
  Future<void> saveUser(RememberedUser user);

  /// Olvida al usuario Y su credencial biométrica: otro usuario en este
  /// teléfono no hereda la huella del anterior.
  Future<void> clearUser();

  /// Credencial biométrica de ESTE teléfono para el usuario recordado.
  Future<String?> readBiometricCredential();

  /// `false` si no se pudo escribir: quien activó la huella debe revocarla en
  /// el servidor para no dejar una credencial huérfana.
  Future<bool> saveBiometricCredential(String credential);

  Future<void> clearBiometricCredential();

  /// Identificador estable de ESTE teléfono. Lo exige el backend para
  /// reconocer dispositivos de confianza y para su contador de intentos.
  /// Se genera una vez y sobrevive mientras la app siga instalada.
  Future<String> deviceId();

  Future<LockoutState> readLockout();
  Future<void> saveLockout(LockoutState state);
  Future<void> clearLockout();
}
