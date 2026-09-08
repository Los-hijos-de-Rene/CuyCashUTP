/// Estado de intentos/bloqueo (simulado, persistido). `level` = nº de bloqueos
/// aplicados (para escalar la duración).
class LockoutState {
  const LockoutState({
    this.failedAttempts = 0,
    this.level = 0,
    this.lockedUntil,
  });

  final int failedAttempts;
  final int level;
  final DateTime? lockedUntil;

  bool isLocked(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);

  LockoutState copyWith({int? failedAttempts, int? level, DateTime? lockedUntil}) =>
      LockoutState(
        failedAttempts: failedAttempts ?? this.failedAttempts,
        level: level ?? this.level,
        lockedUntil: lockedUntil ?? this.lockedUntil,
      );

  Map<String, dynamic> toJson() => {
        'failedAttempts': failedAttempts,
        'level': level,
        'lockedUntil': lockedUntil?.toIso8601String(),
      };

  factory LockoutState.fromJson(Map<String, dynamic> json) => LockoutState(
        failedAttempts: json['failedAttempts'] as int? ?? 0,
        level: json['level'] as int? ?? 0,
        lockedUntil: switch (json['lockedUntil']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
      );

  @override
  bool operator ==(Object other) =>
      other is LockoutState &&
      other.failedAttempts == failedAttempts &&
      other.level == level &&
      other.lockedUntil == lockedUntil;

  @override
  int get hashCode => Object.hash(failedAttempts, level, lockedUntil);
}
