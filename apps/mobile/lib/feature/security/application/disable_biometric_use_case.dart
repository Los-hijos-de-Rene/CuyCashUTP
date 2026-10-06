import '../../device/domain/device_store.dart';
import '../domain/security_repository.dart';

/// Apaga la huella. El secreto local se borra SIEMPRE, aunque el servidor no
/// conteste: sin él, la credencial del servidor no la puede usar nadie, y se
/// revoca en el próximo `enroll`.
class DisableBiometricUseCase {
  const DisableBiometricUseCase({
    required SecurityRepository repo,
    required DeviceStore store,
  }) : _repo = repo,
       _store = store;

  final SecurityRepository _repo;
  final DeviceStore _store;

  Future<void> call() async {
    await _store.clearBiometricCredential();
    await _repo.revokeBiometric();
  }
}
