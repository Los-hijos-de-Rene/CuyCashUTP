import 'package:cuycash/core/env/app_flavor.dart';
import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildMockDependencies expone un MemoryAuthRepository', () async {
    final deps = await buildMockDependencies();
    expect(deps.flavor, AppFlavor.mock);
    expect(deps.authRepository, isA<MemoryAuthRepository>());
  });
}
