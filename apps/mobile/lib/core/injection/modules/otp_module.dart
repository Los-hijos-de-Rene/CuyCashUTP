import '../../../feature/otp/application/otp_actions.dart';
import '../app_dependencies.dart';

abstract final class OtpModule {
  static OtpActions create(AppDependencies deps) =>
      OtpActions(deps.otpRepository);
}
