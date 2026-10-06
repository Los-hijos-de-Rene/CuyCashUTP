import 'package:cuycash/feature/profile/infrastructure/memory_profile_repository.dart';

import 'profile_repository_contract.dart';

void main() {
  probarContratoDePerfil(
    'MemoryProfileRepository',
    MemoryProfileRepository.new,
    dni: MemoryProfileRepository.demo.dni,
    aliasInicial: MemoryProfileRepository.demo.alias,
  );
}
