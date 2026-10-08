import 'package:core_kernel/core_kernel.dart';

import '../domain/dev_tools_repository.dart';

/// Operaciones del menú de desarrollo (delegación directa sobre el repo).
class DevToolsActions {
  const DevToolsActions(this._repo);

  final DevToolsRepository _repo;

  FutureResult<DevToolsFailure, DevSeed> resetAndSeed() => _repo.resetAndSeed();

  FutureResult<DevToolsFailure, DevSeed> seed() => _repo.seed();

  FutureResult<DevToolsFailure, List<DevOtp>> latestOtps() =>
      _repo.latestOtps();
}
