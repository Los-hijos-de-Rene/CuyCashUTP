import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/account.dart';
import '../domain/account_failure.dart';
import '../domain/account_limits.dart';
import '../domain/account_repository.dart';
import '../domain/account_type.dart';
import '../domain/movement.dart';
import '../../lockout/domain/lockout_policy.dart';
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
///
/// Abrir cuenta aplica las reglas del backend con PIN `000000`
/// ([pinValido]). Este mock cuenta los PIN errados ([maxIntentosPin]) pero NO
/// bloquea por tiempo (el de transferencias sí): basta porque abrir una cuenta
/// no mueve dinero.
class MemoryAccountRepository implements AccountRepository {
  MemoryAccountRepository({
    DateTime Function()? clock,
    this.pageSize = 20,
    MemoryLedger? ledger,
    this.maxIntentosPin = LockoutPolicy.maxAttempts,
  }) : assert(pageSize > 0),
       _ledger = ledger ?? MemoryLedger(clock: clock);

  static const cuentaId = MemoryLedger.cuentaId;
  static const tx1 = MemoryLedger.tx1;
  static const tx2 = MemoryLedger.tx2;
  static const tx3 = MemoryLedger.tx3;

  static const pinValido = '000000';

  final int pageSize;
  final int maxIntentosPin;
  final MemoryLedger _ledger;
  int _fallosPin = 0;
  final _aperturas = <String, ({String huella, Account cuenta})>{};

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async =>
      right(_ledger.cuentas);

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async {
    if (_ledger.cuenta(cuentaId) == null) {
      return left(const GlobalFailure.server(AccountFailure.accountNotFound()));
    }
    return right(_pagina(_ledger.movimientosDe(cuentaId), cursor, pageSize));
  }

  @override
  FutureResult<AccountFailure, MovementPage> todosLosMovimientos({
    String? cursor,
    int? limit,
  }) async =>
      right(_pagina(_ledger.todosLosMovimientos(), cursor, limit ?? pageSize));

  /// Cursor = índice del siguiente; uno ilegible empieza por el principio.
  static MovementPage _pagina(
    List<Movement> todos,
    String? cursor,
    int tamano,
  ) {
    final inicio = switch (int.tryParse(cursor ?? '')) {
      final int i when i >= 0 && i < todos.length => i,
      _ => 0,
    };
    final fin = inicio + tamano;
    final hayMas = fin < todos.length;
    return MovementPage(
      items: List.unmodifiable(
        todos.sublist(inicio, hayMas ? fin : todos.length),
      ),
      nextCursor: hayMas ? '$fin' : null,
    );
  }

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(
    String transactionId,
  ) async {
    for (final c in _ledger.cuentas) {
      for (final m in _ledger.movimientosDe(c.id)) {
        if (m.transactionId == transactionId) return right(m);
      }
    }
    return left(const GlobalFailure.server(AccountFailure.accountNotFound()));
  }

  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) async {
    // Mismo orden que el router: nombre, reintento, reglas, PIN al final.
    if (nombre != null && nombre.length > AccountLimits.nombreMaxLength) {
      return _falla(const AccountFailure.invalidName());
    }
    final huella = '${tipo.code}|${moneda.code}|${nombre ?? ''}';
    if (_aperturas[idempotencyKey] case final previa?) {
      return previa.huella == huella
          ? right(_ledger.cuenta(previa.cuenta.id) ?? previa.cuenta)
          : _falla(const AccountFailure.idempotencyKeyReused());
    }
    if (tipo == AccountType.sueldo && moneda != Currency.pen) {
      return _falla(const AccountFailure.invalidCurrency());
    }
    final actuales = _ledger.cuentas;
    if (actuales.length >= AccountLimits.maxCuentas) {
      return _falla(const AccountFailure.limitReached());
    }
    if (tipo == AccountType.sueldo &&
        actuales.any((c) => c.tipo == AccountType.sueldo)) {
      return _falla(const AccountFailure.salaryAccountExists());
    }
    if (pin != pinValido) {
      _fallosPin++;
      return _falla(AccountFailure.wrongPin(maxIntentosPin - _fallosPin));
    }
    _fallosPin = 0;
    final cuenta = _ledger.abrir(tipo: tipo, moneda: moneda, nombre: nombre);
    _aperturas[idempotencyKey] = (huella: huella, cuenta: cuenta);
    return right(cuenta);
  }

  @override
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) async {
    if (nombre != null && nombre.length > AccountLimits.nombreMaxLength) {
      return _falla(const AccountFailure.invalidName());
    }
    return switch (_ledger.renombrar(cuentaId, nombre)) {
      final Account c => right(c),
      null => _falla(const AccountFailure.accountNotFound()),
    };
  }

  Result<AccountFailure, T> _falla<T>(AccountFailure f) =>
      left(GlobalFailure.server(f));
}
