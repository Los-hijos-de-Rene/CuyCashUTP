import 'package:core_kernel/core_kernel.dart';

/// Sentido del movimiento respecto a la cuenta consultada.
enum MovementDirection { debito, credito }

/// Clase de operación. Los tipos que el backend añada después (pago QR,
/// cuota…) caen en [otro] en lugar de romper el parseo.
enum MovementKind { transferencia, recarga, otro }

/// Una fila del historial de una cuenta.
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
