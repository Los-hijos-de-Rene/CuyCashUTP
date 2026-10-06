import 'package:core_kernel/core_kernel.dart';

import '../domain/account.dart';
import '../domain/account_type.dart';
import '../domain/movement.dart';

/// Libro mayor en memoria (flavor `mock`): las cuentas del titular de demo y
/// sus movimientos, UNO solo para toda la app. Lo leen `MemoryAccountRepository`
/// (inicio) y lo escribe `MemoryTransferRepository` (enviar y recargar), así
/// que tras una operación el saldo del inicio cambia como en el backend real.
///
/// Se construye una vez en la composición raíz del flavor `mock` y se inyecta
/// a ambos repositorios. Sin inyección, cada repositorio crea el suyo
/// (comportamiento previo: saldos independientes, útil en tests unitarios).
class MemoryLedger {
  MemoryLedger({DateTime Function()? clock})
    : _filas = _sembrar((clock ?? DateTime.now)());

  static const cuentaId = 'acc-demo-1';
  static const cuentaSueldoId = 'acc-demo-2';
  static const cuentaDolaresId = 'acc-demo-3';
  static const tx1 = 'tx-demo-1';
  static const tx2 = 'tx-demo-2';
  static const tx3 = 'tx-demo-3';

  final List<_Fila> _filas;
  int _abiertas = 0;

  List<Account> get cuentas => [for (final f in _filas) f.cuenta];

  Account? cuenta(String id) => _fila(id)?.cuenta;

  /// Saldo de [id]; `StateError` si no existe (quien llama ya lo validó).
  Money saldoDe(String id) => _existente(id).cuenta.saldoDisponible;

  _Fila _existente(String id) => switch (_fila(id)) {
    final _Fila f => f,
    null => throw StateError('Cuenta desconocida en el libro: $id'),
  };

  /// Más reciente primero; vacía si la cuenta no existe.
  List<MovementDetail> movimientosDe(String id) =>
      List.unmodifiable(_fila(id)?.movimientos ?? const []);

  _Fila? _fila(String id) {
    for (final f in _filas) {
      if (f.cuenta.id == id) return f;
    }
    return null;
  }

  /// Aplica una operación al saldo de [cuentaId] y la pone al principio de su
  /// historial.
  void registrar({
    required String cuentaId,
    required String transactionId,
    required MovementKind tipo,
    required MovementDirection direccion,
    required Money monto,
    required DateTime fecha,
    String? contraparte,
    String? motivo,
    String? cuentaDestinoMasked,
  }) {
    final f = _existente(cuentaId);
    final saldo = direccion == MovementDirection.credito
        ? f.cuenta.saldoDisponible + monto
        : f.cuenta.saldoDisponible - monto;
    f.cuenta = f.cuenta.copyWith(saldoDisponible: saldo, saldoContable: saldo);
    f.movimientos.insert(
      0,
      MovementDetail(
        transactionId: transactionId,
        tipo: tipo,
        direccion: direccion,
        monto: monto,
        saldoPosterior: saldo,
        fecha: fecha.toUtc(),
        estado: 'confirmada',
        contraparte: contraparte,
        motivo: motivo,
        cuentaDestinoMasked: cuentaDestinoMasked,
      ),
    );
  }

  /// Abre una cuenta en cero. Las reglas (tope, sueldo única) las aplica el
  /// repositorio, como el router en el backend.
  Account abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
  }) {
    final n = ++_abiertas;
    final cuenta = Account(
      id: 'acc-mem-$n',
      numero: '1910000000${(9000 + n).toString().padLeft(4, '0')}',
      tipo: tipo,
      moneda: moneda,
      estado: 'activa',
      nombre: nombre,
      saldoDisponible: Money.zero(moneda),
      saldoContable: Money.zero(moneda),
    );
    _filas.add(_Fila(cuenta));
    return cuenta;
  }

  /// `null` si [id] no existe.
  Account? renombrar(String id, String? nombre) {
    final f = _fila(id);
    if (f == null) return null;
    f.cuenta = f.cuenta.copyWith(nombre: () => nombre);
    return f.cuenta;
  }

  /// Primera cuenta: movimientos más reciente primero, con saldos
  /// encadenados: 95.40 → (+1,200.00) 1,295.40 → (−45.00) 1,250.40.
  static List<_Fila> _sembrar(DateTime ahora) {
    final hoy = ahora.toLocal();
    // Hora local construida y pasada a UTC, como llegaría del servidor.
    DateTime a(DateTime dia, int h, int m) =>
        DateTime(dia.year, dia.month, dia.day, h, m).toUtc();
    final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);

    return [
      _Fila(
        const Account(
          id: cuentaId,
          numero: '19100000004521',
          tipo: AccountType.ahorro,
          moneda: Currency.pen,
          estado: 'activa',
          saldoDisponible: Money.soles(125040),
          saldoContable: Money.soles(125040),
        ),
        [
          MovementDetail(
            transactionId: tx1,
            tipo: MovementKind.transferencia,
            direccion: MovementDirection.debito,
            monto: const Money.soles(4500),
            // Enmascarada: en un DÉBITO el backend solo da lo que ya dio
            // `/directory/resolve`, porque la operación la eligió quien envía.
            contraparte: 'B*** D*** A***',
            saldoPosterior: const Money.soles(125040),
            fecha: a(hoy, 14, 30),
            estado: 'confirmada',
            cuentaDestinoMasked: '••••7732',
          ),
          MovementDetail(
            transactionId: tx2,
            tipo: MovementKind.transferencia,
            direccion: MovementDirection.credito,
            monto: const Money.soles(120000),
            // Completa: es un CRÉDITO, y recibir no es algo que uno se provoque.
            contraparte: 'Jenny Marisol Ruiz',
            saldoPosterior: const Money.soles(129540),
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
            monto: const Money.soles(1850),
            contraparte: 'M*** L*** C***',
            saldoPosterior: const Money.soles(9540),
            fecha: a(ayer, 13, 5),
            estado: 'confirmada',
            cuentaDestinoMasked: '••••1908',
          ),
        ],
      ),
      _Fila(
        const Account(
          id: cuentaSueldoId,
          numero: '19100000008830',
          tipo: AccountType.sueldo,
          moneda: Currency.pen,
          estado: 'activa',
          saldoDisponible: Money.soles(350000),
          saldoContable: Money.soles(350000),
        ),
      ),
      _Fila(
        const Account(
          id: cuentaDolaresId,
          numero: '19100000002207',
          tipo: AccountType.ahorro,
          moneda: Currency.usd,
          estado: 'activa',
          saldoDisponible: Money.dolares(12000),
          saldoContable: Money.dolares(12000),
        ),
      ),
    ];
  }
}

class _Fila {
  _Fila(this.cuenta, [List<MovementDetail>? movimientos])
    : movimientos = movimientos ?? [];

  Account cuenta;
  final List<MovementDetail> movimientos;
}
