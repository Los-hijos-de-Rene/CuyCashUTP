import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/format/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatea con separadores peruanos', () {
    expect(formatMoney(Money.soles(125040)), 'S/ 1,250.40');
    expect(formatMoney(Money.zero(Currency.pen)), 'S/ 0.00');
    expect(formatMoney(Money.soles(5)), 'S/ 0.05');
    expect(formatMoney(Money.soles(100000000)), 'S/ 1,000,000.00');
  });

  test('un negativo lleva el signo delante', () {
    expect(formatMoney(Money.soles(-150)), '-S/ 1.50');
    expect(
      '-'.allMatches(formatMoney(Money.soles(-5000))).length,
      1,
      reason: 'un solo signo; la UI no debe anteponer otro',
    );
  });

  test('los dólares llevan US\$ delante', () {
    expect(formatMoney(const Money.dolares(2000)), r'US$ 20.00');
    expect(formatMoney(const Money.dolares(123456789)), r'US$ 1,234,567.89');
    expect(formatMoney(const Money.dolares(-150)), r'-US$ 1.50');
  });
}
