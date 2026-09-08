/// Política del código de un solo uso (simulada en cliente; el enforcement
/// real es backend). Tres relojes INDEPENDIENTES conviven aquí:
///
/// - [ttl]      — vida del código.
/// - [cooldown] — enfriamiento entre reenvíos.
/// - [lockout]  — bloqueo del identificador tras cancelar el flujo.
///
/// Que el enfriamiento llegue a cero NO vence el código, y que el código venza
/// no toca el enfriamiento: son relojes distintos.
abstract final class OtpPolicy {
  /// Único código que el mock acepta. Deliberadamente fácil de recordar para
  /// probar a mano; el código real lo emite el backend.
  static const validCode = '123456';

  static const cooldown = Duration(seconds: 60);
  static const ttl = Duration(seconds: 600);
  static const lockout = Duration(seconds: 900);

  static const maxAttempts = 3;
  static const maxResends = 3;
}
