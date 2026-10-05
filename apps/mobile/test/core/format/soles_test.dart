import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/format/soles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatea con separadores peruanos', () {
    expect(formatSoles(Money.fromCentimos(125040)), 'S/ 1,250.40');
    expect(formatSoles(Money.zero), 'S/ 0.00');
    expect(formatSoles(Money.fromCentimos(5)), 'S/ 0.05');
    expect(formatSoles(Money.fromCentimos(100000000)), 'S/ 1,000,000.00');
  });

  test('un negativo lleva el signo delante', () {
    expect(formatSoles(Money.fromCentimos(-150)), '-S/ 1.50');
  });
}
