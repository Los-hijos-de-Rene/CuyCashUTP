/// Política de bloqueo escalonado (simulada en cliente; el enforcement real
/// es backend). Nivel 1 = 15 min, nivel 2 = 1 h, nivel 3+ = 24 h.
abstract final class LockoutPolicy {
  static const int maxAttempts = 3;

  static Duration durationForLevel(int level) => switch (level) {
        1 => const Duration(minutes: 15),
        2 => const Duration(hours: 1),
        _ => const Duration(hours: 24),
      };
}
