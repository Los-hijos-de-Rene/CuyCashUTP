import 'package:core_kernel/core_kernel.dart';

import 'account_type.dart';

/// Sentido del movimiento respecto a la cuenta consultada.
enum MovementDirection { debito, credito }

/// Clase de operación. Los tipos que el backend añada después (pago QR,
/// cuota…) caen en [otro] en lugar de romper el parseo.
enum MovementKind { transferencia, recarga, otro }

/// La cuenta propia a la que pertenece una fila del historial combinado: lo
/// justo para nombrarla ("Ahorros · ••••4521"). El número llega enmascarado.
class MovementAccountRef {
  const MovementAccountRef({
    required this.id,
    required this.tipo,
    required this.moneda,
    required this.numeroMasked,
    this.nombre,
  });

  final String id;
  final AccountType tipo;
  final Currency moneda;
  final String numeroMasked;
  final String? nombre;
}

/// Una fila del historial de una cuenta o del historial combinado.
class Movement {
  const Movement({
    required this.transactionId,
    required this.tipo,
    required this.direccion,
    required this.monto,
    required this.saldoPosterior,
    required this.fecha,
    this.contraparte,
    this.motivo,
    this.cuenta,
    this.cuentaDestino,
  });

  final String transactionId;
  final MovementKind tipo;
  final MovementDirection direccion;

  /// SIEMPRE positivo: el signo lo da [direccion].
  final Money monto;

  /// Nombre completo del otro extremo; `Recarga de saldo` en recargas.
  final String? contraparte;
  final String? motivo;
  final Money saldoPosterior;

  /// Instante en UTC (`isUtc == true`). Para mostrarlo, convertir con
  /// `toLocal()` en la capa de presentación.
  final DateTime fecha;

  /// De qué cuenta propia es. Solo en el historial combinado; en el de una
  /// cuenta es `null` porque ya se sabe.
  final MovementAccountRef? cuenta;

  /// La cuenta propia que RECIBIÓ, si es una transferencia entre cuentas del
  /// titular. Solo en el historial combinado, donde esa operación sale una
  /// vez (por su débito) en vez de dos.
  final MovementAccountRef? cuentaDestino;

  /// Transferencia entre cuentas propias (solo se sabe en el combinado).
  bool get entrePropias => cuentaDestino != null;
}

/// La ficha de un movimiento (constancia).
class MovementDetail extends Movement {
  const MovementDetail({
    required super.transactionId,
    required super.tipo,
    required super.direccion,
    required super.monto,
    required super.saldoPosterior,
    required super.fecha,
    required this.estado,
    super.contraparte,
    super.motivo,
    this.cuentaDestinoMasked,
  });

  /// `pendiente` | `confirmada` | `revertida`.
  final String estado;

  /// `••••NNNN` de la cuenta destino; solo existe en transferencias.
  final String? cuentaDestinoMasked;
}

/// Una página del historial, de la más reciente a la más antigua.
class MovementPage {
  const MovementPage({required this.items, this.nextCursor});

  final List<Movement> items;

  /// Opaco: se devuelve tal cual en la siguiente llamada. `null` = no hay más.
  final String? nextCursor;
}
