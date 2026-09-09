import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../feature/auth/infrastructure/supabase_auth_repository.dart';
import '../../../../feature/device/infrastructure/secure_device_store.dart';
import '../../../../feature/kyc/domain/kyc_repository.dart';
import '../../../../feature/kyc/infrastructure/http_kyc_repository.dart';
import '../../../../feature/kyc/infrastructure/memory_kyc_repository.dart';
import '../../../../feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import '../../../../feature/otp/infrastructure/memory_otp_repository.dart';
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
    deviceStore: const SecureDeviceStore(FlutterSecureStorage()),
    // TODO(backend): el OTP real lo emite Supabase. Hasta entonces también
    // aquí corre el simulado, con el reloj inyectado desde la raíz.
    otpRepository: MemoryOtpRepository(clock: DateTime.now),
    // TODO(backend): el rate limit por DNI lo aplicará el servidor.
    identifierLockoutStore: MemoryIdentifierLockoutStore(),
    kycRepository: _kycRepository(),
  );
}

/// Sin `KYC_BASE_URL`/`KYC_API_KEY` se cae al Memory* en vez de romper el
/// arranque: el resto de la app no depende del KYC para funcionar, y quedarse
/// sin abrir por una variable de entorno ausente sería peor que simularlo.
KycRepository _kycRepository() => AppEnv.hasKycConfig
    ? HttpKycRepository.withConfig(
        baseUrl: AppEnv.kycBaseUrl,
        apiKey: AppEnv.kycApiKey,
      )
    : MemoryKycRepository(clock: DateTime.now);
