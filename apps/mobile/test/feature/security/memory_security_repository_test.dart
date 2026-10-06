import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'security_repository_contract.dart';

void main() {
  probarContratoDeSeguridad(
    'MemorySecurityRepository',
    () => MemorySecurityRepository(
      MemorySecurityState.demo(clock: () => DateTime.utc(2026, 10, 6, 12)),
      clock: () => DateTime.utc(2026, 10, 6, 12),
    ),
    pin: '000000',
    otroId: MemorySecurityState.otroDispositivoId,
    maxIntentos: LockoutPolicy.maxAttempts,
  );

  test('cambiar el PIN revoca la huella de los otros, no la de este', () async {
    final estado = MemorySecurityState.demo(clock: DateTime.now);
    final repo = MemorySecurityRepository(estado, clock: DateTime.now);
    final mia = (await repo.enrollBiometric('000000')).getRight().toNullable();
    estado.credentials['ajena'] = MemorySecurityState.otroDispositivoId;

    await repo.changePin(current: '000000', nuevo: '502718');

    expect(estado.credentials.keys, [mia]);
  });
}
