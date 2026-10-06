/// Reglas del PIN de 6 dígitos (las mismas que `pin_is_valid` del backend).
abstract final class PinRules {
  static final _pin = RegExp(r'^\d{6}$');

  /// Cada condición del PIN se expone por separado, y no solo agregada en
  /// [isValid], para que la checklist pueda mostrar EXACTAMENTE cuál falta.
  /// Una regla que se comprueba en silencio deja al usuario atascado sin saber
  /// qué corregir.
  static bool hasSixDigits(String pin) => _pin.hasMatch(pin);

  /// Descarta 000000, 111111… (los seis dígitos iguales).
  static bool hasNoRepeatedDigit(String pin) =>
      hasSixDigits(pin) && pin.split('').toSet().length > 1;

  /// Descarta secuencias triviales, ascendentes o descendentes (123456 /
  /// 654321).
  static bool hasNoSequence(String pin) {
    if (!hasSixDigits(pin)) return false;
    const asc = '0123456789';
    const desc = '9876543210';
    return !asc.contains(pin) && !desc.contains(pin);
  }

  static bool isValid(String pin) =>
      hasSixDigits(pin) && hasNoRepeatedDigit(pin) && hasNoSequence(pin);
}
