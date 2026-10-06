import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/presentation/home/movement_amount_label.dart';
import 'package:flutter_test/flutter_test.dart';

Movement _mov(MovementDirection d, int centimos) => Movement(
  transactionId: 't',
  tipo: MovementKind.transferencia,
  direccion: d,
  monto: Money.soles(centimos),
  saldoPosterior: Money.zero(Currency.pen),
  fecha: DateTime.utc(2026, 1, 1),
);

void main() {
  // El signo lo pone la UI según la dirección y formatSoles recibe el valor
  // absoluto; si no, un egreso saldría "- -S/ 50.00".
  test('un crédito se ve "+ S/ 50.00"', () {
    expect(
      movementAmountLabel(_mov(MovementDirection.credito, 5000)),
      '+ S/ 50.00',
    );
  });

  test('un débito se ve "- S/ 50.00"', () {
    expect(
      movementAmountLabel(_mov(MovementDirection.debito, 5000)),
      '- S/ 50.00',
    );
  });

  test('un monto con signo no duplica el signo', () {
    final label = movementAmountLabel(_mov(MovementDirection.debito, -5000));
    expect(label, '- S/ 50.00');
    expect(label, isNot(contains('- -')));
    expect(label, isNot(contains('-S/')));
  });
}
