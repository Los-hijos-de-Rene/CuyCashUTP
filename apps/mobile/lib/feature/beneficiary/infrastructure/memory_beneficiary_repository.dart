import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../account/infrastructure/memory_ledger.dart';
import '../../transfer/domain/recipient_account.dart';
import '../../transfer/infrastructure/memory_transfer_repository.dart';
import '../domain/beneficiary.dart';
import '../domain/beneficiary_failure.dart';
import '../domain/beneficiary_limits.dart';
import '../domain/beneficiary_repository.dart';

/// Impl en memoria (flavor `mock`). Reproduce `directory.py`:
///
/// - `guardar`: orden idéntico al backend: presupuesto de consultas, cuenta
///   existente (propia o de un tercero). Un apodo vacío o de más de 40
///   caracteres es un 422 (`unexpected`), como el `BeneficiaryIn` real.
/// - Upsert por CUENTA: guardar la misma cuenta dos veces deja UNA fila con
///   el último apodo y conserva su posición (el alta original); dos cuentas
///   de la misma persona son dos frecuentes.
/// - Presupuesto: [consultasMaximas] por [ventana] deslizante, la misma
///   regla que `MemoryTransferRepository`. OJO: aquí es un presupuesto
///   PROPIO; en el backend se comparte con la búsqueda y el envío.
/// - `listar` va del más reciente al más antiguo; `eliminar` es idempotente.
///
/// Cuentas conocidas: las de terceros de `MemoryTransferRepository` y, si hay
/// [ledger], las propias del titular (que se guardan con su nombre).
class MemoryBeneficiaryRepository implements BeneficiaryRepository {
  MemoryBeneficiaryRepository({
    required DateTime Function() clock,
    this.consultasMaximas = 20,
    this.ventana = const Duration(minutes: 10),
    MemoryLedger? ledger,
  }) : _clock = clock,
       _ledger = ledger;

  final DateTime Function() _clock;
  final int consultasMaximas;
  final Duration ventana;
  final MemoryLedger? _ledger;

  final _consultas = <DateTime>[];
  final _filas = <({String id, String cuentaId, String apodo})>[];
  int _secuencia = 0;

  Result<BeneficiaryFailure, T> _falla<T>(BeneficiaryFailure f) =>
      left(GlobalFailure.server(f));

  BeneficiaryFailure? _consumirConsulta() {
    final ahora = _clock();
    _consultas.removeWhere((m) => !m.add(ventana).isAfter(ahora));
    if (_consultas.length >= consultasMaximas) {
      final espera = _consultas.first.add(ventana).difference(ahora);
      return BeneficiaryFailure.rateLimited(
        espera.inSeconds < 1 ? const Duration(seconds: 1) : espera,
      );
    }
    _consultas.add(ahora);
    return null;
  }

  /// La cuenta [id] con su titular: propia (con su nombre) o de un tercero.
  ({String dni, String nombreEnmascarado, RecipientAccount cuenta})? _buscar(
    String id,
  ) {
    if (_ledger?.cuenta(id) case final propia?) {
      return (
        dni: MemoryTransferRepository.dniPropio,
        nombreEnmascarado: MemoryTransferRepository.nombrePropioEnmascarado,
        cuenta: RecipientAccount(
          cuentaId: propia.id,
          tipo: propia.tipo,
          moneda: propia.moneda,
          numeroMasked: propia.numeroMasked,
          nombre: propia.nombre,
        ),
      );
    }
    return MemoryTransferRepository.cuentaConocida(id);
  }

  @override
  FutureResult<BeneficiaryFailure, List<Beneficiary>> listar() async => right([
    for (final f in _filas.reversed)
      Beneficiary(
        id: f.id,
        dni: _buscar(f.cuentaId)?.dni ?? '',
        apodo: f.apodo,
        nombreEnmascarado: _buscar(f.cuentaId)?.nombreEnmascarado,
        cuenta: _buscar(f.cuentaId)?.cuenta,
      ),
  ]);

  @override
  FutureResult<BeneficiaryFailure, Unit> guardar({
    required String cuentaDestinoId,
    required String apodo,
  }) async {
    if (apodo.isEmpty || apodo.length > BeneficiaryLimits.apodoMaxLength) {
      return _falla(const BeneficiaryFailure.unexpected());
    }
    if (_consumirConsulta() case final f?) return _falla(f);
    if (_buscar(cuentaDestinoId) == null) {
      return _falla(const BeneficiaryFailure.recipientNotFound());
    }
    final i = _filas.indexWhere((f) => f.cuentaId == cuentaDestinoId);
    if (i >= 0) {
      _filas[i] = (id: _filas[i].id, cuentaId: cuentaDestinoId, apodo: apodo);
    } else {
      _filas.add((
        id: 'ben-mem-${++_secuencia}',
        cuentaId: cuentaDestinoId,
        apodo: apodo,
      ));
    }
    return right(unit);
  }

  @override
  FutureResult<BeneficiaryFailure, Unit> eliminar(String id) async {
    _filas.removeWhere((f) => f.id == id);
    return right(unit);
  }
}
