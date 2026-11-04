/// Configuración de la sesión en la app.
///
/// El backend mantiene la sesión 30 días (`SESSION_TTL_SECONDS`), pero la app
/// no puede dejar la banca abierta para siempre: tras un rato sin uso se pide
/// de nuevo PIN o huella (HU03 CA4).
abstract final class SessionConfig {
  /// Minutos sin uso antes de bloquear la interfaz.
  ///
  /// Se cambia sin tocar el código:
  /// `flutter run --dart-define=SESSION_INACTIVITY_MINUTES=10`.
  static const int inactivityMinutes = int.fromEnvironment(
    'SESSION_INACTIVITY_MINUTES',
    defaultValue: 5,
  );

  static const Duration inactivityTimeout = Duration(
    minutes: inactivityMinutes,
  );
}
