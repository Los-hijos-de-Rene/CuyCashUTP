/// Reglas de cuentas que la UI aplica ANTES de pedir, espejo del backend.
abstract final class AccountLimits {
  /// Cuentas por titular, cerradas incluidas.
  static const maxCuentas = 5;

  /// Caracteres del nombre que el titular le pone a su cuenta.
  static const nombreMaxLength = 30;

  /// Recortado; vacío es `null`. No valida el largo: eso lo dice la pantalla.
  static String? normalizarNombre(String? crudo) {
    final limpio = (crudo ?? '').trim();
    return limpio.isEmpty ? null : limpio;
  }
}
