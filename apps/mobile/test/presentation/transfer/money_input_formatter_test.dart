import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/presentation/transfer/money_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TextEditingValue v(String t) => TextEditingValue(text: t);

  String tras(String antes, String despues, {VoidCallback? onRejected}) =>
      MoneyInputFormatter(
        onRejected: onRejected,
      ).formatEditUpdate(v(antes), v(despues)).text;

  test('deja pasar lo que Money.parse sabe leer', () {
    for (final ok in ['', '1', '250', '250.', '250.5', '250.50', '250,50']) {
      expect(tras('', ok), ok, reason: ok);
    }
  });

  test('rechaza la coma de miles: 1,234 vuelve a lo anterior', () {
    var avisos = 0;
    expect(tras('1,23', '1,234', onRejected: () => avisos++), '1,23');
    expect(avisos, 1);
  });

  test('rechaza el pegado de 1,234.56 entero', () {
    var avisos = 0;
    expect(tras('', '1,234.56', onRejected: () => avisos++), '');
    expect(avisos, 1);
  });

  test('rechaza letras, signos, un tercer decimal y varios separadores', () {
    for (final mal in ['a', '-5', '+5', '1.234', '1.2.3', '1e5', '12345678']) {
      expect(tras('', mal), '', reason: mal);
    }
  });

  test('todo lo que deja pasar y es completo lo lee Money.parse', () {
    for (final t in ['250', '250.5', '250,50', '0.01']) {
      expect(Money.parse(t), isNotNull, reason: t);
    }
  });
}
