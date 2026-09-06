/// Error como valor, de la frontera al pixel.
///
/// `F` es el failure de negocio por feature (`AuthFailure`, …), sealed y
/// definido en el domain de cada feature. PROHIBIDO aplanar a string o
/// `catch (_) {}`: el consumo es por `switch` exhaustivo.
sealed class GlobalFailure<F> {
  const GlobalFailure();

  const factory GlobalFailure.noConnection() = NoConnection<F>;
  const factory GlobalFailure.timeout() = Timeout<F>;
  const factory GlobalFailure.permissionDenied(String? hint) = PermissionDenied<F>;
  const factory GlobalFailure.notFound() = NotFound<F>;
  const factory GlobalFailure.storage(String message) = StorageFailure<F>;
  const factory GlobalFailure.server(F failure) = ServerFailure<F>;
  const factory GlobalFailure.unexpected(Object error, StackTrace stackTrace) =
      Unexpected<F>;
}

final class NoConnection<F> extends GlobalFailure<F> {
  const NoConnection();
}

final class Timeout<F> extends GlobalFailure<F> {
  const Timeout();
}

final class PermissionDenied<F> extends GlobalFailure<F> {
  const PermissionDenied(this.hint);
  final String? hint;
}

final class NotFound<F> extends GlobalFailure<F> {
  const NotFound();
}

final class StorageFailure<F> extends GlobalFailure<F> {
  const StorageFailure(this.message);
  final String message;
}

final class ServerFailure<F> extends GlobalFailure<F> {
  const ServerFailure(this.failure);
  final F failure;
}

final class Unexpected<F> extends GlobalFailure<F> {
  const Unexpected(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}
