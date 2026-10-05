import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../feature/auth/infrastructure/http_auth_repository.dart';
import '../../../../feature/device/domain/device_store.dart';
import '../../../../feature/device/infrastructure/secure_device_store.dart';
import '../../../../feature/kyc/domain/kyc_repository.dart';
import '../../../../feature/kyc/infrastructure/http_kyc_repository.dart';
import '../../../../feature/kyc/infrastructure/memory_kyc_repository.dart';
import '../../../../feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import '../../../../feature/otp/infrastructure/http_otp_repository.dart';
import '../../../env/app_env.dart';
import '../../../env/app_flavor.dart';
import '../../app_dependencies.dart';

/// Construcción compartida por `local` y `production`: mismo código, distinta
/// config vía `--dart-define`.
///
/// Habla con `services/api`, no con Supabase: el modelo de identidad de
/// CuyCash es DNI + PIN y Supabase Auth no encaja (ADR-0002).
Future<AppDependencies> buildSharedBackendDependencies(AppFlavor flavor) async {
  const DeviceStore deviceStore = SecureDeviceStore(FlutterSecureStorage());
  // El backend exige `X-Device-Id` en cada llamada: se resuelve una vez, al
  // armar el grafo, para que ningún repositorio tenga que esperarlo después.
  final deviceId = await deviceStore.deviceId();
  final baseUrl = AppEnv.authBaseUrl;

  return AppDependencies(
    flavor: flavor,
    authRepository:
        HttpAuthRepository.withConfig(baseUrl: baseUrl, deviceId: deviceId),
    deviceStore: deviceStore,
    otpRepository:
        HttpOtpRepository.withConfig(baseUrl: baseUrl, deviceId: deviceId),
    // El bloqueo real lo lleva el servidor y llega en la respuesta. Este store
    // queda para el acceso rápido, que sí es local a este teléfono.
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
