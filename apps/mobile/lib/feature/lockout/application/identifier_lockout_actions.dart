import '../domain/identifier_lockout_store.dart';
import '../domain/lockout_policy.dart';
import '../domain/lockout_state.dart';

/// Rate limit del inicio de sesión, con el DNI como clave.
///
/// Es el gemelo de `DeviceActions.registerFailedAttempt`, pero con otro
/// alcance: aquel bloquea ESTE teléfono (acceso rápido), este bloquea LA CUENTA
/// en cualquier teléfono.
class IdentifierLockoutActions {
  const IdentifierLockoutActions(
    this._store, {
    this.policy = const LockoutPolicy(),
  });

  final IdentifierLockoutStore _store;
  final LockoutPolicy policy;

  Future<LockoutState> read(String identifier) => _store.read(identifier);

  /// Registra un intento fallido contra [identifier]. Al alcanzar
  /// `maxAttempts` sube de nivel y fija `lockedUntil`, reiniciando el contador.
  Future<LockoutState> registerFailedAttempt(
    String identifier,
    DateTime now,
  ) async {
    final current = await _store.read(identifier);
    final attempts = current.failedAttempts + 1;
    final LockoutState next;
    if (attempts >= LockoutPolicy.maxAttempts) {
      final level = current.level + 1;
      next = LockoutState(
        failedAttempts: 0,
        level: level,
        lockedUntil: now.add(policy.durationForLevel(level)),
      );
    } else {
      next = current.copyWith(failedAttempts: attempts);
    }
    await _store.save(identifier, next);
    return next;
  }

  Future<void> reset(String identifier) => _store.clear(identifier);
}
