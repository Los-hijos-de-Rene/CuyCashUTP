/// Failures de cuentas (viajan en `GlobalFailure.server`). Construcción por
/// factory nombrado; pattern matching por subclase.
sealed class AccountFailure {
  const AccountFailure();

  const factory AccountFailure.accountNotFound() = AccountNotFound;
  const factory AccountFailure.unauthenticated() = Unauthenticated;
  const factory AccountFailure.network() = NetworkFailure;
  const factory AccountFailure.unexpected() = UnexpectedFailure;
  const factory AccountFailure.limitReached() = AccountLimitReached;
  const factory AccountFailure.salaryAccountExists() = SalaryAccountExists;
  const factory AccountFailure.invalidCurrency() = InvalidAccountCurrency;
  const factory AccountFailure.invalidName() = InvalidAccountName;
  const factory AccountFailure.wrongPin(int intentosRestantes) =
      AccountWrongPin;
  const factory AccountFailure.locked(DateTime hasta) = AccountLocked;
  const factory AccountFailure.idempotencyKeyReused() = AccountKeyReused;
}

/// La cuenta o el movimiento no existe, o no es del usuario. El backend
/// responde 404 en ambos casos a propósito: distinguirlos confirmaría que
/// existe.
final class AccountNotFound extends AccountFailure {
  const AccountNotFound();
}

/// La sesión no es válida o venció.
final class Unauthenticated extends AccountFailure {
  const Unauthenticated();
}

/// No se pudo llegar al servidor (sin red o timeout).
final class NetworkFailure extends AccountFailure {
  const NetworkFailure();
}

/// Respuesta que la app no sabe interpretar (5xx, código desconocido, JSON
/// malformado).
final class UnexpectedFailure extends AccountFailure {
  const UnexpectedFailure();
}

/// El titular ya tiene el máximo de cuentas.
final class AccountLimitReached extends AccountFailure {
  const AccountLimitReached();
}

/// Ya existe una cuenta sueldo; solo se permite una.
final class SalaryAccountExists extends AccountFailure {
  const SalaryAccountExists();
}

/// La moneda no vale para ese tipo de cuenta (sueldo solo en soles).
final class InvalidAccountCurrency extends AccountFailure {
  const InvalidAccountCurrency();
}

/// El nombre excede el largo permitido.
final class InvalidAccountName extends AccountFailure {
  const InvalidAccountName();
}

/// PIN incorrecto; quedan [intentosRestantes] antes del bloqueo.
final class AccountWrongPin extends AccountFailure {
  const AccountWrongPin(this.intentosRestantes);

  final int intentosRestantes;
}

/// Titular o dispositivo bloqueado hasta [hasta] (UTC).
final class AccountLocked extends AccountFailure {
  const AccountLocked(this.hasta);

  final DateTime hasta;
}

/// La clave de idempotencia ya se usó para otra intención.
final class AccountKeyReused extends AccountFailure {
  const AccountKeyReused();
}

extension AccountFailureOutcome on AccountFailure {
  /// El fallo deja DESCONOCIDO si la cuenta se abrió (red, inesperado): solo
  /// es seguro reintentar con la MISMA clave.
  bool get outcomeUnknown => switch (this) {
    NetworkFailure() || UnexpectedFailure() => true,
    AccountNotFound() ||
    Unauthenticated() ||
    AccountLimitReached() ||
    SalaryAccountExists() ||
    InvalidAccountCurrency() ||
    InvalidAccountName() ||
    AccountWrongPin() ||
    AccountLocked() ||
    AccountKeyReused() => false,
  };
}
