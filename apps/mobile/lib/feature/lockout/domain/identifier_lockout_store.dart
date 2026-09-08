import 'lockout_state.dart';

/// Bloqueo por IDENTIFICADOR (el DNI), no por teléfono.
///
/// Es el contador que protege el inicio de sesión: si se atara al dispositivo,
/// bastaría con probar desde otro teléfono para saltárselo. La clave del rate
/// limit es la cuenta.
///
/// Por eso NO se persiste en el almacén cifrado local: es estado de servidor.
/// Hasta que exista backend real vive en memoria (ver
/// `MemoryIdentifierLockoutStore`), igual que el reto del OTP.
abstract interface class IdentifierLockoutStore {
  Future<LockoutState> read(String identifier);
  Future<void> save(String identifier, LockoutState state);
  Future<void> clear(String identifier);
}
