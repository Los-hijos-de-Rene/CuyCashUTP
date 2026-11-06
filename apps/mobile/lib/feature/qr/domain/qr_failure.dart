/// Fallos del cobro y pago con QR. Se construyen por factory nombrado y se
/// distinguen por subclase, igual que el resto de failures del repo.
sealed class QrFailure {
  const QrFailure();

  /// El QR superó su fecha de caducidad.
  const factory QrFailure.expired() = QrExpired;

  /// El contenido no coincide con la firma: alguien lo alteró.
  const factory QrFailure.tampered() = QrTampered;

  /// La cuenta de origen no alcanza a cubrir el monto.
  const factory QrFailure.insufficientFunds() = QrInsufficientFunds;

  /// PIN errado al confirmar el pago.
  const factory QrFailure.wrongPin(int intentosRestantes) = QrWrongPin;

  /// Sin red o timeout.
  const factory QrFailure.network() = QrNetworkFailure;

  /// El servicio de QR no está configurado en este entorno.
  const factory QrFailure.unavailable() = QrUnavailable;

  /// El QR ya se pagó: cada cobro admite un solo pago.
  const factory QrFailure.alreadyPaid() = QrAlreadyPaid;

  /// La cuenta que paga es la misma que cobra.
  const factory QrFailure.sameAccount() = QrSameAccount;

  /// La cuenta que paga y el cobro están en monedas distintas.
  const factory QrFailure.currencyMismatch() = QrCurrencyMismatch;

  /// El monto está fuera del rango permitido.
  const factory QrFailure.amountOutOfRange() = QrAmountOutOfRange;

  /// La cuenta de cobro o de pago no está disponible.
  const factory QrFailure.accountUnavailable() = QrAccountUnavailable;

  /// Demasiados intentos: el servidor bloqueó el acceso por un tiempo.
  const factory QrFailure.locked() = QrLocked;

  /// Respuesta que la app no sabe interpretar.
  const factory QrFailure.unexpected() = QrUnexpectedFailure;
}

final class QrExpired extends QrFailure {
  const QrExpired();
}

final class QrTampered extends QrFailure {
  const QrTampered();
}

final class QrInsufficientFunds extends QrFailure {
  const QrInsufficientFunds();
}

final class QrWrongPin extends QrFailure {
  const QrWrongPin(this.intentosRestantes);

  /// Intentos que quedan antes del bloqueo por DNI.
  final int intentosRestantes;
}

final class QrNetworkFailure extends QrFailure {
  const QrNetworkFailure();
}

final class QrUnavailable extends QrFailure {
  const QrUnavailable();
}

final class QrUnexpectedFailure extends QrFailure {
  const QrUnexpectedFailure();
}

final class QrAlreadyPaid extends QrFailure {
  const QrAlreadyPaid();
}

final class QrSameAccount extends QrFailure {
  const QrSameAccount();
}

final class QrCurrencyMismatch extends QrFailure {
  const QrCurrencyMismatch();
}

final class QrAmountOutOfRange extends QrFailure {
  const QrAmountOutOfRange();
}

final class QrAccountUnavailable extends QrFailure {
  const QrAccountUnavailable();
}

final class QrLocked extends QrFailure {
  const QrLocked();
}
