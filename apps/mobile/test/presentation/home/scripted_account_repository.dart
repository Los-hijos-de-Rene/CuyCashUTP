import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:fpdart/fpdart.dart';

/// Envuelve un repositorio real para los tests de blocs: cuenta las páginas
/// pedidas, puede fallar a pedido, tarda en las páginas con cursor y puede
/// retener `renombrar` hasta [liberarRenombrar].
class ScriptedAccountRepository implements AccountRepository {
  ScriptedAccountRepository(
    this._inner, {
    this.latenciaConCursor = Duration.zero,
    this.latencia = Duration.zero,
    this.renombrarLento = false,
  });

  final AccountRepository _inner;
  final Duration latenciaConCursor;

  /// Para toda página: como la red, tarda más que una ráfaga de eventos.
  final Duration latencia;
  final bool renombrarLento;
  final liberarRenombrar = Completer<void>();

  bool falla = false;
  int paginas = 0;

  /// Los `limit` con que se pidió el historial combinado.
  final limites = <int?>[];

  Result<AccountFailure, T> _red<T>() =>
      left(const GlobalFailure.server(AccountFailure.network()));

  Future<void> _esperar(String? cursor) async {
    await Future<void>.delayed(latencia);
    if (cursor != null) await Future<void>.delayed(latenciaConCursor);
  }

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async =>
      falla ? _red() : _inner.cuentas();

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async {
    paginas++;
    await _esperar(cursor);
    return falla ? _red() : _inner.movimientos(cuentaId, cursor: cursor);
  }

  @override
  FutureResult<AccountFailure, MovementPage> todosLosMovimientos({
    String? cursor,
    int? limit,
  }) async {
    paginas++;
    limites.add(limit);
    await _esperar(cursor);
    return falla
        ? _red()
        : _inner.todosLosMovimientos(cursor: cursor, limit: limit);
  }

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(String id) =>
      _inner.movimiento(id);

  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) => _inner.abrir(
    tipo: tipo,
    moneda: moneda,
    nombre: nombre,
    pin: pin,
    idempotencyKey: idempotencyKey,
  );

  @override
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) async {
    if (renombrarLento) await liberarRenombrar.future;
    return _inner.renombrar(cuentaId, nombre);
  }
}
