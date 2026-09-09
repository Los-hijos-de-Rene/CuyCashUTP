import 'dev_host.dart';

/// Config de entorno leída de `--dart-define` (via `--dart-define-from-file`).
abstract final class AppEnv {
  /// Backend de identidad (`services/auth`). Si no se define, se asume que
  /// corre en el PC anfitrión: sirve para emulador y simulador, NO para un
  /// teléfono físico, donde hay que poner la IP de la red local.
  static const _authBaseUrl = String.fromEnvironment('AUTH_BASE_URL');

  static String get authBaseUrl =>
      _authBaseUrl.isNotEmpty ? _authBaseUrl : DevHost.urlFor(8001);

  /// Microservicio de KYC facial. En emulador Android la IP del host es
  /// `10.0.2.2`; desde un teléfono físico, la IP del PC en la red local.
  static const kycBaseUrl = String.fromEnvironment('KYC_BASE_URL');

  /// ATAJO DE DEMO, no diseño final. Una clave compilada en la app es
  /// extraíble (basta `strings` sobre el APK o un proxy mirando el tráfico),
  /// así que debe tratarse como pública. Cuando exista backend propio, la
  /// clave vive allí y la app deja de conocerla.
  static const kycApiKey = String.fromEnvironment('KYC_API_KEY');

  static bool get hasKycConfig => kycBaseUrl.isNotEmpty && kycApiKey.isNotEmpty;
}
