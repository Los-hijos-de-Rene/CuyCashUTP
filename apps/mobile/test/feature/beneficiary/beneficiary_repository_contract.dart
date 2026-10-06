import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary_failure.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// La MISMA batería contra el `Memory*` y contra el HTTP.
///
/// Premisas del escenario que [construir] debe entregar, SIEMPRE con estado
/// nuevo en cada llamada (cada test gasta presupuesto de consultas):
///
/// - Titular [dniPropio].
/// - Los únicos clientes son [dniConocido] y [dniConocido2], con nombre
///   enmascarado.
/// - Presupuesto de [consultasMaximas] consultas de destinatario, que
///   `guardar` consume (también cuando solo actualiza el apodo).
/// - Lista vacía al empezar.
void probarContratoDeBeneficiarios(
  String nombre,
  BeneficiaryRepository Function() construir, {
  required String dniPropio,
  required String dniConocido,
  required String dniConocido2,
  required int consultasMaximas,
}) {
  BeneficiaryFailure falloDe(Result<BeneficiaryFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<BeneficiaryFailure>>(), reason: '$r');
    return (failure! as ServerFailure<BeneficiaryFailure>).failure;
  }

  T valorDe<T>(Result<BeneficiaryFailure, T> r) =>
      r.match((f) => fail('No debía fallar: $f'), (v) => v);

  group('$nombre · contrato de BeneficiaryRepository', () {
    test('sin frecuentes la lista viene vacía', () async {
      expect(valorDe(await construir().listar()), isEmpty);
    });

    test('guardar crea el frecuente con su apodo y su nombre enmascarado',
        () async {
      final repo = construir();
      valorDe(await repo.guardar(dniConocido, 'Carlos'));

      final lista = valorDe(await repo.listar());
      expect(lista, hasLength(1));
      expect(lista.single.id, isNotEmpty);
      expect(lista.single.dni, dniConocido);
      expect(lista.single.apodo, 'Carlos');
      expect(lista.single.nombreEnmascarado, contains('***'));
    });

    test('el apodo que llega es el que se guarda, tal cual', () async {
      final repo = construir();
      valorDe(await repo.guardar(dniConocido, 'Mamá Ñañita'));

      expect(valorDe(await repo.listar()).single.apodo, 'Mamá Ñañita');
    });

    test('guardar dos veces el mismo DNI actualiza el apodo', () async {
      final repo = construir();
      valorDe(await repo.guardar(dniConocido, 'Carlos'));
      final id = valorDe(await repo.listar()).single.id;
      valorDe(await repo.guardar(dniConocido, 'Carlitos'));

      final suyos = valorDe(await repo.listar())
          .where((b) => b.dni == dniConocido)
          .toList();
      expect(suyos, hasLength(1));
      expect(suyos.single.apodo, 'Carlitos');
      expect(suyos.single.id, id, reason: 'el upsert conserva la fila');
    });

    test('el más reciente va primero', () async {
      final repo = construir();
      valorDe(await repo.guardar(dniConocido, 'Primero'));
      valorDe(await repo.guardar(dniConocido2, 'Segundo'));

      final lista = valorDe(await repo.listar());
      expect(lista.map((b) => b.apodo), ['Segundo', 'Primero']);
    });

    test('eliminar quita el frecuente', () async {
      final repo = construir();
      valorDe(await repo.guardar(dniConocido, 'Carlos'));
      final Beneficiary b = valorDe(await repo.listar()).single;

      valorDe(await repo.eliminar(b.id));

      expect(valorDe(await repo.listar()), isEmpty);
    });

    test('eliminar uno inexistente no es un error', () async {
      final r = await construir().eliminar('no-existe');
      r.match((f) => fail('No debía fallar: $f'), (_) {});
    });

    test('guardar un DNI que no está en CuyCash devuelve recipientNotFound',
        () async {
      final r = await construir().guardar('99999999', 'Fantasma');
      expect(falloDe(r), isA<BeneficiaryRecipientNotFound>());
    });

    test('un DNI no guardado por no existir no ensucia la lista', () async {
      final repo = construir();
      await repo.guardar('99999999', 'Fantasma');
      expect(valorDe(await repo.listar()), isEmpty);
    });

    test('guardarse a uno mismo devuelve selfTransfer', () async {
      final r = await construir().guardar(dniPropio, 'Yo');
      expect(falloDe(r), isA<BeneficiarySelfTransfer>());
    });

    test('un apodo de 40 caracteres entra; uno de 80 es un fallo, no una '
        'excepción', () async {
      final repo = construir();
      valorDe(await repo.guardar(dniConocido, 'x' * 40));

      final r = await repo.guardar(dniConocido, 'x' * 80);
      expect(falloDe(r), isA<BeneficiaryUnexpectedFailure>());
      expect(valorDe(await repo.listar()).single.apodo, 'x' * 40);
    });

    test('guardar consume el presupuesto de consultas y al agotarse '
        'devuelve rateLimited con espera', () async {
      final repo = construir();
      for (var i = 0; i < consultasMaximas; i++) {
        valorDe(await repo.guardar(dniConocido, 'Carlos'));
      }

      final f = falloDe(await repo.guardar(dniConocido, 'Carlos'));
      expect(f, isA<BeneficiaryRateLimited>());
      expect((f as BeneficiaryRateLimited).reintentarEn, isNotNull);
    });

    test('listar y eliminar no gastan presupuesto', () async {
      final repo = construir();
      for (var i = 0; i < consultasMaximas + 5; i++) {
        valorDe(await repo.listar());
        valorDe(await repo.eliminar('x'));
      }
      valorDe(await repo.guardar(dniConocido, 'Carlos'));
    });
  });
}
