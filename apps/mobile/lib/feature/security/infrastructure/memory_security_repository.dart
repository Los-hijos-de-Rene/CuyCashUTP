import 'dart:math';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../auth/domain/pin_rules.dart';
import '../domain/linked_device.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';
import 'memory_security_state.dart';

/// Impl en memoria (flavor `mock`). Mismas reglas que `services/api`: el PIN
/// errado descuenta intentos y al agotarlos bloquea 15 min; cambiar el PIN
/// revoca las huellas de los otros teléfonos.
class MemorySecurityRepository implements SecurityRepository {
  MemorySecurityRepository(this._s, {required DateTime Function() clock})
    : _clock = clock;

  final MemorySecurityState _s;
  final DateTime Function() _clock;

  static const _bloqueo = Duration(minutes: 15);

  GlobalFailure<SecurityFailure>? _verificar(String pin) {
    final hasta = _s.lockedUntil;
    if (hasta != null && _clock().isBefore(hasta)) {
      return GlobalFailure.server(SecurityFailure.locked(hasta));
    }
    if (pin == _s.pin) {
      _s.attemptsLeft = MemorySecurityState.maxAttempts;
      return null;
    }
    _s.attemptsLeft--;
    if (_s.attemptsLeft <= 0) {
      final nuevo = _clock().add(_bloqueo);
      _s.lockedUntil = nuevo;
      _s.attemptsLeft = MemorySecurityState.maxAttempts;
      return GlobalFailure.server(SecurityFailure.locked(nuevo));
    }
    return GlobalFailure.server(SecurityFailure.wrongPin(_s.attemptsLeft));
  }

  @override
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) async {
    if (_verificar(current) case final f?) return left(f);
    // "Igual al actual" va antes que "débil": el PIN demo ('000000') es débil
    // y aun así pedir el mismo debe decir que no cambió.
    if (nuevo == _s.pin) {
      return left(const GlobalFailure.server(SecurityFailure.pinUnchanged()));
    }
    if (!PinRules.isValid(nuevo)) {
      return left(const GlobalFailure.server(SecurityFailure.weakPin()));
    }
    _s.pin = nuevo;
    _s.credentials.removeWhere((_, device) => device != _s.thisDeviceId);
    return right(_s.devices.where((d) => !d.esEste).length);
  }

  @override
  FutureResult<SecurityFailure, List<LinkedDevice>> devices() async {
    final conHuella = _s.credentials.values.toSet();
    return right([
      for (final d in _s.devices)
        d.copyWith(conHuella: conHuella.contains(d.id)),
    ]);
  }

  @override
  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) async {
    final i = _s.devices.indexWhere((d) => d.id == id);
    if (i < 0) {
      return left(const GlobalFailure.server(SecurityFailure.deviceNotFound()));
    }
    if (_s.devices[i].esEste) {
      return left(
        const GlobalFailure.server(SecurityFailure.cannotUnlinkCurrent()),
      );
    }
    _s.devices.removeAt(i);
    _s.credentials.removeWhere((_, device) => device == id);
    return right(unit);
  }

  @override
  FutureResult<SecurityFailure, String> enrollBiometric(String pin) async {
    if (_verificar(pin) case final f?) return left(f);
    _s.credentials.removeWhere((_, device) => device == _s.thisDeviceId);
    final random = Random.secure();
    final secreto = List.generate(
      32,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _s.credentials[secreto] = _s.thisDeviceId;
    return right(secreto);
  }

  @override
  FutureResult<SecurityFailure, Unit> revokeBiometric() async {
    _s.credentials.removeWhere((_, device) => device == _s.thisDeviceId);
    return right(unit);
  }
}
