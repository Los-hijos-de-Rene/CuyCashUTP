import '../../feature/account/application/account_actions.dart';
import '../../feature/account/domain/account_repository.dart';
import '../../feature/auth/domain/auth_repository.dart';
import '../../feature/beneficiary/application/beneficiary_actions.dart';
import '../../feature/beneficiary/domain/beneficiary_repository.dart';
import '../../feature/device/domain/device_store.dart';
import '../../feature/kyc/domain/kyc_repository.dart';
import '../../feature/lockout/domain/identifier_lockout_store.dart';
import '../../feature/lockout/domain/lockout_policy.dart';
import '../../feature/otp/domain/otp_repository.dart';
import '../../feature/profile/application/profile_actions.dart';
import '../../feature/profile/domain/profile_repository.dart';
import '../../feature/security/application/security_actions.dart';
import '../../feature/security/domain/security_repository.dart';
import '../../feature/transfer/application/transfer_actions.dart';
import '../../feature/transfer/domain/pending_transfer_store.dart';
import '../../feature/transfer/domain/transfer_repository.dart';
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
    required this.kycRepository,
    required this.accountRepository,
    required this.transferRepository,
    required this.pendingTransferStore,
    required this.beneficiaryRepository,
    required this.profileRepository,
    required this.securityRepository,
    this.lockoutPolicy = const LockoutPolicy(),
  });

  final AppFlavor flavor;
  final AuthRepository authRepository;
  final DeviceStore deviceStore;
  final OtpRepository otpRepository;

  /// Bloqueo por DNI (rate limit del login). Simula estado de servidor: una
  /// sola instancia para toda la app.
  final IdentifierLockoutStore identifierLockoutStore;

  /// Verificación de identidad (documento + liveness). El análisis corre en el
  /// servidor; el teléfono solo captura y pregunta.
  final KycRepository kycRepository;

  /// Consulta de cuentas y movimientos. Los blocs consumen [accountActions].
  final AccountRepository accountRepository;
  AccountActions get accountActions => AccountActions(accountRepository);

  /// Envío y recarga de saldo. Los blocs consumen [transferActions].
  final TransferRepository transferRepository;
  TransferActions get transferActions => TransferActions(transferRepository);

  /// Claves de idempotencia de envíos que pudieron ejecutarse, por usuario.
  final PendingTransferStore pendingTransferStore;

  /// Frecuentes. Los blocs consumen [beneficiaryActions].
  final BeneficiaryRepository beneficiaryRepository;
  BeneficiaryActions get beneficiaryActions =>
      BeneficiaryActions(beneficiaryRepository);

  /// Datos del titular y alias. Los blocs consumen [profileActions].
  final ProfileRepository profileRepository;
  ProfileActions get profileActions => ProfileActions(profileRepository);

  /// Cambio de PIN, dispositivos y huella. Los blocs consumen
  /// [securityActions] o los use cases de `feature/security/application`.
  final SecurityRepository securityRepository;
  SecurityActions get securityActions => SecurityActions(securityRepository);

  final LockoutPolicy lockoutPolicy;
}
