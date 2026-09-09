/// Config de entorno leída de `--dart-define` (via `--dart-define-from-file`).
abstract final class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Microservicio de KYC facial. En emulador Android la IP del host es
  /// `10.0.2.2`; desde un teléfono físico, la IP del PC en la red local.
  static const kycBaseUrl = String.fromEnvironment('KYC_BASE_URL');

  /// ATAJO DE DEMO, no diseño final. Una clave compilada en la app es
  /// extraíble (basta `strings` sobre el APK o un proxy mirando el tráfico),
  /// así que debe tratarse como pública. Cuando exista backend propio, la
  /// clave vive allí y la app deja de conocerla.
  static const kycApiKey = String.fromEnvironment('KYC_API_KEY');

  static bool get hasKycConfig => kycBaseUrl.isNotEmpty && kycApiKey.isNotEmpty;

  /// Valida que existan credenciales (solo flavors local/production).
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL / SUPABASE_ANON_KEY. Usá --dart-define-from-file.',
      );
    }
  }
}
