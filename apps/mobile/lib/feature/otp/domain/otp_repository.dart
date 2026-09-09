import 'package:core_kernel/core_kernel.dart';
import 'otp_challenge.dart';
import 'otp_failure.dart';

/// Contrato del código de un solo uso (domain). Nunca lanza: devuelve `Result`.
///
/// El mismo contrato sirve a la recuperación de PIN y a la verificación de un
/// teléfono nuevo: cambia el identificador (correo o DNI), no el protocolo.
abstract interface class OtpRepository {
  /// Abre un reto para [identifier]. La respuesta es IDÉNTICA exista o no la
  /// cuenta — decir "ese correo no existe" confirmaría qué cuentas hay.
  /// Falla solo si el identificador está bloqueado tras una cancelación.
  FutureResult<OtpFailure, OtpChallenge> request(String identifier);

  /// Verifica el código. En éxito consume el reto y devuelve un TICKET.
  ///
  /// El ticket es la prueba de haber pasado por el código: sin él, el backend
  /// no deja cambiar el PIN ni abrir sesión en un teléfono nuevo. Que sea un
  /// valor y no un booleano es lo que impide saltarse el paso.
  FutureResult<OtpFailure, String> verify({
    required String challengeId,
    required String code,
  });

  /// Reenvía el código: reinicia el TTL y el enfriamiento. El reenvío que
  /// excede `OtpPolicy.maxResends` cancela el reto.
  FutureResult<OtpFailure, OtpChallenge> resend(String challengeId);
}
