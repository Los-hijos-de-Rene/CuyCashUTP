import 'package:local_auth/local_auth.dart';

import '../domain/biometric_gate.dart';

/// `BiometricGate` sobre `local_auth`. Solo biometría (`biometricOnly`): el
/// PIN del sistema no sustituye al de CuyCash.
class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout => BiometricOutcome.cancelled,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricOutcome.unavailable,
        _ => BiometricOutcome.failed,
      };
    } catch (_) {
      return BiometricOutcome.failed;
    }
  }
}
