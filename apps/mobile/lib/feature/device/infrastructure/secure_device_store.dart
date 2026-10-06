import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/device_store.dart';
import '../../lockout/domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// DeviceStore cifrado (Keychain / EncryptedSharedPreferences). Usado en todos
/// los flavors (capacidad del dispositivo, no backend).
class SecureDeviceStore implements DeviceStore {
  const SecureDeviceStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _userKey = 'cuycash.remembered_user';
  static const _lockoutKey = 'cuycash.lockout';
  static const _deviceIdKey = 'cuycash.device_id';
  static const _biometricKey = 'cuycash.biometric_credential';

  @override
  Future<RememberedUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return RememberedUser.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUser(RememberedUser user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  @override
  Future<void> clearUser() async {
    await _storage.delete(key: _userKey);
    // Otro usuario en este teléfono no hereda la huella del anterior.
    await _storage.delete(key: _biometricKey);
  }

  @override
  Future<String?> readBiometricCredential() =>
      _storage.read(key: _biometricKey);

  @override
  Future<bool> saveBiometricCredential(String credential) async {
    try {
      await _storage.write(key: _biometricKey, value: credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearBiometricCredential() =>
      _storage.delete(key: _biometricKey);

  @override
  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    // Se genera aquí y no en el servidor: identifica al teléfono, no a la
    // cuenta, así que debe sobrevivir a un cambio de usuario.
    final generated = _randomId();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  /// 128 bits al azar. No se usa un identificador del sistema (IMEI,
  /// androidId) a propósito: son datos del aparato y su lectura está
  /// restringida; para reconocer un teléfono basta con un valor propio.
  static String _randomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<LockoutState> readLockout() async {
    final raw = await _storage.read(key: _lockoutKey);
    if (raw == null) return const LockoutState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const LockoutState();
      return LockoutState.fromJson(decoded);
    } catch (_) {
      return const LockoutState();
    }
  }

  @override
  Future<void> saveLockout(LockoutState state) =>
      _storage.write(key: _lockoutKey, value: jsonEncode(state.toJson()));

  @override
  Future<void> clearLockout() => _storage.delete(key: _lockoutKey);
}
