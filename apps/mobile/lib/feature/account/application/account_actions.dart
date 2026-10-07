import 'package:core_kernel/core_kernel.dart';

import '../domain/account.dart';
import '../domain/account_failure.dart';
import '../domain/account_limits.dart';
import '../domain/account_repository.dart';
import '../domain/account_type.dart';
import '../domain/movement.dart';

/// Operaciones FINAS de cuentas (delegación directa sobre el
/// `AccountRepository`). El bloc la consume por constructor; nunca toca el
/// repo. Si una operación pasa a orquestar 2+ dependencias, sale a su propio
/// `*_use_case.dart`.
class AccountActions {
  const AccountActions(this._repo);

  final AccountRepository _repo;

  FutureResult<AccountFailure, List<Account>> cuentas() => _repo.cuentas();

  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) => _repo.movimientos(cuentaId, cursor: cursor);

  FutureResult<AccountFailure, MovementPage> todosLosMovimientos({
    String? cursor,
    int? limit,
  }) => _repo.todosLosMovimientos(cursor: cursor, limit: limit);

  FutureResult<AccountFailure, MovementDetail> movimiento(
    String transactionId,
  ) => _repo.movimiento(transactionId);

  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) => _repo.abrir(
    tipo: tipo,
    moneda: moneda,
    nombre: AccountLimits.normalizarNombre(nombre),
    pin: pin,
    idempotencyKey: idempotencyKey,
  );

  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) => _repo.renombrar(cuentaId, AccountLimits.normalizarNombre(nombre));
}
