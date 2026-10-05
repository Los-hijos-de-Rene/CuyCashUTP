part of 'account_bloc.dart';

@freezed
sealed class AccountEvent with _$AccountEvent {
  /// Primera carga: cuenta y primera página de movimientos.
  const factory AccountEvent.started() = AccountStarted;

  /// Pull-to-refresh: recarga desde el principio sin vaciar la pantalla.
  const factory AccountEvent.refreshed() = AccountRefreshed;

  /// El scroll llegó cerca del final. Sale sin hacer nada si no hay más
  /// páginas o si ya hay una carga en curso.
  const factory AccountEvent.moreRequested() = AccountMoreRequested;
}
