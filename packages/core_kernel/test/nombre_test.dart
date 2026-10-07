import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('formatNombre', () {
    test('mayúscula al inicio de cada palabra, el resto en minúsculas', () {
      expect(formatNombre('jair alberto conislla pérez'),
          'Jair Alberto Conislla Pérez');
      expect(formatNombre('JAIR CONISLLA'), 'Jair Conislla');
    });

    test('quita espacios de más', () {
      expect(formatNombre('  ana   maría  '), 'Ana María');
    });

    test('respeta los apellidos compuestos con guion', () {
      expect(formatNombre('garcía-pérez'), 'García-Pérez');
    });

    test('vacío queda vacío', () {
      expect(formatNombre('   '), '');
    });

    test('no altera un nombre enmascarado', () {
      expect(formatNombre('J*** M*** R***'), 'J*** M*** R***');
    });
  });
}
