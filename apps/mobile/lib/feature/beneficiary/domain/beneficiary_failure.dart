/// Failures de frecuentes (viajan en `GlobalFailure.server`). Construcción por
/// factory nombrado; pattern matching por subclase.
///
/// Las subclases llevan el prefijo `Beneficiary` porque `NetworkFailure`,
/// `Unauthenticated` y `UnexpectedFailure` ya existen en otras features.
sealed class BeneficiaryFailure {
  const BeneficiaryFailure();

  const factory BeneficiaryFailure.recipientNotFound() =
      BeneficiaryRecipientNotFound;
  const factory BeneficiaryFailure.selfTransfer() = BeneficiarySelfTransfer;
  const factory BeneficiaryFailure.rateLimited(Duration? reintentarEn) =
      BeneficiaryRateLimited;
  const factory BeneficiaryFailure.unauthenticated() =
      BeneficiaryUnauthenticated;
  const factory BeneficiaryFailure.network() = BeneficiaryNetworkFailure;
  const factory BeneficiaryFailure.unexpected() = BeneficiaryUnexpectedFailure;
}

/// Ese DNI no es cliente de CuyCash, o su cuenta no puede recibir.
final class BeneficiaryRecipientNotFound extends BeneficiaryFailure {
  const BeneficiaryRecipientNotFound();
}

/// El DNI es el del propio titular.
final class BeneficiarySelfTransfer extends BeneficiaryFailure {
  const BeneficiarySelfTransfer();
}

/// Demasiadas consultas de destinatario (429): guardar comparte presupuesto
/// con la búsqueda y el envío.
final class BeneficiaryRateLimited extends BeneficiaryFailure {
  const BeneficiaryRateLimited(this.reintentarEn);

  /// `retry_after_seconds` del servidor; `null` si no vino legible.
  final Duration? reintentarEn;
}

/// La sesión no es válida o venció.
final class BeneficiaryUnauthenticated extends BeneficiaryFailure {
  const BeneficiaryUnauthenticated();
}

/// No se pudo llegar al servidor (sin red o timeout).
final class BeneficiaryNetworkFailure extends BeneficiaryFailure {
  const BeneficiaryNetworkFailure();
}

/// Respuesta que la app no sabe interpretar (5xx, 422, JSON malformado).
final class BeneficiaryUnexpectedFailure extends BeneficiaryFailure {
  const BeneficiaryUnexpectedFailure();
}
