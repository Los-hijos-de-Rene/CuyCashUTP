import '../../profile/domain/alias_rules.dart';

/// Lo que se teclea para buscar a quién enviarle: un DNI o un alias.
///
/// No hay ambigüedad: el DNI son 8 dígitos y el alias lleva al menos una
/// letra ([AliasRules]).
sealed class RecipientQuery {
  const RecipientQuery();

  /// `null` si el texto no es ni un DNI completo ni un alias válido.
  static RecipientQuery? parse(String texto) {
    final limpio = texto.trim();
    if (_dni.hasMatch(limpio)) return DniQuery(limpio);
    final alias = AliasRules.normalize(limpio);
    return AliasRules.isValid(alias) ? AliasQuery(alias) : null;
  }

  /// Solo dígitos: el usuario está escribiendo un DNI (completo o no).
  static bool looksLikeDni(String texto) => _digitos.hasMatch(texto.trim());

  static final _dni = RegExp(r'^\d{8}$');
  static final _digitos = RegExp(r'^\d+$');
}

final class DniQuery extends RecipientQuery {
  const DniQuery(this.dni);
  final String dni;
}

/// [alias] ya normalizado: minúsculas y con `@`.
final class AliasQuery extends RecipientQuery {
  const AliasQuery(this.alias);
  final String alias;
}
