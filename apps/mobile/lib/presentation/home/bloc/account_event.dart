part of 'account_bloc.dart';

@freezed
sealed class AccountEvent with _$AccountEvent {
  /// Primera carga: las cuentas y los últimos movimientos de todas.
  const factory AccountEvent.started() = AccountStarted;

  /// Pull-to-refresh: recarga sin vaciar la pantalla.
  const factory AccountEvent.refreshed() = AccountRefreshed;

  /// El carrusel se detuvo en otra cuenta: es la que usan las acciones
  /// rápidas (transferir, depositar).
  const factory AccountEvent.selected(int indice) = AccountSelected;

  /// Se abrió una cuenta: se agrega y queda a la vista.
  const factory AccountEvent.opened(Account cuenta) = AccountOpened;

  /// Poner o quitar (`null`) el nombre de una cuenta.
  const factory AccountEvent.renameRequested({
    required String cuentaId,
    String? nombre,
  }) = AccountRenameRequested;
}
