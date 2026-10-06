import '../domain/device_store.dart';
import '../../lockout/domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// DeviceStore en memoria (tests / fake).
class MemoryDeviceStore implements DeviceStore {
  MemoryDeviceStore({RememberedUser? user, LockoutState lockout = const LockoutState()})
      : _user = user,
        _lockout = lockout;

  RememberedUser? _user;
  String? _credential;

  /// Simula un disco que no escribe (para probar la credencial huérfana).
  bool failCredentialWrites = false;
  LockoutState _lockout;

  @override
  Future<RememberedUser?> readUser() async => _user;

  @override
  Future<void> saveUser(RememberedUser user) async => _user = user;

  @override
  Future<void> clearUser() async {
    _user = null;
    _credential = null;
  }

  @override
  Future<String?> readBiometricCredential() async => _credential;

  @override
  Future<bool> saveBiometricCredential(String credential) async {
    if (failCredentialWrites) return false;
    _credential = credential;
    return true;
  }

  @override
  Future<void> clearBiometricCredential() async => _credential = null;

  String? _deviceId;

  @override
  Future<String> deviceId() async => _deviceId ??= 'mem-device-${_seq++}';

  static int _seq = 0;

  @override
  Future<LockoutState> readLockout() async => _lockout;

  @override
  Future<void> saveLockout(LockoutState state) async => _lockout = state;

  @override
  Future<void> clearLockout() async => _lockout = const LockoutState();
}
