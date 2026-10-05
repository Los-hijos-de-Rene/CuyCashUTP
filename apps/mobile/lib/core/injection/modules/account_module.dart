import '../../../feature/account/application/account_actions.dart';
import '../app_dependencies.dart';

/// Wiring de cuentas: expone `AccountActions` (armadas sobre el `AccountRepository` del grafo). Los
/// blocs de presentación reciben las acciones, nunca el repositorio.
abstract final class AccountModule {
  static AccountActions create(AppDependencies deps) =>
      deps.accountActions;
}
