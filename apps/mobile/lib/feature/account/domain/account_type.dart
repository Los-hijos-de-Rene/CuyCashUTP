/// Tipo de una cuenta de titular. Espejo del `CHECK` de `accounts.tipo`
/// (sin `sistema`, que nunca llega a la app).
enum AccountType {
  ahorro('ahorro'),
  corriente('corriente'),
  sueldo('sueldo');

  const AccountType(this.code);

  /// Como viaja en el JSON.
  final String code;

  /// `null` ante un tipo desconocido: quien parsea decide.
  static AccountType? fromCode(String code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}
