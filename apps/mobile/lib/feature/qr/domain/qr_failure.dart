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

  /// La API de QR todavía no está desplegada en este entorno.
  const factory QrFailure.unavailable() = QrUnavailable;

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
