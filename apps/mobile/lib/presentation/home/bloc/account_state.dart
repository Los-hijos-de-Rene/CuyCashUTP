part of 'account_bloc.dart';

/// Progreso de la carga inicial. `ready` también cubre "recargando": se
/// distingue por [AccountState.refreshing], para no tirar lo que ya se ve.
enum AccountStatus { loading, ready, error }

@freezed
abstract class AccountState with _$AccountState {
  const AccountState._();

  const factory AccountState({
    @Default(AccountStatus.loading) AccountStatus status,

    /// Todas las cuentas del titular, en el orden del servidor.
    @Default(<Account>[]) List<Account> cuentas,

    /// Índice en [cuentas] de la que se ve en el carrusel.
    @Default(0) int seleccionada,

    /// Los últimos movimientos de TODAS las cuentas (como mucho
    /// [AccountBloc.recientesEnInicio]). El historial completo vive en la
    /// pantalla de movimientos.
    @Default(<Movement>[]) List<Movement> recientes,

    /// Hay más movimientos que los [recientes]: el inicio ofrece "Ver más".
    @Default(false) bool hayMasMovimientos,
    @Default(false) bool refreshing,

    /// El último refresco falló y lo que se ve son datos anteriores.
    @Default(false) bool refreshFailed,

    /// Solo con `status == error`.
    AccountFailure? failure,

    /// Hay un cambio de nombre en vuelo.
    @Default(false) bool renaming,

    /// El último cambio de nombre falló; `null` si salió bien o no hubo.
    AccountFailure? renameFailure,
  }) = _AccountState;

  /// La cuenta visible; `null` sin cuentas.
  Account? get cuenta =>
      seleccionada < cuentas.length ? cuentas[seleccionada] : null;

  bool get puedeAbrirOtra => cuentas.length < AccountLimits.maxCuentas;
}
