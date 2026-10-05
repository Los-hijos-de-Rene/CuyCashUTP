import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../feature/account/infrastructure/memory_account_repository.dart';
import '../../../feature/account/infrastructure/memory_ledger.dart';
import '../../../feature/auth/infrastructure/memory_auth_repository.dart';
import '../../../feature/device/infrastructure/secure_device_store.dart';
import '../../../feature/kyc/infrastructure/memory_kyc_repository.dart';
import '../../../feature/lockout/domain/lockout_policy.dart';
import '../../../feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import '../../../feature/otp/infrastructure/memory_otp_repository.dart';
import '../../../feature/transfer/infrastructure/memory_pending_transfer_store.dart';
import '../../../feature/transfer/infrastructure/memory_transfer_repository.dart';
import '../../env/app_flavor.dart';
import '../app_dependencies.dart';

/// Grafo del flavor `mock`: repos en memoria, sin red. PIN válido = '000000'.
Future<AppDependencies> buildMockDependencies() async {
  // UN libro mayor para toda la demo: enviar y recargar mueven el saldo que
  // el inicio muestra.
  final ledger = MemoryLedger(clock: DateTime.now);
  return AppDependencies(
    flavor: AppFlavor.mock,
    authRepository: MemoryAuthRepository(),
    deviceStore: const SecureDeviceStore(FlutterSecureStorage()),
    // El reloj se inyecta aquí (composición raíz): dentro del repo nunca se
    // llama a DateTime.now().
    otpRepository: MemoryOtpRepository(clock: DateTime.now),
    identifierLockoutStore: MemoryIdentifierLockoutStore(),
    kycRepository: MemoryKycRepository(clock: DateTime.now),
    accountRepository: MemoryAccountRepository(
      clock: DateTime.now,
      ledger: ledger,
    ),
    transferRepository: MemoryTransferRepository(
      clock: DateTime.now,
      ledger: ledger,
    ),
    pendingTransferStore: MemoryPendingTransferStore(),
    // Bloqueo de 10/20/30 s para poder ver la pantalla completa al probar.
    lockoutPolicy: const LockoutPolicy.mock(),
  );
}
