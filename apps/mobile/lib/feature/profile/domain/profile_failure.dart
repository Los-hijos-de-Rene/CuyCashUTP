/// Failures del perfil (viajan en `GlobalFailure.server`). Prefijo `Profile`
/// porque `NetworkFailure`/`Unauthenticated` ya existen en otras features.
sealed class ProfileFailure {
  const ProfileFailure();

  const factory ProfileFailure.invalidAlias() = ProfileInvalidAlias;
  const factory ProfileFailure.unauthenticated() = ProfileUnauthenticated;
  const factory ProfileFailure.network() = ProfileNetworkFailure;
  const factory ProfileFailure.unexpected() = ProfileUnexpectedFailure;
}

/// El servidor rechazó el formato del alias (422 `INVALID_ALIAS`).
final class ProfileInvalidAlias extends ProfileFailure {
  const ProfileInvalidAlias();
}

final class ProfileUnauthenticated extends ProfileFailure {
  const ProfileUnauthenticated();
}

final class ProfileNetworkFailure extends ProfileFailure {
  const ProfileNetworkFailure();
}

final class ProfileUnexpectedFailure extends ProfileFailure {
  const ProfileUnexpectedFailure();
}
