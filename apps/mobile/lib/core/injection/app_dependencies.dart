import '../../feature/auth/domain/auth_repository.dart';
import '../../feature/device/domain/device_store.dart';
import '../env/app_flavor.dart';

/// Grafo de dependencias ya resuelto (composición raíz). Solo INTERFACES:
/// el bootstrap no conoce Supabase ni memory. Crece con cada feature.
class AppDependencies {
  const AppDependencies({
    required this.flavor,
    required this.authRepository,
    required this.deviceStore,
  });

  final AppFlavor flavor;
  final AuthRepository authRepository;
  final DeviceStore deviceStore;
}
