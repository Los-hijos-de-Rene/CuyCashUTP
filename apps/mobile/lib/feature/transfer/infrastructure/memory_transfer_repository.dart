import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../account/domain/account_type.dart';
import '../../account/domain/movement.dart';
import '../../account/infrastructure/memory_ledger.dart';
import '../../lockout/domain/lockout_policy.dart';
import '../domain/recipient_account.dart';
import '../domain/recipient_directory.dart';
import '../domain/recipient_query.dart';
import '../domain/transfer_failure.dart';
import '../domain/transfer_receipt.dart';
import '../domain/transfer_repository.dart';

/// Impl en memoria (flavor `mock`). Reproduce las reglas del router real
/// (`services/api/.../transfers.py`) para que la demo no mienta:
///
/// - Orden de validación idéntico: cuenta de origen, misma cuenta
///   (`sameAccount`), presupuesto de consultas, cuenta destino existente,
///   misma moneda (`currencyMismatch`), monto y, EL ÚLTIMO, el PIN. Los fondos
///   se miran al postear, tras el PIN. Un REINTENTO (clave ya registrada) no
///   vuelve a buscar el destino ni gasta presupuesto; si la clave era de un
///   envío a OTRA cuenta responde `idempotencyKeyReused` antes del PIN.
/// - Idempotencia: `idempotencyKey → (huella, constancia)`. La misma clave con
///   la misma huella devuelve la MISMA constancia (`reutilizada: true`) sin
///   volver a mover saldo; con otra huella, `idempotencyKeyReused`. Los
///   intentos fallidos NO guardan la clave.
/// - Moneda: un [Money] en otra moneda que la de la cuenta de origen (o de la
///   recargada) es `currencyMismatch`. El backend no puede recibirlo (manda
///   céntimos sin moneda); aquí se rechaza para no comparar monedas distintas
///   en el libro, que lanzaría.
/// - Bloqueo: [maxIntentos] PIN errados seguidos bloquean por [bloqueo] (el
///   DNI; este mock no distingue el bloqueo de dispositivo). Un PIN correcto
///   reinicia la cuenta de fallos. Mientras dura, ni el PIN correcto entra.
/// - Presupuesto de consultas: [consultasMaximas] por [ventana] deslizante,
///   compartidas entre `resolverDestinatario` y `enviar`, como en el backend.
///
/// Datos de demo (contrato estable): titular [dniPropio] con las cuentas del
/// [MemoryLedger] compartido ([cuentaId] con S/ 1,250.40, la de sueldo en
/// soles y una de ahorros en dólares); enviar y recargar las actualizan, y
/// entre cuentas propias el dinero también se acredita en la de destino. PIN
/// válido `000000`. Terceros: [dniDestino] con [cuentaDestinoId] (ahorros
/// S/), [cuentaDestinoCorrienteId] (corriente S/) y [cuentaDestinoDolaresId]
/// (ahorros US$); [dniDestino2] con [cuentaDestino2Id] (ahorros S/). Cada
/// persona se encuentra también por su alias ([aliasPropio], [aliasDestino],
/// [aliasDestino2]).
class MemoryTransferRepository implements TransferRepository {
  MemoryTransferRepository({
    required DateTime Function() clock,
    // El MISMO número que el backend (`IDENTIFIER_MAX_ATTEMPTS`) y que el
    // resto de la app: el PIN de un movimiento alimenta el bloqueo del login,
    // así que no puede haber dos cuentas de intentos distintas. Con 5 aquí, la
    // demo prometía "te quedan 4" donde producción dice "te quedan 2".
    this.maxIntentos = LockoutPolicy.maxAttempts,
    this.bloqueo = const Duration(minutes: 15),
    this.consultasMaximas = 20,
    this.ventana = const Duration(minutes: 10),
    MemoryLedger? ledger,
  }) : _clock = clock,
       _ledger = ledger ?? MemoryLedger(clock: clock);

  static const pinValido = '000000';
  static const dniPropio = '70123456';
  static const aliasPropio = '@jheampierre';
  static const nombrePropioEnmascarado = 'T*** C***';
  static const cuentaId = MemoryLedger.cuentaId;
  static const dniDestino = '87654321';
  static const dniDestino2 = '43219876';
  static const aliasDestino = '@jmrosa';
  static const aliasDestino2 = '@carlos';
  static const cuentaDestinoId = 'acc-ext-1';
  static const cuentaDestinoCorrienteId = 'acc-ext-2';
  static const cuentaDestinoDolaresId = 'acc-ext-3';
  static const cuentaDestino2Id = 'acc-ext-4';
  static const montoMinimo = 1;
  static const montoMaximo = 200000;

  /// Padrón de terceros de la demo: por DNI, su alias, su nombre y sus
  /// cuentas.
  static const _directorio = <String, RecipientDirectory>{
    dniDestino: RecipientDirectory(
      alias: aliasDestino,
      nombreEnmascarado: 'J*** M*** R***',
      cuentas: [
        RecipientAccount(
          cuentaId: cuentaDestinoId,
          tipo: AccountType.ahorro,
          moneda: Currency.pen,
          numeroMasked: '••••7732',
        ),
        RecipientAccount(
          cuentaId: cuentaDestinoCorrienteId,
          tipo: AccountType.corriente,
          moneda: Currency.pen,
          numeroMasked: '••••5510',
        ),
        RecipientAccount(
          cuentaId: cuentaDestinoDolaresId,
          tipo: AccountType.ahorro,
          moneda: Currency.usd,
          numeroMasked: '••••0419',
        ),
      ],
    ),
    dniDestino2: RecipientDirectory(
      alias: aliasDestino2,
      nombreEnmascarado: 'C*** A*** N***',
      cuentas: [
        RecipientAccount(
          cuentaId: cuentaDestino2Id,
          tipo: AccountType.ahorro,
          moneda: Currency.pen,
          numeroMasked: '••••1908',
        ),
      ],
    ),
  };

  /// Una cuenta de un TERCERO de la demo por su id, con su titular; `null` si
  /// no existe. La usan los frecuentes en memoria.
  static ({String dni, String nombreEnmascarado, RecipientAccount cuenta})?
  cuentaConocida(String cuentaId) {
    for (final MapEntry(key: dni, value: d) in _directorio.entries) {
      for (final c in d.cuentas) {
        if (c.cuentaId == cuentaId) {
          return (dni: dni, nombreEnmascarado: d.nombreEnmascarado, cuenta: c);
        }
      }
    }
    return null;
  }

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

  /// `destino` es la cuenta destino de un envío (`null` en una recarga).
  final _operaciones =
      <
        String,
        ({String huella, String? destino, TransferReceipt constancia})
      >{};

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

  /// El directorio del propio titular sale del libro: sus cuentas, con nombre.
  RecipientDirectory get _propio => RecipientDirectory(
    alias: aliasPropio,
    nombreEnmascarado: nombrePropioEnmascarado,
    cuentas: [
      for (final c in _ledger.cuentas)
        RecipientAccount(
          cuentaId: c.id,
          tipo: c.tipo,
          moneda: c.moneda,
          numeroMasked: c.numeroMasked,
          nombre: c.nombre,
        ),
    ],
  );

  /// Cuenta destino por id: propia (del libro) o de un tercero.
  RecipientAccount? _destino(String cuentaId) {
    for (final c in _propio.cuentas) {
      if (c.cuentaId == cuentaId) return c;
    }
    return cuentaConocida(cuentaId)?.cuenta;
  }

  @override
  FutureResult<TransferFailure, RecipientDirectory> resolverDestinatario(
    String consulta,
  ) async {
    final query = RecipientQuery.parse(consulta);
    // Como el backend: lo malformado no gasta cupo.
    if (query == null) return _falla(const TransferFailure.recipientNotFound());
    if (_consumirConsulta() case final f?) return _falla(f);
    final encontrado = switch (query) {
      DniQuery(:final dni) => dni == dniPropio ? _propio : _directorio[dni],
      AliasQuery(:final alias) =>
        alias == aliasPropio
            ? _propio
            : _directorio.values.where((d) => d.alias == alias).firstOrNull,
    };
    return switch (encontrado) {
      final RecipientDirectory d => right(d),
      null => _falla(const TransferFailure.recipientNotFound()),
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
    required String cuentaId,
    required String huella,
    required String idempotencyKey,
    required Money monto,
    required MovementDirection direccion,
    required String? contraparte,
    String? destino,
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
      cuentaId: cuentaId,
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
    _operaciones[idempotencyKey] = (
      huella: huella,
      destino: destino,
      constancia: constancia,
    );
    return right(constancia);
  }

  @override
  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String cuentaDestinoId,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  }) async {
    final origen = _ledger.cuenta(cuentaOrigenId);
    if (origen == null) return _falla(const TransferFailure.accountNotFound());
    if (cuentaDestinoId == cuentaOrigenId) {
      return _falla(const TransferFailure.sameAccount());
    }
    // Un monto en otra moneda que la del origen no se puede comparar con su
    // saldo: se rechaza aquí, nunca como un StateError del libro.
    if (monto.currency != origen.moneda) {
      return _falla(const TransferFailure.currencyMismatch());
    }
    final nota = (motivo ?? '').trim();
    final huella =
        'transferencia|$cuentaOrigenId|$cuentaDestinoId|'
        '${monto.centimos}|$nota';
    final previa = _operaciones[idempotencyKey];
    final reintento = previa != null;
    final destino = _destino(cuentaDestinoId);
    if (reintento) {
      // Un reintento no vuelve a buscar el destino ni gasta presupuesto. La
      // clave de un envío a OTRA cuenta es 409 antes del PIN, como en el
      // backend: devolver la original haría creer que fue a la elegida.
      if (previa.destino != cuentaDestinoId) {
        return _falla(const TransferFailure.idempotencyKeyReused());
      }
    } else {
      if (_consumirConsulta() case final f?) return _falla(f);
      if (destino == null) {
        return _falla(const TransferFailure.recipientNotFound());
      }
      if (destino.moneda != origen.moneda) {
        return _falla(const TransferFailure.currencyMismatch());
      }
    }
    if (_validarMonto(monto) case final f?) return _falla(f);
    if (_exigirPin(pin) case final f?) return _falla(f);
    // Una clave ya registrada no mira el saldo: el backend devuelve la
    // original (o 409 si los datos cambiaron) sin recontar.
    if (!reintento && _ledger.saldoDe(cuentaOrigenId) < monto) {
      return _falla(const TransferFailure.insufficientFunds());
    }
    final esPropia = _ledger.cuenta(cuentaDestinoId) != null;
    final r = _postear(
      cuentaId: cuentaOrigenId,
      huella: huella,
      idempotencyKey: idempotencyKey,
      monto: monto,
      direccion: MovementDirection.debito,
      contraparte: esPropia
          ? nombrePropioEnmascarado
          : cuentaConocida(cuentaDestinoId)?.nombreEnmascarado,
      destino: cuentaDestinoId,
      motivo: nota.isEmpty ? null : nota,
      cuentaDestinoMasked: destino?.numeroMasked,
    );
    // Entre cuentas propias el dinero también LLEGA: se acredita en el libro.
    if (r case Right(value: final constancia) when esPropia && !reintento) {
      _ledger.registrar(
        cuentaId: cuentaDestinoId,
        transactionId: constancia.transactionId,
        tipo: MovementKind.transferencia,
        direccion: MovementDirection.credito,
        monto: monto,
        fecha: constancia.fecha,
        contraparte: nombrePropioEnmascarado,
        motivo: nota.isEmpty ? null : nota,
        cuentaDestinoMasked: destino?.numeroMasked,
      );
    }
    return r;
  }

  @override
  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String idempotencyKey,
  }) async {
    final cuenta = _ledger.cuenta(cuentaId);
    if (cuenta == null) return _falla(const TransferFailure.accountNotFound());
    if (monto.currency != cuenta.moneda) {
      return _falla(const TransferFailure.currencyMismatch());
    }
    if (_validarMonto(monto) case final f?) return _falla(f);

    return _postear(
      cuentaId: cuentaId,
      huella: 'recarga|$cuentaId|${monto.centimos}',
      idempotencyKey: idempotencyKey,
      monto: monto,
      direccion: MovementDirection.credito,
      contraparte: 'Depósito simulado',
    );
  }
}
