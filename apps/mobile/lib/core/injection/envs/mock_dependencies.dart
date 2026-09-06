import '../../../feature/auth/infrastructure/memory_auth_repository.dart';
import '../../env/app_flavor.dart';
import '../app_dependencies.dart';

/// Grafo del flavor `mock`: repos en memoria, sin red. PIN válido = '0000'.
Future<AppDependencies> buildMockDependencies() async => AppDependencies(
      flavor: AppFlavor.mock,
      authRepository: MemoryAuthRepository(),
    );
