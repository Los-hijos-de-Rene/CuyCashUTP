import 'dart:math';

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('IdempotencyKey.generate', () {
    test('cumple el contrato del backend: 8 a 64 caracteres', () {
      final clave = IdempotencyKey.generate();
      expect(clave.length, inInclusiveRange(8, 64));
    });

    test('es hexadecimal', () {
      expect(IdempotencyKey.generate(), matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('dos claves seguidas no coinciden', () {
      final claves = {for (var i = 0; i < 200; i++) IdempotencyKey.generate()};
      expect(claves, hasLength(200));
    });

    test('con el mismo generador aleatorio es determinista', () {
      expect(
        IdempotencyKey.generate(random: Random(7)),
        IdempotencyKey.generate(random: Random(7)),
      );
    });
  });
}
