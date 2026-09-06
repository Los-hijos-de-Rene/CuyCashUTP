import '../../../../feature/auth/infrastructure/supabase_auth_repository.dart';
import '../../../env/app_env.dart';
import '../../../env/app_flavor.dart';
import '../../app_dependencies.dart';

/// Construcción compartida por `local` y `production` (mismo código, distinta
/// config vía `--dart-define`). El cableado real de Supabase.initialize se
/// completa cuando llegue el backend.
Future<AppDependencies> buildSharedSupabaseDependencies(
  AppFlavor flavor,
) async {
  AppEnv.validate();
  // TODO(backend): Supabase.initialize(url: AppEnv.supabaseUrl, anonKey: ...)
  return AppDependencies(
    flavor: flavor,
    authRepository: SupabaseAuthRepository(),
  );
}
