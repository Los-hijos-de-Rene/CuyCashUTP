import 'package:intl/intl.dart';

/// Formatea un monto en soles como `S/ 1,250.40`.
///
/// El símbolo va delante y los separadores son los peruanos: coma para miles,
/// punto para decimales. No se usa `NumberFormat.currency(locale: 'es_PE')`
/// porque los datos de ICU para ese locale devuelven `1.250,40 S/`, que no es
/// como se escribe el dinero en el país ni como lo muestran los bancos.
///
/// Un solo lugar: cuando entre el motor transaccional, redondeo y separadores
/// no pueden divergir entre pantallas.
String formatSoles(double amount) =>
    'S/ ${NumberFormat('#,##0.00', 'en_US').format(amount)}';
