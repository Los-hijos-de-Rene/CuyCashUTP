import 'package:core_kernel/core_kernel.dart';

import '../domain/movement.dart';

/// Libro mayor en memoria (flavor `mock`): el saldo y los movimientos de la
/// cuenta de demo, UNO solo para toda la app. Lo leen `MemoryAccountRepository`
/// (inicio) y lo escribe `MemoryTransferRepository` (enviar y recargar), así
/// que tras una operación el saldo del inicio cambia como en el backend real.
///
/// Se construye una vez en la composición raíz del flavor `mock` y se inyecta
/// a ambos repositorios. Sin inyección, cada repositorio crea el suyo
/// (comportamiento previo: saldos independientes, útil en tests unitarios).
class MemoryLedger {
  MemoryLedger({DateTime Function()? clock})
    : _movimientos = _sembrar((clock ?? DateTime.now)()),
      _saldo = const Money.fromCentimos(125040);

  static const cuentaId = 'acc-demo-1';
  static const tx1 = 'tx-demo-1';
  static const tx2 = 'tx-demo-2';
  static const tx3 = 'tx-demo-3';

  Money _saldo;
  final List<MovementDetail> _movimientos;

  Money get saldo => _saldo;

  /// Más reciente primero.
  List<MovementDetail> get movimientos => List.unmodifiable(_movimientos);

  /// Aplica una operación al saldo y la pone al principio del historial.
  void registrar({
    required String transactionId,
    required MovementKind tipo,
    required MovementDirection direccion,
    required Money monto,
    required DateTime fecha,
    String? contraparte,
    String? motivo,
    String? cuentaDestinoMasked,
  }) {
    _saldo = direccion == MovementDirection.credito
        ? _saldo + monto
        : _saldo - monto;
    _movimientos.insert(
      0,
      MovementDetail(
        transactionId: transactionId,
        tipo: tipo,
        direccion: direccion,
        monto: monto,
        saldoPosterior: _saldo,
        fecha: fecha.toUtc(),
        estado: 'confirmada',
        contraparte: contraparte,
        motivo: motivo,
        cuentaDestinoMasked: cuentaDestinoMasked,
      ),
    );
  }

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
        // Enmascarada: en un DÉBITO el backend solo da lo que ya dio
        // `/directory/resolve`, porque la operación la eligió quien envía.
        contraparte: 'B*** D*** A***',
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
        // Completa: es un CRÉDITO, y recibir no es algo que uno se provoque.
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
        contraparte: 'M*** L*** C***',
        saldoPosterior: const Money.fromCentimos(9540),
        fecha: a(ayer, 13, 5),
        estado: 'confirmada',
        cuentaDestinoMasked: '••••1908',
      ),
    ];
  }
}
