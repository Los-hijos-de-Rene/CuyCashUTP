part of 'account_bloc.dart';

/// Progreso de la carga inicial. `ready` también cubre "recargando" y "pidiendo
/// más": esos casos se distinguen por [AccountState.refreshing] y
/// [AccountState.loadingMore], para no tirar a la basura lo que ya se ve.
enum AccountStatus { loading, ready, error }

@freezed
abstract class AccountState with _$AccountState {
  const factory AccountState({
    @Default(AccountStatus.loading) AccountStatus status,
    Account? cuenta,
    @Default(<Movement>[]) List<Movement> movimientos,

    /// Cursor opaco de la siguiente página; `null` = no hay más.
    String? nextCursor,
    @Default(false) bool loadingMore,
    @Default(false) bool refreshing,

    /// Solo con `status == error`.
    AccountFailure? failure,
  }) = _AccountState;
}
