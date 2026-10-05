import 'package:cuycash/core/env/app_flavor.dart';
import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildMockDependencies expone un MemoryAuthRepository', () async {
    final deps = await buildMockDependencies();
    expect(deps.flavor, AppFlavor.mock);
    expect(deps.authRepository, isA<MemoryAuthRepository>());
  });

  test('buildMockDependencies expone cuentas en memoria', () async {
    final deps = await buildMockDependencies();
    expect(deps.accountRepository, isA<MemoryAccountRepository>());
  });
}
