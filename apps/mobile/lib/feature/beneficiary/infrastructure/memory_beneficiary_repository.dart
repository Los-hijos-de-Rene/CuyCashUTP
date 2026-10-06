import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../transfer/infrastructure/memory_transfer_repository.dart';
import '../domain/beneficiary.dart';
import '../domain/beneficiary_failure.dart';
import '../domain/beneficiary_limits.dart';
import '../domain/beneficiary_repository.dart';

/// Impl en memoria (flavor `mock`). Reproduce `directory.py`:
///
/// - `guardar`: orden idéntico al backend: DNI propio, presupuesto de
///   consultas, destinatario existente. Un apodo vacío o de más de 40
///   caracteres es un 422 (`unexpected`), como el `BeneficiaryIn` real.
/// - Upsert: guardar el mismo DNI dos veces deja UNA fila con el último
///   apodo y conserva su posición (el alta original).
/// - Presupuesto: [consultasMaximas] por [ventana] deslizante, la misma
///   regla que `MemoryTransferRepository`. OJO: aquí es un presupuesto
///   PROPIO; en el backend se comparte con la búsqueda y el envío.
/// - `listar` va del más reciente al más antiguo; `eliminar` es idempotente.
///
/// Clientes conocidos: los de `MemoryTransferRepository`. Titular
/// [dniPropio].
class MemoryBeneficiaryRepository implements BeneficiaryRepository {
  MemoryBeneficiaryRepository({
    required DateTime Function() clock,
    this.consultasMaximas = 20,
    this.ventana = const Duration(minutes: 10),
    this.dniPropio = MemoryTransferRepository.dniPropio,
  }) : _clock = clock;

  final DateTime Function() _clock;
  final int consultasMaximas;
  final Duration ventana;
  final String dniPropio;

  final _consultas = <DateTime>[];
  final _filas = <({String id, String dni, String apodo})>[];
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

  @override
  FutureResult<BeneficiaryFailure, List<Beneficiary>> listar() async => right([
    for (final f in _filas.reversed)
      Beneficiary(
        id: f.id,
        dni: f.dni,
        apodo: f.apodo,
        nombreEnmascarado: MemoryTransferRepository.destinatarioConocido(
          f.dni,
        )?.nombreEnmascarado,
      ),
  ]);

  @override
  FutureResult<BeneficiaryFailure, Unit> guardar(
    String dni,
    String apodo,
  ) async {
    final formatoValido = RegExp(r'^\d{8}$').hasMatch(dni);
    if (!formatoValido ||
        apodo.isEmpty ||
        apodo.length > BeneficiaryLimits.apodoMaxLength) {
      return _falla(const BeneficiaryFailure.unexpected());
    }
    if (dni == dniPropio) {
      return _falla(const BeneficiaryFailure.selfTransfer());
    }
    if (_consumirConsulta() case final f?) return _falla(f);
    if (MemoryTransferRepository.destinatarioConocido(dni) == null) {
      return _falla(const BeneficiaryFailure.recipientNotFound());
    }
    final i = _filas.indexWhere((f) => f.dni == dni);
    if (i >= 0) {
      _filas[i] = (id: _filas[i].id, dni: dni, apodo: apodo);
    } else {
      _filas.add((id: 'ben-mem-${++_secuencia}', dni: dni, apodo: apodo));
    }
    return right(unit);
  }

  @override
  FutureResult<BeneficiaryFailure, Unit> eliminar(String id) async {
    _filas.removeWhere((f) => f.id == id);
    return right(unit);
  }
}
