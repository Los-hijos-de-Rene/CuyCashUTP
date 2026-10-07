import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/domain/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// La MISMA batería contra Memory y HTTP. [construir] entrega estado nuevo con
/// el titular [dni], alias inicial [aliasInicial], KYC verificado, y otro
/// titular que ya usa [aliasDeOtro].
void probarContratoDePerfil(
  String nombre,
  ProfileRepository Function() construir, {
  required String dni,
  required String aliasInicial,
  required String aliasDeOtro,
}) {
  T valorDe<T>(Result<ProfileFailure, T> r) =>
      r.match((f) => fail('No debía fallar: $f'), (v) => v);

  ProfileFailure falloDe(Result<ProfileFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<ProfileFailure>>(), reason: '$r');
    return (failure! as ServerFailure<ProfileFailure>).failure;
  }

  group('$nombre · contrato de ProfileRepository', () {
    test('me devuelve los datos con el correo enmascarado', () async {
      final datos = valorDe(await construir().me());
      expect(datos.dni, dni);
      expect(datos.alias, aliasInicial);
      expect(datos.emailMasked, contains('•'));
      // Ningún backend escribe aún el resultado del KYC (R7).
      expect(datos.kycVerified, isFalse);
      expect(datos.clienteDesde.isUtc, isTrue);
    });

    test('updateAlias normaliza, persiste y lo devuelve', () async {
      final repo = construir();
      expect(valorDe(await repo.updateAlias(' Nuevo_1 ')), '@nuevo_1');
      expect(valorDe(await repo.me()).alias, '@nuevo_1');
    });

    test('un alias inválido es invalidAlias', () async {
      expect(falloDe(await construir().updateAlias('ñandú')),
          isA<ProfileInvalidAlias>());
    });

    test('un alias de puros dígitos es invalidAlias', () async {
      expect(falloDe(await construir().updateAlias('12345678')),
          isA<ProfileInvalidAlias>());
    });

    test('el alias de otro es aliasTaken y no cambia el mío', () async {
      final repo = construir();
      expect(falloDe(await repo.updateAlias(aliasDeOtro.toUpperCase())),
          isA<ProfileAliasTaken>());
      expect(valorDe(await repo.me()).alias, aliasInicial);
    });

    test('volver a guardar mi propio alias no es conflicto', () async {
      expect(valorDe(await construir().updateAlias(aliasInicial)), aliasInicial);
    });
  });
}
