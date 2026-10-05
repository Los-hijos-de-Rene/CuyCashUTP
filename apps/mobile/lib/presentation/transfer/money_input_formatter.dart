import 'package:flutter/services.dart';

/// Deja pasar solo lo que `Money.parse` sabe leer: dígitos, un separador
/// decimal (`.` o `,`) y como máximo dos decimales.
///
/// `Money.parse` rechaza el separador de miles (`1,234` es ambiguo: ¿1.234 o
/// 1234?) porque leerlo mal es un error de factor 1000. Por eso el campo no
/// deja teclearlo: con tres dígitos tras la coma la edición se rechaza y se
/// avisa por [onRejected], en vez de quedarse muda.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter({this.onRejected});

  /// Se llama cuando se descartó una edición (p. ej. `1,234` o un pegado
  /// con letras).
  final VoidCallback? onRejected;

  /// Hasta 7 enteros (el tope por envío es 2,000.00) y 2 decimales.
  static final _permitido = RegExp(r'^\d{0,7}(?:[.,]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_permitido.hasMatch(newValue.text)) return newValue;
    onRejected?.call();
    return oldValue;
  }
}
