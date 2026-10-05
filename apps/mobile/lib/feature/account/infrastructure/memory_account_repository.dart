import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/account.dart';
import '../domain/account_failure.dart';
import '../domain/account_repository.dart';
import '../domain/movement.dart';

/// Impl en memoria (flavor `mock`): una cuenta y tres movimientos de demo.
///
/// Los identificadores son ESTABLES y forman parte del contrato de la demo:
/// la pantalla de detalle del movimiento y sus tests se apoyan en ellos.
///
/// - [cuentaId]: `acc-demo-1` (número `19100000004521`, S/ 1,250.40).
/// - [tx1] `tx-demo-1`: Bodega Don Aurelio, débito S/ 45.00, hoy 14:30.
/// - [tx2] `tx-demo-2`: Jenny Marisol Ruiz, crédito S/ 1,200.00, hoy 09:15.
/// - [tx3] `tx-demo-3`: Menú La Cuchara, débito S/ 18.50, ayer 13:05.
///
/// Paginación: igual que el backend, el cursor es opaco y un cursor ilegible
/// empieza por el principio. Aquí es el índice del siguiente movimiento.
/// [pageSize] (20 por defecto, como el backend) existe para poder probar la
/// paginación con solo tres movimientos.
class MemoryAccountRepository implements AccountRepository {
  MemoryAccountRepository({
    DateTime Function()? clock,
    this.pageSize = 20,
  })  : assert(pageSize > 0),
        _movimientos = _sembrar((clock ?? DateTime.now)());

  static const cuentaId = 'acc-demo-1';
  static const tx1 = 'tx-demo-1';
  static const tx2 = 'tx-demo-2';
  static const tx3 = 'tx-demo-3';

  final int pageSize;
  final List<MovementDetail> _movimientos;

  static const _cuenta = Account(
    id: cuentaId,
    numero: '19100000004521',
    tipo: 'ahorro',
    moneda: 'PEN',
    estado: 'activa',
    saldoDisponible: Money.fromCentimos(125040),
    saldoContable: Money.fromCentimos(125040),
  );

  /// Más reciente primero, con saldos encadenados:
  /// 95.40 → (+1,200.00) 1,295.40 → (−45.00) 1,250.40.
  static List<MovementDetail> _sembrar(DateTime ahora) {
    final hoy = ahora.toLocal();
    // Hora local construida y pasada a UTC, como llegaría del servidor.
    DateTime a(DateTime dia, int h, int m) =>
        DateTime(dia.year, dia.month, dia.day, h, m).toUtc();
    final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);

    return [
      MovementDetail(
        transactionId: tx1,
        tipo: MovementKind.transferencia,
        direccion: MovementDirection.debito,
        monto: const Money.fromCentimos(4500),
        contraparte: 'Bodega Don Aurelio',
        saldoPosterior: const Money.fromCentimos(125040),
        fecha: a(hoy, 14, 30),
        estado: 'confirmada',
        cuentaDestinoMasked: '••••7732',
      ),
      MovementDetail(
        transactionId: tx2,
        tipo: MovementKind.transferencia,
        direccion: MovementDirection.credito,
        monto: const Money.fromCentimos(120000),
        contraparte: 'Jenny Marisol Ruiz',
        saldoPosterior: const Money.fromCentimos(129540),
        fecha: a(hoy, 9, 15),
        estado: 'confirmada',
        // Como el backend: el destino de la transferencia, que en un crédito
        // es la cuenta propia.
        cuentaDestinoMasked: '••••4521',
      ),
      MovementDetail(
        transactionId: tx3,
        tipo: MovementKind.transferencia,
        direccion: MovementDirection.debito,
        monto: const Money.fromCentimos(1850),
        contraparte: 'Menú La Cuchara',
        saldoPosterior: const Money.fromCentimos(9540),
        fecha: a(ayer, 13, 5),
        estado: 'confirmada',
        cuentaDestinoMasked: '••••1908',
      ),
    ];
  }

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async =>
      right(const [_cuenta]);

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
    return right(MovementPage(
      items: List.unmodifiable(
        _movimientos.sublist(inicio, hayMas ? fin : _movimientos.length),
      ),
      nextCursor: hayMas ? '$fin' : null,
    ));
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
