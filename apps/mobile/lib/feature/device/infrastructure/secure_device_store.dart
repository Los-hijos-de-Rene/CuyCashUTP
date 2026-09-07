import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/device_store.dart';
import '../domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// DeviceStore cifrado (Keychain / EncryptedSharedPreferences). Usado en todos
/// los flavors (capacidad del dispositivo, no backend).
class SecureDeviceStore implements DeviceStore {
  const SecureDeviceStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _userKey = 'cuycash.remembered_user';
  static const _lockoutKey = 'cuycash.lockout';

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
  Future<void> clearUser() => _storage.delete(key: _userKey);

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
