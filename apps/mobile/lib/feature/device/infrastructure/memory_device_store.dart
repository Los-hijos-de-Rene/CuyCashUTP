import '../domain/device_store.dart';
import '../domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// DeviceStore en memoria (tests / fake).
class MemoryDeviceStore implements DeviceStore {
  MemoryDeviceStore({RememberedUser? user, LockoutState lockout = const LockoutState()})
      : _user = user,
        _lockout = lockout;

  RememberedUser? _user;
  LockoutState _lockout;

  @override
  Future<RememberedUser?> readUser() async => _user;

  @override
  Future<void> saveUser(RememberedUser user) async => _user = user;

  @override
  Future<void> clearUser() async => _user = null;

  @override
  Future<LockoutState> readLockout() async => _lockout;

  @override
  Future<void> saveLockout(LockoutState state) async => _lockout = state;

  @override
  Future<void> clearLockout() async => _lockout = const LockoutState();
}
