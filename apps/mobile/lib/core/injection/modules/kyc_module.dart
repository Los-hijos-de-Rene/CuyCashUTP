import '../../../feature/kyc/application/kyc_actions.dart';
import '../app_dependencies.dart';

abstract final class KycModule {
  static KycActions create(AppDependencies deps) =>
      KycActions(deps.kycRepository);
}
