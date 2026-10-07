/// Failures de auth (viajan en `GlobalFailure.server`). Construcción por factory
/// nombrado; pattern matching por subclase.
sealed class AuthFailure {
  const AuthFailure();

  const factory AuthFailure.invalidCredentials() = InvalidCredentials;
  const factory AuthFailure.identifierTaken() = IdentifierTaken;
  const factory AuthFailure.weakPin() = WeakPin;
  const factory AuthFailure.tooManyAttempts(int attemptsLeft) = TooManyAttempts;
  const factory AuthFailure.accessLocked(DateTime until) = AccessLocked;
  const factory AuthFailure.pinUnchanged() = PinUnchanged;
  const factory AuthFailure.authUnavailable() = AuthUnavailable;
  const factory AuthFailure.biometricRevoked() = BiometricRevoked;
  const factory AuthFailure.deviceVerificationRequired() =
      DeviceVerificationRequired;
}

/// DNI o PIN incorrectos.
final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

/// El DNI ya está registrado.
final class IdentifierTaken extends AuthFailure {
  const IdentifierTaken();
}

/// El PIN no cumple el formato (6 dígitos).
final class WeakPin extends AuthFailure {
  const WeakPin();
}

/// Credenciales incorrectas, con los intentos que informa el SERVIDOR.
///
/// Existe aparte de `invalidCredentials` porque con backend real el contador no
/// lo lleva el teléfono: contarlo aquí permitiría reinstalar la app para
/// ponerlo a cero.
final class TooManyAttempts extends AuthFailure {
  const TooManyAttempts(this.attemptsLeft);
  final int attemptsLeft;
}

/// El acceso está bloqueado hasta [until] (por DNI o por dispositivo).
final class AccessLocked extends AuthFailure {
  const AccessLocked(this.until);
  final DateTime until;
}

/// El PIN nuevo es igual al que ya tenía la cuenta.
final class PinUnchanged extends AuthFailure {
  const PinUnchanged();
}

/// No se pudo contactar al proveedor de auth (sin backend real aún).
final class AuthUnavailable extends AuthFailure {
  const AuthUnavailable();
}

/// La credencial biométrica ya no vale (revocada, de otro teléfono, o el
/// dispositivo se desvinculó). Se borra del teléfono y se entra con PIN.
final class BiometricRevoked extends AuthFailure {
  const BiometricRevoked();
}

/// El PIN fue correcto, pero este teléfono no es de confianza (nunca lo fue, o
/// lo desvincularon desde otro): falta el OTP de dispositivo. NO es un PIN
/// errado y no debe sumar intentos.
final class DeviceVerificationRequired extends AuthFailure {
  const DeviceVerificationRequired();
}
