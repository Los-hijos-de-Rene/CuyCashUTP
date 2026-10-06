import '../../../feature/security/application/biometric_sign_in_use_case.dart';
import '../../../feature/security/application/disable_biometric_use_case.dart';
import '../../../feature/security/application/enable_biometric_use_case.dart';
import '../../../feature/security/application/security_actions.dart';
import '../app_dependencies.dart';

/// Wiring de seguridad: los blocs reciben las acciones, nunca el repositorio.
abstract final class SecurityModule {
  static SecurityActions create(AppDependencies deps) => deps.securityActions;

  static EnableBiometricUseCase enableBiometric(AppDependencies deps) =>
      EnableBiometricUseCase(
        repo: deps.securityRepository,
        gate: deps.biometricGate,
        store: deps.deviceStore,
      );

  static DisableBiometricUseCase disableBiometric(AppDependencies deps) =>
      DisableBiometricUseCase(
        repo: deps.securityRepository,
        store: deps.deviceStore,
      );

  static BiometricSignInUseCase biometricSignIn(AppDependencies deps) =>
      BiometricSignInUseCase(
        auth: deps.authRepository,
        gate: deps.biometricGate,
        store: deps.deviceStore,
      );
}
