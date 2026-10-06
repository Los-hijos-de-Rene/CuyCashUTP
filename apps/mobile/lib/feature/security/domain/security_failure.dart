/// Failures de seguridad (viajan en `GlobalFailure.server`). Prefijo
/// `Security` porque los nombres genéricos ya existen en otras features.
sealed class SecurityFailure {
  const SecurityFailure();

  const factory SecurityFailure.wrongPin(int attemptsLeft) = SecurityWrongPin;
  const factory SecurityFailure.locked(DateTime until) = SecurityLocked;
  const factory SecurityFailure.weakPin() = SecurityWeakPin;
  const factory SecurityFailure.pinUnchanged() = SecurityPinUnchanged;
  const factory SecurityFailure.cannotUnlinkCurrent() =
      SecurityCannotUnlinkCurrent;
  const factory SecurityFailure.deviceNotFound() = SecurityDeviceNotFound;
  const factory SecurityFailure.biometricUnavailable() =
      SecurityBiometricUnavailable;
  const factory SecurityFailure.unauthenticated() = SecurityUnauthenticated;
  const factory SecurityFailure.network() = SecurityNetworkFailure;
  const factory SecurityFailure.unexpected() = SecurityUnexpectedFailure;
}

/// El PIN actual no es correcto; [attemptsLeft] lo cuenta el servidor.
final class SecurityWrongPin extends SecurityFailure {
  const SecurityWrongPin(this.attemptsLeft);
  final int attemptsLeft;
}

/// Se agotaron los intentos: bloqueado hasta [until] y la sesión cerrada.
final class SecurityLocked extends SecurityFailure {
  const SecurityLocked(this.until);
  final DateTime until;
}

final class SecurityWeakPin extends SecurityFailure {
  const SecurityWeakPin();
}

final class SecurityPinUnchanged extends SecurityFailure {
  const SecurityPinUnchanged();
}

/// Este teléfono no se desvincula desde la lista: para eso está cerrar sesión.
final class SecurityCannotUnlinkCurrent extends SecurityFailure {
  const SecurityCannotUnlinkCurrent();
}

/// Ya no estaba vinculado (otro teléfono lo sacó antes).
final class SecurityDeviceNotFound extends SecurityFailure {
  const SecurityDeviceNotFound();
}

/// Sin sensor o sin huellas registradas en el sistema.
final class SecurityBiometricUnavailable extends SecurityFailure {
  const SecurityBiometricUnavailable();
}

final class SecurityUnauthenticated extends SecurityFailure {
  const SecurityUnauthenticated();
}

/// Sin red o timeout. En `changePin` el resultado es DESCONOCIDO.
final class SecurityNetworkFailure extends SecurityFailure {
  const SecurityNetworkFailure();
}

final class SecurityUnexpectedFailure extends SecurityFailure {
  const SecurityUnexpectedFailure();
}
