import '../../../feature/beneficiary/application/beneficiary_actions.dart';
import '../app_dependencies.dart';

/// Wiring de frecuentes: expone `BeneficiaryActions` (armadas sobre el
/// `BeneficiaryRepository` del grafo). Los blocs de presentación reciben las
/// acciones, nunca el repositorio.
abstract final class BeneficiaryModule {
  static BeneficiaryActions create(AppDependencies deps) =>
      deps.beneficiaryActions;
}
