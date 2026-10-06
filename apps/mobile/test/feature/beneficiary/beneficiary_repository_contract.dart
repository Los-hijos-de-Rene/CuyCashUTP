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
/// - [cuentaConocida] y [cuentaConocida2] son dos cuentas de la MISMA persona
///   [dniConocido], con nombre enmascarado. Ninguna otra cuenta existe.
/// - Presupuesto de [consultasMaximas] consultas de destinatario, que
///   `guardar` consume (también cuando solo actualiza el apodo).
/// - Lista vacía al empezar.
void probarContratoDeBeneficiarios(
  String nombre,
  BeneficiaryRepository Function() construir, {
  required String dniConocido,
  required String cuentaConocida,
  required String cuentaConocida2,
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

    test('guardar crea el frecuente con su cuenta', () async {
      final repo = construir();
      valorDe(
        await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'Carlos'),
      );

      final lista = valorDe(await repo.listar());
      expect(lista, hasLength(1));
      final b = lista.single;
      expect(b.id, isNotEmpty);
      expect(b.dni, dniConocido);
      expect(b.apodo, 'Carlos');
      expect(b.nombreEnmascarado, contains('***'));
      expect(b.cuenta?.cuentaId, cuentaConocida);
      expect(b.cuenta?.numeroMasked, startsWith('••••'));
    });

    test('dos cuentas de la misma persona son dos frecuentes', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'A'));
      valorDe(
        await repo.guardar(cuentaDestinoId: cuentaConocida2, apodo: 'B'),
      );
      expect(valorDe(await repo.listar()).map((b) => b.apodo), ['B', 'A']);
    });

    test('guardar dos veces la misma cuenta actualiza el apodo', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'A'));
      final id = valorDe(await repo.listar()).single.id;
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'B'));

      final lista = valorDe(await repo.listar());
      expect(lista.single.apodo, 'B');
      expect(lista.single.id, id, reason: 'el upsert conserva la fila');
    });

    test('una cuenta inexistente es recipientNotFound', () async {
      expect(
        falloDe(
          await construir().guardar(cuentaDestinoId: 'no-existe', apodo: 'X'),
        ),
        isA<BeneficiaryRecipientNotFound>(),
      );
    });

    test('el apodo que llega es el que se guarda, tal cual', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'Mamá Ñañita'));

      expect(valorDe(await repo.listar()).single.apodo, 'Mamá Ñañita');
    });

    test('eliminar quita el frecuente', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'Carlos'));
      final Beneficiary b = valorDe(await repo.listar()).single;

      valorDe(await repo.eliminar(b.id));

      expect(valorDe(await repo.listar()), isEmpty);
    });

    test('eliminar uno inexistente no es un error', () async {
      final r = await construir().eliminar('no-existe');
      r.match((f) => fail('No debía fallar: $f'), (_) {});
    });

    test('un apodo de 40 caracteres entra; uno de 80 es un fallo, no una '
        'excepción', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'x' * 40));

      final r = await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'x' * 80);
      expect(falloDe(r), isA<BeneficiaryUnexpectedFailure>());
      expect(valorDe(await repo.listar()).single.apodo, 'x' * 40);
    });

    test('guardar consume el presupuesto de consultas y al agotarse '
        'devuelve rateLimited con espera', () async {
      final repo = construir();
      for (var i = 0; i < consultasMaximas; i++) {
        valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'Carlos'));
      }

      final f = falloDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'Carlos'));
      expect(f, isA<BeneficiaryRateLimited>());
      expect((f as BeneficiaryRateLimited).reintentarEn, isNotNull);
    });

    test('listar y eliminar no gastan presupuesto', () async {
      final repo = construir();
      for (var i = 0; i < consultasMaximas + 5; i++) {
        valorDe(await repo.listar());
        valorDe(await repo.eliminar('x'));
      }
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'Carlos'));
    });
  });
}
