import '../../../feature/security/application/security_actions.dart';
import '../app_dependencies.dart';

/// Wiring de seguridad: los blocs reciben las acciones, nunca el repositorio.
abstract final class SecurityModule {
  static SecurityActions create(AppDependencies deps) => deps.securityActions;
}
