import 'dart:math';

/// Id de usuario (extension type sobre String — cero costo en runtime, tipado
/// en compile-time).
extension type const UserId(String value) {}

/// Genera claves de idempotencia para operaciones que mueven dinero.
///
/// Una clave identifica una INTENCIÓN del usuario, no un intento: se genera
/// una vez, antes de que haya nada que pueda duplicarse, y se reutiliza en
/// cada reintento. El backend exige de 8 a 64 caracteres.
abstract final class IdempotencyKey {
  static final Random _secure = Random.secure();

  /// 32 caracteres hexadecimales (128 bits de aleatoriedad). [random] solo se
  /// inyecta en tests; por defecto es criptográficamente seguro.
  static String generate({Random? random}) {
    final rng = random ?? _secure;
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
