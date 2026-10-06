/// Monedas en las que CuyCash lleva cuentas. Espejo del `CHECK` de
/// `accounts.moneda` del backend.
enum Currency {
  pen('PEN', 'S/'),
  usd('USD', r'US$');

  const Currency(this.code, this.symbol);

  /// Código ISO 4217, como viaja en el JSON.
  final String code;

  /// Cómo se escribe delante del monto en Perú.
  final String symbol;

  /// `null` ante un código desconocido: quien parsea decide (normalmente, un
  /// fallo inesperado). Adivinar soles pintaría dólares como soles.
  static Currency? fromCode(String code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}
