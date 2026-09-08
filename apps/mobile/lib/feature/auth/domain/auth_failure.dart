/// Failures de auth (viajan en `GlobalFailure.server`). Construcción por factory
/// nombrado; pattern matching por subclase.
sealed class AuthFailure {
  const AuthFailure();

  const factory AuthFailure.invalidCredentials() = InvalidCredentials;
  const factory AuthFailure.identifierTaken() = IdentifierTaken;
  const factory AuthFailure.weakPin() = WeakPin;
  const factory AuthFailure.pinUnchanged() = PinUnchanged;
  const factory AuthFailure.authUnavailable() = AuthUnavailable;
}

/// DNI/Alias o PIN incorrectos.
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

/// El PIN nuevo es igual al que ya tenía la cuenta.
final class PinUnchanged extends AuthFailure {
  const PinUnchanged();
}

/// No se pudo contactar al proveedor de auth (sin backend real aún).
final class AuthUnavailable extends AuthFailure {
  const AuthUnavailable();
}
