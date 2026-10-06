/// Resultado del diálogo biométrico del sistema. Cancelar no es un error: el
/// usuario eligió el PIN.
enum BiometricOutcome { success, cancelled, unavailable, failed }

/// La huella o el rostro del sistema. El teléfono no guarda nada aquí: solo
/// pregunta "¿es el dueño?".
abstract interface class BiometricGate {
  /// Hay sensor Y al menos una huella o rostro registrado.
  Future<bool> isAvailable();

  Future<BiometricOutcome> authenticate(String reason);
}
