import '../../../feature/transfer/application/pending_transfer_actions.dart';
import '../../../feature/transfer/application/transfer_actions.dart';
import '../app_dependencies.dart';

/// Wiring de transferencias: expone `TransferActions` (armadas sobre el
/// `TransferRepository` del grafo). Los blocs de presentación reciben las
/// acciones, nunca el repositorio.
abstract final class TransferModule {
  static TransferActions create(AppDependencies deps) => deps.transferActions;

  /// Claves de envíos pendientes (reloj inyectado aquí, en la composición).
  static PendingTransferActions pending(AppDependencies deps) =>
      PendingTransferActions(deps.pendingTransferStore, clock: DateTime.now);
}
