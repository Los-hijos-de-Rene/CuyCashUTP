import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../feature/account/infrastructure/http_account_repository.dart';
import '../../../../feature/auth/infrastructure/http_auth_repository.dart';
import '../../../../feature/beneficiary/infrastructure/http_beneficiary_repository.dart';
import '../../../../feature/biometric/infrastructure/local_auth_biometric_gate.dart';
import '../../../../feature/device/domain/device_store.dart';
import '../../../../feature/device/infrastructure/secure_device_store.dart';
import '../../../../feature/kyc/infrastructure/http_kyc_repository.dart';
import '../../../../feature/kyc/infrastructure/memory_kyc_repository.dart';
import '../../../../feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import '../../../../feature/otp/infrastructure/http_otp_repository.dart';
import '../../../../feature/profile/infrastructure/http_profile_repository.dart';
import '../../../../feature/security/infrastructure/http_security_repository.dart';
import '../../../../feature/transfer/infrastructure/http_transfer_repository.dart';
import '../../../../feature/transfer/infrastructure/shared_prefs_pending_transfer_store.dart';
import '../../../env/app_env.dart';
import '../../../env/device_name.dart';
import '../../../http/authenticated_dio.dart';
import '../../../http/close_session_on_expiry.dart';
import '../../../http/session_token_holder.dart';
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
  final deviceName = await describeThisDevice();
  final baseUrl = AppEnv.authBaseUrl;

  // Un único `Dio` autenticado para auth y para las features con dinero. El
  // token pasa por el holder (no por el dominio): auth lo escribe, el
  // interceptor lo lee.
  final tokenHolder = SessionTokenHolder();
  late final HttpAuthRepository authRepository;
  final dio = buildAuthenticatedDio(
    baseUrl: baseUrl,
    deviceId: deviceId,
    deviceName: deviceName,
    readToken: () => tokenHolder.token,
    // Sesión vencida: ver `closeSessionOnExpiry`.
    onUnauthenticated: () => closeSessionOnExpiry(authRepository)(),
  );
  authRepository = HttpAuthRepository(
    dio: dio,
    deviceId: deviceId,
    tokenHolder: tokenHolder,
  );

  return AppDependencies(
    flavor: flavor,
    authRepository: authRepository,
    deviceStore: deviceStore,
    otpRepository: HttpOtpRepository.withConfig(
      baseUrl: baseUrl,
      deviceId: deviceId,
    ),
    // El bloqueo real lo lleva el servidor y llega en la respuesta. Este store
    // queda para el acceso rápido, que sí es local a este teléfono.
    identifierLockoutStore: MemoryIdentifierLockoutStore(),
    kycRepository: usesRealKyc(flavor, enabled: AppEnv.kycEnabled)
        ? HttpKycRepository(dio: dio)
        : MemoryKycRepository(clock: DateTime.now),
    accountRepository: HttpAccountRepository(dio: dio),
    transferRepository: HttpTransferRepository(dio: dio),
    pendingTransferStore: const SharedPrefsPendingTransferStore(),
    beneficiaryRepository: HttpBeneficiaryRepository(dio: dio),
    profileRepository: HttpProfileRepository(dio: dio),
    securityRepository: HttpSecurityRepository(dio: dio),
    biometricGate: LocalAuthBiometricGate(),
  );
}


/// Si el registro llama al KYC facial real (proxy `/v1/kyc` del backend).
///
/// Solo en `local`, y solo con `KYC_ENABLED`. En `production` SIEMPRE se
/// simula, diga lo que diga la config: el microservicio aún no está desplegado
/// en Render, y un `config.production.json` con la bandera encendida dejaría
/// el registro en producción sin poder terminar. Cuando se despliegue, este
/// es el único sitio que hay que cambiar.
///
/// Sin la bandera, `local` también simula en vez de romper el arranque: el
/// resto de la app no depende del KYC.
bool usesRealKyc(AppFlavor flavor, {required bool enabled}) =>
    flavor == AppFlavor.local && enabled;
