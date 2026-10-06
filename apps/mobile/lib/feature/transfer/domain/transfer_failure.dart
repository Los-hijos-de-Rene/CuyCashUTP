/// Failures de movimientos de dinero (viajan en `GlobalFailure.server`).
/// Construcción por factory nombrado; pattern matching por subclase.
sealed class TransferFailure {
  const TransferFailure();

  const factory TransferFailure.insufficientFunds() = InsufficientFunds;
  const factory TransferFailure.recipientNotFound() = RecipientNotFound;
  const factory TransferFailure.currencyMismatch() = CurrencyMismatch;
  const factory TransferFailure.sameAccount() = SameAccount;
  const factory TransferFailure.accountNotFound() = TransferAccountNotFound;
  const factory TransferFailure.accountBlocked() = AccountBlocked;
  const factory TransferFailure.amountOutOfRange() = AmountOutOfRange;
  const factory TransferFailure.idempotencyKeyReused() = IdempotencyKeyReused;
  const factory TransferFailure.wrongPin(int intentosRestantes) = WrongPin;
  const factory TransferFailure.identifierLocked(DateTime hasta) =
      IdentifierLocked;
  const factory TransferFailure.deviceLocked(DateTime hasta) = DeviceLocked;
  const factory TransferFailure.rateLimited(Duration? reintentarEn) =
      RateLimited;
  const factory TransferFailure.unauthenticated() = TransferUnauthenticated;
  const factory TransferFailure.network() = TransferNetworkFailure;
  const factory TransferFailure.unexpected() = TransferUnexpectedFailure;
}

/// El saldo disponible no alcanza.
final class InsufficientFunds extends TransferFailure {
  const InsufficientFunds();
}

/// Ese DNI no es cliente de CuyCash, o su cuenta no puede recibir. El backend
/// responde igual en ambos casos a propósito.
final class RecipientNotFound extends TransferFailure {
  const RecipientNotFound();
}

/// La cuenta destino es de otra moneda que la de origen: no hay conversión.
final class CurrencyMismatch extends TransferFailure {
  const CurrencyMismatch();
}

/// La cuenta destino es la misma de origen.
final class SameAccount extends TransferFailure {
  const SameAccount();
}

/// La cuenta de origen no existe o no es del usuario (el backend no
/// distingue ambos casos).
final class TransferAccountNotFound extends TransferFailure {
  const TransferAccountNotFound();
}

/// La cuenta propia no está activa.
final class AccountBlocked extends TransferFailure {
  const AccountBlocked();
}

/// Monto fuera de 1..200000 céntimos (S/ 0.01 a S/ 2,000.00).
final class AmountOutOfRange extends TransferFailure {
  const AmountOutOfRange();
}

/// La misma `idempotencyKey` se usó con datos distintos (409).
final class IdempotencyKeyReused extends TransferFailure {
  const IdempotencyKeyReused();
}

/// PIN errado. El backend responde 403 (NO 401) a propósito: la sesión sigue
/// siendo válida y el interceptor no debe cerrarla.
final class WrongPin extends TransferFailure {
  const WrongPin(this.intentosRestantes);

  /// Intentos que quedan antes del bloqueo por DNI.
  final int intentosRestantes;
}

/// Bloqueo por DNI (`IDENTIFIER_LOCKED`, 423): se agota igual entrando que
/// enviando.
final class IdentifierLocked extends TransferFailure {
  const IdentifierLocked(this.hasta);

  /// Instante en UTC hasta el que dura el bloqueo.
  final DateTime hasta;
}

/// Bloqueo por dispositivo (`DEVICE_LOCKED`, 423): afecta a este teléfono
/// aunque el DNI no esté bloqueado.
final class DeviceLocked extends TransferFailure {
  const DeviceLocked(this.hasta);

  /// Instante en UTC hasta el que dura el bloqueo.
  final DateTime hasta;
}

/// Demasiadas consultas de destinatario (429). La búsqueda, el alta de
/// frecuentes y el envío comparten presupuesto.
///
/// CUIDADO: un REINTENTO idempotente de `enviar` también puede recibirlo, y
/// entonces el usuario no sabe si el dinero se movió. Es una limitación
/// conocida del backend: quien consuma este failure tras un reintento debe
/// decir "no pudimos confirmar", no "no se envió".
final class RateLimited extends TransferFailure {
  const RateLimited(this.reintentarEn);

  /// `retry_after_seconds` del servidor; `null` si no vino legible.
  final Duration? reintentarEn;
}

/// La sesión no es válida o venció (el interceptor ya la cierra).
final class TransferUnauthenticated extends TransferFailure {
  const TransferUnauthenticated();
}

/// No se pudo llegar al servidor (sin red o timeout). El resultado de la
/// operación es DESCONOCIDO: reintentar con la MISMA `idempotencyKey`.
final class TransferNetworkFailure extends TransferFailure {
  const TransferNetworkFailure();
}

/// Respuesta que la app no sabe interpretar (5xx, código desconocido, JSON
/// malformado).
final class TransferUnexpectedFailure extends TransferFailure {
  const TransferUnexpectedFailure();
}

extension TransferFailureOutcome on TransferFailure {
  /// El fallo deja DESCONOCIDO si el dinero se movió (red, 429, inesperado):
  /// la única salida segura es reintentar con la MISMA clave de idempotencia.
  bool get outcomeUnknown => switch (this) {
    TransferNetworkFailure() ||
    TransferUnexpectedFailure() ||
    RateLimited() => true,
    InsufficientFunds() ||
    WrongPin() ||
    IdentifierLocked() ||
    DeviceLocked() ||
    RecipientNotFound() ||
    CurrencyMismatch() ||
    SameAccount() ||
    AmountOutOfRange() ||
    AccountBlocked() ||
    IdempotencyKeyReused() ||
    TransferAccountNotFound() ||
    TransferUnauthenticated() => false,
  };
}
