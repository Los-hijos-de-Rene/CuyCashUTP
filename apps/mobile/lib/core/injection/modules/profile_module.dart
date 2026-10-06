import '../../../feature/profile/application/profile_actions.dart';
import '../app_dependencies.dart';

/// Wiring del perfil: los blocs reciben las acciones, nunca el repositorio.
abstract final class ProfileModule {
  static ProfileActions create(AppDependencies deps) => deps.profileActions;
}
