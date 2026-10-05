import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('sumar diez veces S/ 0.10 da exactamente S/ 1.00', () {
      // Con double, esta suma da 0.9999999999999999. Es la razón entera de
      // que este tipo exista.
      var total = Money.zero;
      for (var i = 0; i < 10; i++) {
        total = total + Money.fromCentimos(10);
      }
      expect(total, Money.fromCentimos(100));
    });

    test('parse acepta las formas que el usuario escribe', () {
      expect(Money.parse('250'), Money.fromCentimos(25000));
      expect(Money.parse('250.00'), Money.fromCentimos(25000));
      expect(Money.parse('250,00'), Money.fromCentimos(25000));
      expect(Money.parse('250.5'), Money.fromCentimos(25050));
      expect(Money.parse(' 250.00 '), Money.fromCentimos(25000));
      expect(Money.parse('0.01'), Money.fromCentimos(1));
      expect(Money.parse('0'), Money.zero);
      expect(Money.parse('007.50'), Money.fromCentimos(750));
    });

    test('parse rechaza lo que no es un monto', () {
      expect(Money.parse('abc'), isNull);
      expect(Money.parse(''), isNull);
      expect(Money.parse('-5'), isNull);
      expect(
        Money.parse('1.234'),
        isNull,
        reason: 'tres decimales no son soles',
      );
      expect(Money.parse('1.2.3'), isNull);
    });

    test('parse rechaza entradas ambiguas o que aceptarían de más', () {
      expect(Money.parse('1,234.56'), isNull, reason: 'separador de miles');
      expect(Money.parse('1,234'), isNull, reason: 'ambiguo: tres decimales');
      expect(Money.parse('1,2,3'), isNull);
      expect(Money.parse('  '), isNull);
      expect(Money.parse('+5'), isNull);
      expect(Money.parse('1e3'), isNull);
      expect(Money.parse('٥'), isNull, reason: 'dígitos árabes');
      expect(Money.parse('５'), isNull, reason: 'dígitos de ancho completo');
      expect(Money.parse('.5'), isNull);
      expect(Money.parse('5.'), isNull);
      expect(Money.parse('5 0'), isNull);
      expect(Money.parse('0x10'), isNull);
      expect(Money.parse('NaN'), isNull);
      expect(Money.parse('1\n2'), isNull);
      expect(Money.parse('9' * 40), isNull, reason: 'no desborda ni lanza');
    });

    test('admite negativos (saldo de la cuenta de sistema)', () {
      final saldo = Money.fromCentimos(100) - Money.fromCentimos(250);
      expect(saldo.centimos, -150);
      expect(saldo < Money.zero, isTrue);
    });

    test('compara por céntimos', () {
      expect(Money.fromCentimos(100) < Money.fromCentimos(101), isTrue);
      expect(Money.fromCentimos(100) >= Money.fromCentimos(100), isTrue);
      expect(Money.fromCentimos(100) > Money.fromCentimos(101), isFalse);
      expect(Money.fromCentimos(100) <= Money.fromCentimos(99), isFalse);
      expect(
        Money.fromCentimos(1).compareTo(Money.fromCentimos(2)),
        isNegative,
      );
    });

    test('dos montos iguales son el mismo valor', () {
      expect(Money.fromCentimos(250), Money.fromCentimos(250));
      expect({Money.fromCentimos(250), Money.fromCentimos(250)}.length, 1);
    });
  });
}
