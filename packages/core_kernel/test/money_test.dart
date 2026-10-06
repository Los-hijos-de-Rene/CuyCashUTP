import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('sumar diez veces S/ 0.10 da exactamente S/ 1.00', () {
      // Con double, esta suma da 0.9999999999999999. Es la razón entera de
      // que este tipo exista.
      var total = Money.zero(Currency.pen);
      for (var i = 0; i < 10; i++) {
        total = total + Money.soles(10);
      }
      expect(total, Money.soles(100));
    });

    test('parse acepta las formas que el usuario escribe', () {
      expect(Money.parse('250', Currency.pen), Money.soles(25000));
      expect(Money.parse('250.00', Currency.pen), Money.soles(25000));
      expect(Money.parse('250,00', Currency.pen), Money.soles(25000));
      expect(Money.parse('250.5', Currency.pen), Money.soles(25050));
      expect(Money.parse(' 250.00 ', Currency.pen), Money.soles(25000));
      expect(Money.parse('0.01', Currency.pen), Money.soles(1));
      expect(Money.parse('0', Currency.pen), Money.zero(Currency.pen));
      expect(Money.parse('007.50', Currency.pen), Money.soles(750));
    });

    test('parse rechaza lo que no es un monto', () {
      expect(Money.parse('abc', Currency.pen), isNull);
      expect(Money.parse('', Currency.pen), isNull);
      expect(Money.parse('-5', Currency.pen), isNull);
      expect(
        Money.parse('1.234', Currency.pen),
        isNull,
        reason: 'tres decimales no son soles',
      );
      expect(Money.parse('1.2.3', Currency.pen), isNull);
    });

    test('parse rechaza entradas ambiguas o que aceptarían de más', () {
      expect(
        Money.parse('1,234.56', Currency.pen),
        isNull,
        reason:
            'decisión: no se interpretan separadores de miles; '
            '1,234 es ambiguo (decimal en es-PE, miles en inglés)',
      );
      expect(
        Money.parse('1,234', Currency.pen),
        isNull,
        reason: 'ambiguo: tres decimales',
      );
      expect(Money.parse('1,2,3', Currency.pen), isNull);
      expect(Money.parse('  ', Currency.pen), isNull);
      expect(Money.parse('+5', Currency.pen), isNull);
      expect(Money.parse('1e3', Currency.pen), isNull);
      expect(Money.parse('٥', Currency.pen), isNull, reason: 'dígitos árabes');
      expect(
        Money.parse('５', Currency.pen),
        isNull,
        reason: 'dígitos de ancho completo',
      );
      expect(Money.parse('.5', Currency.pen), isNull);
      expect(Money.parse('5.', Currency.pen), isNull);
      expect(Money.parse('5 0', Currency.pen), isNull);
      expect(Money.parse('0x10', Currency.pen), isNull);
      expect(Money.parse('NaN', Currency.pen), isNull);
      expect(Money.parse('1\n2', Currency.pen), isNull);
      expect(
        Money.parse('9' * 40, Currency.pen),
        isNull,
        reason: 'no desborda ni lanza',
      );
    });

    test('admite negativos (saldo de la cuenta de sistema)', () {
      final saldo = Money.soles(100) - Money.soles(250);
      expect(saldo.centimos, -150);
      expect(saldo < Money.zero(Currency.pen), isTrue);
    });

    test('compara por céntimos', () {
      expect(Money.soles(100) < Money.soles(101), isTrue);
      expect(Money.soles(100) >= Money.soles(100), isTrue);
      expect(Money.soles(100) > Money.soles(101), isFalse);
      expect(Money.soles(100) <= Money.soles(99), isFalse);
      expect(Money.soles(1).compareTo(Money.soles(2)), isNegative);
    });

    test('dos montos iguales son el mismo valor', () {
      expect(Money.soles(250), Money.soles(250));
      expect({Money.soles(250), Money.soles(250)}.length, 1);
    });

    test('la moneda es parte del valor', () {
      expect(Money.soles(100), isNot(Money.dolares(100)));
      expect(Money.soles(100), Money(100, Currency.pen));
      expect(Money.soles(100).hashCode, Money(100, Currency.pen).hashCode);
    });

    test('operar monedas distintas es un error de programación', () {
      expect(() => Money.soles(1) + Money.dolares(1), throwsStateError);
      expect(() => Money.soles(1) - Money.dolares(1), throwsStateError);
      expect(() => Money.soles(1) < Money.dolares(1), throwsStateError);
      expect(
        () => Money.soles(1).compareTo(Money.dolares(1)),
        throwsStateError,
      );
    });

    test('parse lleva la moneda que se le pide', () {
      expect(Money.parse('20', Currency.usd), Money.dolares(2000));
    });

    test('Currency se lee por código y rechaza los desconocidos', () {
      expect(Currency.fromCode('PEN'), Currency.pen);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('EUR'), isNull);
      expect(Currency.pen.symbol, 'S/');
      expect(Currency.usd.symbol, r'US$');
    });
  });
}
