import 'package:core_kernel/core_kernel.dart';

import 'personal_data.dart';
import 'profile_failure.dart';

/// Datos del titular. Nunca lanza: devuelve `Result`.
abstract interface class ProfileRepository {
  FutureResult<ProfileFailure, PersonalData> me();

  /// Devuelve el alias ya normalizado por el servidor.
  FutureResult<ProfileFailure, String> updateAlias(String alias);
}
