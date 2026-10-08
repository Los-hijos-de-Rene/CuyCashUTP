import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/dev_tools_repository.dart';

/// Memory* del menú de desarrollo (contrato de tests). Cuenta las llamadas y
/// devuelve los mismos usuarios que siembra el backend.
class MemoryDevToolsRepository implements DevToolsRepository {
  MemoryDevToolsRepository({this.failure, List<DevOtp>? otps})
      : _otps = otps ?? const [];

  /// Si no es null, todas las operaciones fallan con esto.
  DevToolsFailure? failure;
  final List<DevOtp> _otps;

  var resets = 0;
  var seeds = 0;

  static const seeded = DevSeed(
    pin: '258036',
    users: [
      DevTestUser(dni: '11111111', name: 'Ana Prueba', alias: '@ana'),
      DevTestUser(dni: '22222222', name: 'Luis Prueba', alias: '@luis'),
    ],
  );

  @override
  FutureResult<DevToolsFailure, DevSeed> resetAndSeed() async {
    if (failure case final f?) return left(GlobalFailure.server(f));
    resets++;
    return right(seeded);
  }

  @override
  FutureResult<DevToolsFailure, DevSeed> seed() async {
    if (failure case final f?) return left(GlobalFailure.server(f));
    seeds++;
    return right(seeded);
  }

  @override
  FutureResult<DevToolsFailure, List<DevOtp>> latestOtps() async {
    if (failure case final f?) return left(GlobalFailure.server(f));
    return right(_otps);
  }
}
