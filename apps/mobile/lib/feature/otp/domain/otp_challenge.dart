/// Reto OTP vigente. Inmutable: cada `request`/`resend` devuelve uno nuevo.
///
/// Lleva los dos vencimientos por separado ([expiresAt] del código y
/// [cooldownUntil] del reenvío) porque avanzan a distinto ritmo.
class OtpChallenge {
  const OtpChallenge({
    required this.id,
    required this.maskedEmail,
    required this.expiresAt,
    required this.cooldownUntil,
    required this.attemptsLeft,
    required this.resendsLeft,
  });

  final String id;

  /// Correo enmascarado para mostrar (`j•••••@gmail.com`).
  final String maskedEmail;

  /// Vencimiento del código.
  final DateTime expiresAt;

  /// Instante en que el reenvío vuelve a estar disponible.
  final DateTime cooldownUntil;

  final int attemptsLeft;
  final int resendsLeft;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  bool isCooling(DateTime now) => now.isBefore(cooldownUntil);

  OtpChallenge copyWith({
    DateTime? expiresAt,
    DateTime? cooldownUntil,
    int? attemptsLeft,
    int? resendsLeft,
  }) =>
      OtpChallenge(
        id: id,
        maskedEmail: maskedEmail,
        expiresAt: expiresAt ?? this.expiresAt,
        cooldownUntil: cooldownUntil ?? this.cooldownUntil,
        attemptsLeft: attemptsLeft ?? this.attemptsLeft,
        resendsLeft: resendsLeft ?? this.resendsLeft,
      );

  @override
  bool operator ==(Object other) =>
      other is OtpChallenge &&
      other.id == id &&
      other.maskedEmail == maskedEmail &&
      other.expiresAt == expiresAt &&
      other.cooldownUntil == cooldownUntil &&
      other.attemptsLeft == attemptsLeft &&
      other.resendsLeft == resendsLeft;

  @override
  int get hashCode => Object.hash(
      id, maskedEmail, expiresAt, cooldownUntil, attemptsLeft, resendsLeft);
}
