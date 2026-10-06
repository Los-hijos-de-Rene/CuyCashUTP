import '../../auth/domain/auth_failure.dart';
import '../../auth/domain/auth_repository.dart';
import '../../biometric/domain/biometric_gate.dart';
import '../../device/domain/device_store.dart';
import 'package:core_kernel/core_kernel.dart';

/// Cómo terminó un intento de entrar con huella.
sealed class BiometricSignIn {
  const BiometricSignIn();
}

final class BiometricSignInSuccess extends BiometricSignIn {
  const BiometricSignInSuccess();
}

final class BiometricSignInCancelled extends BiometricSignIn {
  const BiometricSignInCancelled();
}

final class BiometricSignInUnavailable extends BiometricSignIn {
  const BiometricSignInUnavailable();
}

/// La credencial ya no vale: se borró del teléfono; hay que entrar con PIN.
final class BiometricSignInRevoked extends BiometricSignIn {
  const BiometricSignInRevoked();
}

final class BiometricSignInLocked extends BiometricSignIn {
  const BiometricSignInLocked(this.until);
  final DateTime until;
}

final class BiometricSignInFailed extends BiometricSignIn {
  const BiometricSignInFailed();
}

/// Entrar con huella desde el acceso rápido. Un fallo de huella NO suma al
/// bloqueo local del acceso rápido: ese contador es del PIN.
class BiometricSignInUseCase {
  const BiometricSignInUseCase({
    required AuthRepository auth,
    required BiometricGate gate,
    required DeviceStore store,
  }) : _auth = auth,
       _gate = gate,
       _store = store;

  final AuthRepository _auth;
  final BiometricGate _gate;
  final DeviceStore _store;

  /// Hay credencial guardada Y el sistema puede pedir la huella.
  Future<bool> canUse() async =>
      await _store.readBiometricCredential() != null &&
      await _gate.isAvailable();

  Future<BiometricSignIn> call({
    required String dni,
    required String reason,
  }) async {
    final credencial = await _store.readBiometricCredential();
    if (credencial == null) return const BiometricSignInRevoked();

    switch (await _gate.authenticate(reason)) {
      case BiometricOutcome.cancelled:
        return const BiometricSignInCancelled();
      case BiometricOutcome.unavailable:
        return const BiometricSignInUnavailable();
      case BiometricOutcome.failed:
        return const BiometricSignInFailed();
      case BiometricOutcome.success:
        break;
    }

    final result = await _auth.signInWithBiometric(
      dni: dni,
      credential: credencial,
    );
    return result.match(
      (failure) => switch (failure) {
        ServerFailure(failure: BiometricRevoked()) => _forget(),
        ServerFailure(failure: AccessLocked(:final until)) => Future.value(
          BiometricSignInLocked(until),
        ),
        _ => Future.value(const BiometricSignInFailed()),
      },
      (_) => Future.value(const BiometricSignInSuccess()),
    );
  }

  Future<BiometricSignIn> _forget() async {
    await _store.clearBiometricCredential();
    return const BiometricSignInRevoked();
  }
}
