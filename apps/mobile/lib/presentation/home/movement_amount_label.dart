import 'package:core_kernel/core_kernel.dart';

import '../../core/format/money_format.dart';
import '../../feature/account/domain/movement.dart';

/// Monto de una fila de movimientos: `+ S/ 50.00` / `- S/ 50.00`.
///
/// El signo lo pone ESTA función según [Movement.direccion]; al formateador se
/// le pasa siempre el valor absoluto. `formatMoney` ya emite el signo de un
/// monto negativo, así que sin el `abs` un egreso saldría `- -S/ 50.00`.
String movementAmountLabel(Movement movement) {
  final abs = Money(movement.monto.centimos.abs(), movement.monto.currency);
  final signo = switch (movement.direccion) {
    MovementDirection.credito => '+',
    MovementDirection.debito => '-',
  };
  return '$signo ${formatMoney(abs)}';
}
