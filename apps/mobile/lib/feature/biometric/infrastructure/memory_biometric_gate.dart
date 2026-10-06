import '../domain/biometric_gate.dart';

/// Gate configurable para tests y para el flavor `mock` (un emulador sin
/// huella igual puede recorrer la demo).
class MemoryBiometricGate implements BiometricGate {
  MemoryBiometricGate({
    this.available = true,
    this.outcome = BiometricOutcome.success,
  });

  bool available;
  BiometricOutcome outcome;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    prompts++;
    return available ? outcome : BiometricOutcome.unavailable;
  }
}
