import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/account.dart';
import '../domain/account_failure.dart';
import '../domain/account_repository.dart';
import '../domain/movement.dart';
import 'memory_ledger.dart';

/// Impl en memoria (flavor `mock`): una cuenta y tres movimientos de demo,
/// leídos de un [MemoryLedger] (compartido con `MemoryTransferRepository` en
/// la app, para que enviar y recargar muevan el saldo del inicio).
///
/// Los identificadores son ESTABLES y forman parte del contrato de la demo:
/// la pantalla de detalle del movimiento y sus tests se apoyan en ellos.
///
/// - [cuentaId]: `acc-demo-1` (número `19100000004521`, S/ 1,250.40).
/// - [tx1] `tx-demo-1`: `B*** D*** A***`, débito S/ 45.00, hoy 14:30.
/// - [tx2] `tx-demo-2`: Jenny Marisol Ruiz, crédito S/ 1,200.00, hoy 09:15.
/// - [tx3] `tx-demo-3`: `M*** L*** C***`, débito S/ 18.50, ayer 13:05.
///
/// Paginación: igual que el backend, el cursor es opaco y un cursor ilegible
/// empieza por el principio. Aquí es el índice del siguiente movimiento.
/// [pageSize] (20 por defecto, como el backend) existe para poder probar la
/// paginación con solo tres movimientos.
class MemoryAccountRepository implements AccountRepository {
  MemoryAccountRepository({
    DateTime Function()? clock,
    this.pageSize = 20,
    MemoryLedger? ledger,
  })  : assert(pageSize > 0),
        _ledger = ledger ?? MemoryLedger(clock: clock);

  static const cuentaId = MemoryLedger.cuentaId;
  static const tx1 = MemoryLedger.tx1;
  static const tx2 = MemoryLedger.tx2;
  static const tx3 = MemoryLedger.tx3;

  final int pageSize;
  final MemoryLedger _ledger;

  List<MovementDetail> get _movimientos => _ledger.movimientos;

  Account get _cuenta => Account(
    id: cuentaId,
    numero: '19100000004521',
    tipo: 'ahorro',
    moneda: Currency.pen,
    estado: 'activa',
    saldoDisponible: _ledger.saldo,
    saldoContable: _ledger.saldo,
  );

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async =>
      right([_cuenta]);

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async {
    if (cuentaId != _cuenta.id) {
      return left(const GlobalFailure.server(AccountFailure.accountNotFound()));
    }
    final inicio = switch (int.tryParse(cursor ?? '')) {
      final int i when i >= 0 && i < _movimientos.length => i,
      _ => 0,
    };
    final fin = inicio + pageSize;
    final hayMas = fin < _movimientos.length;
    return right(
      MovementPage(
      items: List.unmodifiable(
        _movimientos.sublist(inicio, hayMas ? fin : _movimientos.length),
      ),
      nextCursor: hayMas ? '$fin' : null,
      ),
    );
  }

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(
    String transactionId,
  ) async {
    for (final m in _movimientos) {
      if (m.transactionId == transactionId) return right(m);
    }
    return left(const GlobalFailure.server(AccountFailure.accountNotFound()));
  }
}
