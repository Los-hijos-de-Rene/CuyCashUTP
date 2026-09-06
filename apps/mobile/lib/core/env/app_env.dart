/// Config de entorno leída de `--dart-define` (via `--dart-define-from-file`).
abstract final class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Valida que existan credenciales (solo flavors local/production).
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL / SUPABASE_ANON_KEY. Usá --dart-define-from-file.',
      );
    }
  }
}
