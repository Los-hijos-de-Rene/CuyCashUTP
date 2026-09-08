/// Política de bloqueo escalonado (simulada en cliente; el enforcement real
/// es backend). Nivel 1 = 15 min, nivel 2 = 1 h, nivel 3+ = 24 h.
///
/// Las duraciones son de instancia (no constantes globales) para que el flavor
/// `mock` pueda acortarlas: ver [LockoutPolicy.mock].
class LockoutPolicy {
  const LockoutPolicy({
    this.level1 = const Duration(minutes: 15),
    this.level2 = const Duration(hours: 1),
    this.level3 = const Duration(hours: 24),
  });

  /// Escalonado corto del flavor `mock`: 10 s / 20 s / 30 s, para poder ver la
  /// cuenta regresiva completa sin esperar 15 minutos reales.
  const LockoutPolicy.mock()
      : level1 = const Duration(seconds: 10),
        level2 = const Duration(seconds: 20),
        level3 = const Duration(seconds: 30);

  /// Intentos antes de bloquear. Es igual en todos los flavors y se usa como
  /// valor por defecto de estado, así que se queda como constante.
  static const int maxAttempts = 3;

  final Duration level1;
  final Duration level2;
  final Duration level3;

  Duration durationForLevel(int level) => switch (level) {
        1 => level1,
        2 => level2,
        _ => level3,
      };

  /// Cuánto duraría el bloqueo si el usuario agotara los intentos AHORA,
  /// estando en [currentLevel] bloqueos previos. Es lo que debe anunciar la
  /// advertencia: nunca "15 minutos" fijo, porque escala.
  Duration nextLockoutFor(int currentLevel) =>
      durationForLevel(currentLevel + 1);
}
