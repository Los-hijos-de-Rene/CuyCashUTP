import 'package:core_kernel/core_kernel.dart';

import 'account_type.dart';

/// Una cuenta del usuario, tal como la informa el servidor.
///
/// Los saldos son [Money] (céntimos enteros): ningún `double` toca el dinero.
/// El saldo es el que dice el servidor; el teléfono no lo recalcula sumando
/// movimientos.
class Account {
  const Account({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.moneda,
    required this.estado,
    this.nombre,
    required this.saldoDisponible,
    required this.saldoContable,
  });

  final String id;
  final String numero;

  final AccountType tipo;

  /// Moneda de la cuenta; sus saldos vienen en ella.
  final Currency moneda;

  /// `activa` | `bloqueada` | `cerrada`.
  final String estado;

  /// Lo pone el titular; `null` si no le puso. Solo lo ve él.
  final String? nombre;
  final Money saldoDisponible;
  final Money saldoContable;

  /// Copia con otro nombre (`() => null` lo quita) u otros saldos.
  Account copyWith({
    String? Function()? nombre,
    Money? saldoDisponible,
    Money? saldoContable,
  }) => Account(
    id: id,
    numero: numero,
    tipo: tipo,
    moneda: moneda,
    estado: estado,
    nombre: nombre == null ? this.nombre : nombre(),
    saldoDisponible: saldoDisponible ?? this.saldoDisponible,
    saldoContable: saldoContable ?? this.saldoContable,
  );

  /// Los últimos cuatro dígitos precedidos de `••••`. El número completo no
  /// debe pintarse en pantallas de resumen.
  String get numeroMasked {
    final cola = numero.length <= 4
        ? numero
        : numero.substring(numero.length - 4);
    return '••••$cola';
  }
}
