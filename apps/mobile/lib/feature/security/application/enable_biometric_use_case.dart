import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../../biometric/domain/biometric_gate.dart';
import '../../device/domain/device_store.dart';
import '../domain/security_failure.dart';
import '../domain/security_repository.dart';

/// Activa la huella: sensor → diálogo del sistema → servidor → secreto en el
/// teléfono. El diálogo va ANTES del servidor: si el usuario cancela, no
/// queda una credencial emitida que nadie guardó.
class EnableBiometricUseCase {
  const EnableBiometricUseCase({
    required SecurityRepository repo,
    required BiometricGate gate,
    required DeviceStore store,
  }) : _repo = repo,
       _gate = gate,
       _store = store;

  final SecurityRepository _repo;
  final BiometricGate _gate;
  final DeviceStore _store;

  Future<bool> isAvailable() => _gate.isAvailable();

  /// `right(true)` activada; `right(false)` el usuario canceló.
  FutureResult<SecurityFailure, bool> call({
    required String pin,
    required String reason,
  }) async {
    const noDisponible = GlobalFailure<SecurityFailure>.server(
      SecurityFailure.biometricUnavailable(),
    );
    if (!await _gate.isAvailable()) return left(noDisponible);

    switch (await _gate.authenticate(reason)) {
      case BiometricOutcome.cancelled:
        return right(false);
      case BiometricOutcome.unavailable:
        return left(noDisponible);
      case BiometricOutcome.failed:
        return left(const GlobalFailure.server(SecurityFailure.unexpected()));
      case BiometricOutcome.success:
        break;
    }

    final emitida = await _repo.enrollBiometric(pin);
    return emitida.match((failure) async => left(failure), (secreto) async {
      if (await _store.saveBiometricCredential(secreto)) return right(true);
      // Una credencial que el teléfono no pudo guardar no la usará nadie:
      // se revoca para no dejarla viva en el servidor.
      await _repo.revokeBiometric();
      return left(const GlobalFailure.server(SecurityFailure.unexpected()));
    });
  }
}
