import 'dev_host.dart';

/// Config de entorno leída de `--dart-define` (via `--dart-define-from-file`).
abstract final class AppEnv {
  /// Backend de identidad (`services/api`). Si no se define, se asume que
  /// corre en el PC anfitrión: sirve para emulador y simulador, NO para un
  /// teléfono físico, donde hay que poner la IP de la red local.
  static const _authBaseUrl = String.fromEnvironment('AUTH_BASE_URL');

  static String get authBaseUrl =>
      _authBaseUrl.isNotEmpty ? _authBaseUrl : DevHost.urlFor(8001);

  /// Si el registro usa el KYC facial REAL, a través del proxy de
  /// `services/api` (`/v1/kyc/...`). Solo tiene efecto en el flavor `local`:
  /// `production` siempre simula (ver `usesRealKyc`).
  ///
  /// La app ya no recibe ni la URL ni la clave del microservicio: las guarda
  /// el backend, que es quien lo llama. Todo lo compilado en el binario es
  /// extraíble, así que una clave aquí sería pública.
  static const kycEnabled = bool.fromEnvironment('KYC_ENABLED');
}
