part of 'movements_bloc.dart';

@freezed
sealed class MovementsEvent with _$MovementsEvent {
  /// Primera página.
  const factory MovementsEvent.started() = MovementsStarted;

  /// Pull-to-refresh: recarga desde el principio sin vaciar la lista.
  const factory MovementsEvent.refreshed() = MovementsRefreshed;

  /// El scroll llegó cerca del final. Sale sin hacer nada si no hay más
  /// páginas o si ya hay una carga en curso.
  const factory MovementsEvent.moreRequested() = MovementsMoreRequested;
}
