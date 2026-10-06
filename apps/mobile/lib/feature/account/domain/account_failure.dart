/// Failures de cuentas (viajan en `GlobalFailure.server`). Construcción por
/// factory nombrado; pattern matching por subclase.
sealed class AccountFailure {
  const AccountFailure();

  const factory AccountFailure.accountNotFound() = AccountNotFound;
  const factory AccountFailure.unauthenticated() = Unauthenticated;
  const factory AccountFailure.network() = NetworkFailure;
  const factory AccountFailure.unexpected() = UnexpectedFailure;
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
