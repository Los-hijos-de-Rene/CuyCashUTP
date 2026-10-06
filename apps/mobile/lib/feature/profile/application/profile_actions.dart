import 'package:core_kernel/core_kernel.dart';

import '../domain/personal_data.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

/// Operaciones finas del perfil. El bloc las consume; nunca toca el repo.
class ProfileActions {
  const ProfileActions(this._repo);

  final ProfileRepository _repo;

  FutureResult<ProfileFailure, PersonalData> me() => _repo.me();

  FutureResult<ProfileFailure, String> updateAlias(String alias) =>
      _repo.updateAlias(alias);
}
