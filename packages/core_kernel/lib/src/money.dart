import 'currency.dart';

/// Un monto en una moneda, guardado como céntimos enteros.
///
/// Existe porque un `double` que representa S/ 0.10 no vale 0.10: tres sumas
/// después, el saldo de la pantalla ya no es el del libro mayor. El backend
/// decidió céntimos enteros; deshacerlo al deserializar anularía la decisión.
///
/// Al ser un tipo propio, el compilador impide pasar un número crudo donde va
/// dinero. Admite valores negativos (la cuenta de sistema del backend tiene
/// saldo negativo): rechazar la entrada negativa del usuario es trabajo de
/// [parse], no del tipo.
final class Money implements Comparable<Money> {
  const Money(this.centimos, this.currency);
  const Money.soles(this.centimos) : currency = Currency.pen;
  const Money.dolares(this.centimos) : currency = Currency.usd;

  static Money zero(Currency currency) => Money(0, currency);

  // Solo dígitos ASCII (`\d` en Dart no incluye otros alfabetos), un único
  // separador decimal (`.` o `,`) y como máximo dos decimales. El tope de 12
  // dígitos enteros evita desbordar `int` en js y no es un límite de negocio.
  static final RegExp _formato = RegExp(r'^(\d{1,12})(?:[.,](\d{1,2}))?$');

  /// Lee lo que el usuario escribe (`250`, `250.00`, `250,00`) en [currency].
  ///
  /// Devuelve `null` ante cualquier cosa que no sea un monto, en
  /// lugar de adivinar: más de dos decimales, signos (`-5`, `+5`), notación
  /// científica, separador de miles (`1,234.56`), varios separadores
  /// (`1.2.3`), dígitos no ASCII o texto vacío. Quien llama decide qué hacer
  /// con una entrada inválida; aceptar de más acabaría cobrando lo que el
  /// usuario no quiso decir. Solo se ignoran los espacios de los extremos.
  static Money? parse(String texto, Currency currency) {
    final match = _formato.firstMatch(texto.trim());
    if (match == null) return null;

    final enteros = int.parse(match.group(1)!);
    final decimales = (match.group(2) ?? '').padRight(2, '0');
    return Money(enteros * 100 + int.parse(decimales), currency);
  }

  final int centimos;
  final Currency currency;

  /// Sumar soles con dólares no es un caso de negocio que el usuario pueda
  /// provocar: es un bug de quien armó la operación. Reventar es lo correcto;
  /// devolver un número sin sentido movería dinero equivocado.
  void _misma(Money other) {
    if (other.currency != currency) {
      throw StateError(
        'Monedas mezcladas: ${currency.code} y ${other.currency.code}',
      );
    }
  }

  Money operator +(Money other) {
    _misma(other);
    return Money(centimos + other.centimos, currency);
  }

  Money operator -(Money other) {
    _misma(other);
    return Money(centimos - other.centimos, currency);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) {
    _misma(other);
    return centimos.compareTo(other.centimos);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.centimos == centimos &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(centimos, currency);

  @override
  String toString() => 'Money($centimos ${currency.code})';
}
