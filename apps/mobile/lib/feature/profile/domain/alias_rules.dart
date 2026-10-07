/// La regla del alias, idéntica a la de `services/api/app/services/alias.py`.
/// Vive en el dominio para validar en vivo sin esperar al servidor; el
/// servidor la vuelve a aplicar.
///
/// El alias es único y sirve para que te encuentren al enviarte dinero. Lleva
/// al menos una letra: puros dígitos se confundirían con un DNI en la búsqueda.
abstract final class AliasRules {
  static final _valido = RegExp(r'^@(?=[a-z0-9_.]*[a-z])[a-z0-9_.]{3,20}$');

  static String normalize(String texto) {
    final limpio = texto.trim().toLowerCase();
    return limpio.startsWith('@') ? limpio : '@$limpio';
  }

  static bool isValid(String normalizado) => _valido.hasMatch(normalizado);
}
