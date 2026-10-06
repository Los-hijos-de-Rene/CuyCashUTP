/// Reglas del apodo de un frecuente (`BeneficiaryIn` del backend).
abstract final class BeneficiaryLimits {
  static const apodoMaxLength = 40;

  /// Recorta espacios y limita a [apodoMaxLength]: el backend responde 422 a
  /// uno más largo y el usuario no podría entender ese error.
  static String normalizarApodo(String apodo) {
    final limpio = apodo.trim();
    return limpio.length <= apodoMaxLength
        ? limpio
        : limpio.substring(0, apodoMaxLength).trimRight();
  }
}
