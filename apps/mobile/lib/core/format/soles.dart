import 'package:core_kernel/core_kernel.dart';
import 'package:intl/intl.dart';

/// Formatea un monto como `S/ 1,250.40`.
///
/// El símbolo va delante y los separadores son los peruanos: coma para miles,
/// punto para decimales. No se usa `NumberFormat.currency(locale: 'es_PE')`
/// porque los datos de ICU para ese locale devuelven `1.250,40 S/`, que no es
/// como se escribe el dinero en el país ni como lo muestran los bancos.
///
/// Recibe [Money] y no un `double`: el redondeo ya lo hizo quien construyó el
/// monto, y aquí solo se decide cómo se ve. El formateo parte de céntimos
/// enteros para no pasar por `double`; los negativos llevan el signo delante
/// del símbolo (`-S/ 1.50`).
String formatSoles(Money monto) {
  final negativo = monto.centimos < 0;
  final abs = monto.centimos.abs();
  final enteros = NumberFormat('#,##0', 'en_US').format(abs ~/ 100);
  final decimales = (abs % 100).toString().padLeft(2, '0');
  return '${negativo ? '-' : ''}S/ $enteros.$decimales';
}
