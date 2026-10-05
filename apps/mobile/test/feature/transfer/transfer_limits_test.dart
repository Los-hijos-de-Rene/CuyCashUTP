import 'package:cuycash/feature/transfer/domain/transfer_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransferLimits.normalizarMotivo', () {
    test('null, vacío y espacios no viajan', () {
      expect(TransferLimits.normalizarMotivo(null), isNull);
      expect(TransferLimits.normalizarMotivo(''), isNull);
      expect(TransferLimits.normalizarMotivo('   '), isNull);
    });

    test('recorta espacios de los extremos', () {
      expect(TransferLimits.normalizarMotivo('  Almuerzo '), 'Almuerzo');
    });

    test('corta a 40 caracteres', () {
      expect(TransferLimits.normalizarMotivo('a' * 41), 'a' * 40);
      expect(TransferLimits.normalizarMotivo('a' * 40), 'a' * 40);
    });

    test('cuenta puntos de código, sin partir un emoji por la mitad', () {
      final r = TransferLimits.normalizarMotivo('😀' * 50)!;
      expect(r.runes.length, 40);
    });
  });
}
