/// Sesión autenticada.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.identifier,
    this.alias,
  });

  final String userId;
  final String identifier; // DNI o alias con el que inició sesión
  final String? alias;

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.identifier == identifier &&
      other.alias == alias;

  @override
  int get hashCode => Object.hash(userId, identifier, alias);
}
