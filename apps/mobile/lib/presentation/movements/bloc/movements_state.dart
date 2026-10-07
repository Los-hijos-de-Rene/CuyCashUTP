part of 'movements_bloc.dart';

/// Progreso de la primera página. `ready` también cubre "recargando" y
/// "pidiendo más", que se distinguen por [MovementsState.refreshing] y
/// [MovementsState.loadingMore].
enum MovementsStatus { loading, ready, error }

@freezed
abstract class MovementsState with _$MovementsState {
  const factory MovementsState({
    @Default(MovementsStatus.loading) MovementsStatus status,
    @Default(<Movement>[]) List<Movement> movimientos,

    /// Cursor opaco de la siguiente página; `null` = no hay más.
    String? nextCursor,
    @Default(false) bool loadingMore,

    /// La última página pedida por scroll falló. El cursor se conserva: el
    /// siguiente scroll reintenta la misma.
    @Default(false) bool loadMoreFailed,
    @Default(false) bool refreshing,

    /// El último refresco falló y lo que se ve son datos anteriores.
    @Default(false) bool refreshFailed,

    /// Solo con `status == error`.
    AccountFailure? failure,
  }) = _MovementsState;
}
