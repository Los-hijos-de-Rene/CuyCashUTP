import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/linked_device.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';

/// Operaciones finas de seguridad. Lo que orquesta más de una dependencia
/// (huella + repo + almacén) vive en su `*_use_case.dart`.
class SecurityActions {
  const SecurityActions(this._repo);

  final SecurityRepository _repo;

  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) => _repo.changePin(current: current, nuevo: nuevo);

  FutureResult<SecurityFailure, List<LinkedDevice>> devices() =>
      _repo.devices();

  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) =>
      _repo.unlinkDevice(id);

  FutureResult<SecurityFailure, String> enrollBiometric(String pin) =>
      _repo.enrollBiometric(pin);

  FutureResult<SecurityFailure, Unit> revokeBiometric() =>
      _repo.revokeBiometric();
}
