import '../../feature/auth/domain/auth_repository.dart';
import '../../feature/device/domain/device_store.dart';
import '../../feature/lockout/domain/identifier_lockout_store.dart';
import '../../feature/lockout/domain/lockout_policy.dart';
import '../../feature/otp/domain/otp_repository.dart';
import '../env/app_flavor.dart';

/// Grafo de dependencias ya resuelto (composición raíz). Solo INTERFACES:
/// el bootstrap no conoce Supabase ni memory. Crece con cada feature.
class AppDependencies {
  const AppDependencies({
    required this.flavor,
    required this.authRepository,
    required this.deviceStore,
    required this.otpRepository,
    required this.identifierLockoutStore,
    this.lockoutPolicy = const LockoutPolicy(),
  });

  final AppFlavor flavor;
  final AuthRepository authRepository;
  final DeviceStore deviceStore;
  final OtpRepository otpRepository;

  /// Bloqueo por DNI (rate limit del login). Simula estado de servidor: una
  /// sola instancia para toda la app.
  final IdentifierLockoutStore identifierLockoutStore;
  final LockoutPolicy lockoutPolicy;
}
