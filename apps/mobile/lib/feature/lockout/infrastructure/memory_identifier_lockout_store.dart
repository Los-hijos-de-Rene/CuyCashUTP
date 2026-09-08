import '../domain/identifier_lockout_store.dart';
import '../domain/lockout_state.dart';

/// Memory* FUNCIONAL del bloqueo por identificador (backend del flavor `mock`
/// + contrato de tests).
///
/// Simula estado de servidor: se comparte entre todas las pantallas de la app
/// y se pierde al reiniciarla, porque el bloqueo real lo llevará el backend y
/// no debe depender de lo que el teléfono guarde.
class MemoryIdentifierLockoutStore implements IdentifierLockoutStore {
  final Map<String, LockoutState> _byIdentifier = {};

  @override
  Future<LockoutState> read(String identifier) async =>
      _byIdentifier[identifier] ?? const LockoutState();

  @override
  Future<void> save(String identifier, LockoutState state) async =>
      _byIdentifier[identifier] = state;

  @override
  Future<void> clear(String identifier) async =>
      _byIdentifier.remove(identifier);
}
