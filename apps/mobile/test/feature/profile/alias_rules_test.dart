import 'package:cuycash/feature/profile/domain/alias_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza como el backend: minúsculas, sin bordes, con @', () {
    expect(AliasRules.normalize('  Jenny_01 '), '@jenny_01');
    expect(AliasRules.normalize('@j.r'), '@j.r');
  });

  test('acepta 3 a 20 de [a-z0-9_.] y rechaza el resto', () {
    for (final bueno in ['@abc', '@j.r_9', '@${'a' * 20}']) {
      expect(AliasRules.isValid(AliasRules.normalize(bueno)), isTrue, reason: bueno);
    }
    for (final malo in ['ab', 'ñandú', 'con espacio', 'a' * 21, '@', '']) {
      expect(AliasRules.isValid(AliasRules.normalize(malo)), isFalse, reason: malo);
    }
  });

  test('exige al menos una letra: puros dígitos se confundirían con un DNI', () {
    for (final malo in ['12345678', '@123', '1_2.3', '___']) {
      expect(AliasRules.isValid(AliasRules.normalize(malo)), isFalse, reason: malo);
    }
    expect(AliasRules.isValid('@a1234567'), isTrue);
  });
}
