import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/kyc/application/kyc_actions.dart';
import '../../../presentation/register/bloc/register_bloc.dart';
import '../app_dependencies.dart';
import 'security_module.dart';

/// Wiring del wizard de registro: arma `AuthActions` desde el repo y crea el
/// `RegisterBloc`. Se provee solo en la ruta /registro (no global).
abstract final class RegisterModule {
  static RegisterBloc create(AppDependencies deps) => RegisterBloc(
    AuthActions(deps.authRepository),
    biometric: SecurityModule.enableBiometric(deps),
    kyc: KycActions(deps.kycRepository),
  )..add(const RegisterEvent.biometricChecked());
}
