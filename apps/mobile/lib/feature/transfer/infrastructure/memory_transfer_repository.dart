import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../account/domain/movement.dart';
import '../../account/infrastructure/memory_ledger.dart';
import '../domain/recipient.dart';
import '../domain/transfer_failure.dart';
import '../domain/transfer_receipt.dart';
import '../domain/transfer_repository.dart';

/// Impl en memoria (flavor `mock`). Reproduce las reglas del router real
/// (`services/api/.../transfers.py`) para que la demo no mienta:
///
/// - Orden de validación idéntico: cuenta, destinatario propio, presupuesto de
///   consultas, destinatario existente, monto y, EL ÚLTIMO, el PIN. Los fondos
///   se miran al postear, tras el PIN.
/// - Idempotencia: `idempotencyKey → (huella, constancia)`. La misma clave con
///   la misma huella devuelve la MISMA constancia (`reutilizada: true`) sin
///   volver a mover saldo; con otra huella, `idempotencyKeyReused`. Los
///   intentos fallidos NO guardan la clave.
/// - Bloqueo: [maxIntentos] PIN errados seguidos bloquean por [bloqueo] (el
///   DNI; este mock no distingue el bloqueo de dispositivo). Un PIN correcto
///   reinicia la cuenta de fallos. Mientras dura, ni el PIN correcto entra.
/// - Presupuesto de consultas: [consultasMaximas] por [ventana] deslizante,
///   compartidas entre `resolverDestinatario` y `enviar`, como en el backend.
///
/// Datos de demo (contrato estable): titular [dniPropio] con la cuenta
/// [cuentaId] y S/ 1,250.40, el mismo saldo que `MemoryAccountRepository`
/// (enviar y recargar lo actualizan en el [MemoryLedger] compartido). PIN
/// válido `000000`. Destinatarios conocidos: [dniDestino] y [dniDestino2].
class MemoryTransferRepository implements TransferRepository {
  MemoryTransferRepository({
    required DateTime Function() clock,
    this.maxIntentos = 5,
    this.bloqueo = const Duration(minutes: 15),
    this.consultasMaximas = 20,
    this.ventana = const Duration(minutes: 10),
    MemoryLedger? ledger,
  }) : _clock = clock,
       _ledger = ledger ?? MemoryLedger(clock: clock);

  static const pinValido = '000000';
  static const dniPropio = '70123456';
  static const cuentaId = 'acc-demo-1';
  static const dniDestino = '87654321';
  static const dniDestino2 = '43219876';
  static const montoMinimo = 1;
  static const montoMaximo = 200000;

  static const _destinatarios = <String, Recipient>{
    dniDestino: Recipient(
      dni: dniDestino,
      nombreEnmascarado: 'J*** M*** R***',
      cuentaDestinoMasked: '••••7732',
    ),
    dniDestino2: Recipient(
      dni: dniDestino2,
      nombreEnmascarado: 'C*** A*** N***',
      cuentaDestinoMasked: '••••1908',
    ),
  };

  final DateTime Function() _clock;
  final int maxIntentos;
  final Duration bloqueo;
  final int consultasMaximas;
  final Duration ventana;

  final MemoryLedger _ledger;
  int _fallos = 0;
  DateTime? _bloqueadoHasta;
  final _consultas = <DateTime>[];
  int _secuencia = 0;
  final _operaciones =
      <String, ({String huella, TransferReceipt constancia})>{};

  Result<TransferFailure, T> _falla<T>(TransferFailure f) =>
      left(GlobalFailure.server(f));

  /// Descuenta una consulta de la ventana deslizante o devuelve el failure de
  /// 429 con el tiempo que falta hasta que caduque la marca más antigua.
  TransferFailure? _consumirConsulta() {
    final ahora = _clock();
    _consultas.removeWhere((m) => !m.add(ventana).isAfter(ahora));
    if (_consultas.length >= consultasMaximas) {
      final espera = _consultas.first.add(ventana).difference(ahora);
      return TransferFailure.rateLimited(
        espera.inSeconds < 1 ? const Duration(seconds: 1) : espera,
      );
    }
    _consultas.add(ahora);
    return null;
  }

  @override
  FutureResult<TransferFailure, Recipient> resolverDestinatario(
    String dni,
  ) async {
    if (dni == dniPropio) return _falla(const TransferFailure.selfTransfer());
    if (_consumirConsulta() case final f?) return _falla(f);
    return switch (_destinatarios[dni]) {
      final Recipient r => right(r),
      _ => _falla(const TransferFailure.recipientNotFound()),
    };
  }

  /// Autoriza con el PIN o devuelve el failure. El fallo cuenta; el acierto
  /// reinicia.
  TransferFailure? _exigirPin(String pin) {
    final ahora = _clock();
    if (_bloqueadoHasta case final hasta? when hasta.isAfter(ahora)) {
      return TransferFailure.identifierLocked(hasta);
    }
    if (pin == pinValido) {
      _fallos = 0;
      _bloqueadoHasta = null;
      return null;
    }
    _fallos++;
    if (_fallos >= maxIntentos) {
      final hasta = ahora.toUtc().add(bloqueo);
      _bloqueadoHasta = hasta;
      _fallos = 0;
      return TransferFailure.identifierLocked(hasta);
    }
    return TransferFailure.wrongPin(maxIntentos - _fallos);
  }

  TransferFailure? _validarMonto(Money monto) =>
      monto.centimos < montoMinimo || monto.centimos > montoMaximo
      ? const TransferFailure.amountOutOfRange()
      : null;

  /// Registra la operación o devuelve la original si la clave ya existía.
  Result<TransferFailure, TransferReceipt> _postear({
    required String huella,
    required String idempotencyKey,
    required Money monto,
    required MovementDirection direccion,
    required String? contraparte,
    String? motivo,
    String? cuentaDestinoMasked,
  }) {
    final previa = _operaciones[idempotencyKey];
    if (previa != null) {
      if (previa.huella != huella) {
        return _falla(const TransferFailure.idempotencyKeyReused());
      }
      return right(
        TransferReceipt(
          transactionId: previa.constancia.transactionId,
          monto: previa.constancia.monto,
          fecha: previa.constancia.fecha,
          reutilizada: true,
        ),
      );
    }
    final constancia = TransferReceipt(
      transactionId: 'tx-mem-${++_secuencia}',
      monto: monto,
      fecha: _clock().toUtc(),
    );
    _ledger.registrar(
      transactionId: constancia.transactionId,
      tipo: direccion == MovementDirection.debito
          ? MovementKind.transferencia
          : MovementKind.recarga,
      direccion: direccion,
      monto: monto,
      fecha: constancia.fecha,
      contraparte: contraparte,
      motivo: motivo,
      cuentaDestinoMasked: cuentaDestinoMasked,
    );
    _operaciones[idempotencyKey] = (huella: huella, constancia: constancia);
    return right(constancia);
  }

  @override
  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String destinatarioDni,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  }) async {
    if (cuentaOrigenId != cuentaId) {
      return _falla(const TransferFailure.accountNotFound());
    }
    if (destinatarioDni == dniPropio) {
      return _falla(const TransferFailure.selfTransfer());
    }
    if (_consumirConsulta() case final f?) return _falla(f);
    if (!_destinatarios.containsKey(destinatarioDni)) {
      return _falla(const TransferFailure.recipientNotFound());
    }
    if (_validarMonto(monto) case final f?) return _falla(f);
    if (_exigirPin(pin) case final f?) return _falla(f);

    final nota = (motivo ?? '').trim();
    final huella =
        'transferencia|$cuentaOrigenId|$destinatarioDni|'
        '${monto.centimos}|$nota';
    // Una clave ya registrada no mira el saldo: el backend devuelve la
    // original (o 409 si los datos cambiaron) sin recontar.
    if (!_operaciones.containsKey(idempotencyKey) && _ledger.saldo < monto) {
      return _falla(const TransferFailure.insufficientFunds());
    }
    return _postear(
      huella: huella,
      idempotencyKey: idempotencyKey,
      monto: monto,
      direccion: MovementDirection.debito,
      contraparte: _destinatarios[destinatarioDni]?.nombreEnmascarado,
      motivo: nota.isEmpty ? null : nota,
      cuentaDestinoMasked: _destinatarios[destinatarioDni]?.cuentaDestinoMasked,
    );
  }

  @override
  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String pin,
    required String idempotencyKey,
  }) async {
    if (cuentaId != MemoryTransferRepository.cuentaId) {
      return _falla(const TransferFailure.accountNotFound());
    }
    if (_validarMonto(monto) case final f?) return _falla(f);
    if (_exigirPin(pin) case final f?) return _falla(f);

    return _postear(
      huella: 'recarga|$cuentaId|${monto.centimos}',
      idempotencyKey: idempotencyKey,
      monto: monto,
      direccion: MovementDirection.credito,
      contraparte: 'Recarga de saldo',
    );
  }
}
