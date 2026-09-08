import '../../../feature/lockout/application/identifier_lockout_actions.dart';
import '../app_dependencies.dart';

abstract final class LockoutModule {
  static IdentifierLockoutActions create(AppDependencies deps) =>
      IdentifierLockoutActions(deps.identifierLockoutStore,
          policy: deps.lockoutPolicy);
}
