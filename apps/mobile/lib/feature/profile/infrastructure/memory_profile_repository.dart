import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/alias_rules.dart';
import '../domain/personal_data.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

/// Impl en memoria (flavor `mock`). Aplica la misma regla de alias que el
/// backend.
class MemoryProfileRepository implements ProfileRepository {
  MemoryProfileRepository({PersonalData? initial}) : _datos = initial ?? demo;

  static final demo = PersonalData(
    dni: '70123456',
    nombres: 'Jheampierre',
    apellidos: 'Ruiz Salas',
    emailMasked: 'j•••••@correo.pe',
    alias: '@jheampierre',
    // Como el backend real: nadie escribe aún `kyc_status`, queda pendiente.
    kycVerified: false,
    clienteDesde: DateTime.utc(2026, 9, 1, 15),
  );

  PersonalData _datos;

  @override
  FutureResult<ProfileFailure, PersonalData> me() async => right(_datos);

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) async {
    final nuevo = AliasRules.normalize(alias);
    if (!AliasRules.isValid(nuevo)) {
      return left(const GlobalFailure.server(ProfileFailure.invalidAlias()));
    }
    _datos = _datos.copyWith(alias: nuevo);
    return right(nuevo);
  }
}
