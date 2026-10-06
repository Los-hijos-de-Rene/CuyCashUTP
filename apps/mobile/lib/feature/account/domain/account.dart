import 'package:core_kernel/core_kernel.dart';

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
    required this.saldoDisponible,
    required this.saldoContable,
  });

  final String id;
  final String numero;

  /// `ahorro` | `corriente`.
  final String tipo;

  /// Código ISO, hoy solo `PEN`.
  final String moneda;

  /// `activa` | `bloqueada` | `cerrada`.
  final String estado;
  final Money saldoDisponible;
  final Money saldoContable;

  /// Los últimos cuatro dígitos precedidos de `••••`. El número completo no
  /// debe pintarse en pantallas de resumen.
  String get numeroMasked {
    final cola = numero.length <= 4 ? numero : numero.substring(numero.length - 4);
    return '••••$cola';
  }
}
