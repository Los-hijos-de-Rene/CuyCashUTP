import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';

/// La MISMA batería contra el `Memory*` y contra el HTTP.
///
/// Es lo que impide que el flavor `mock` mienta: si el repositorio en memoria
/// se comporta distinto del real, la app que se demuestra no es la que se
/// despliega.
///
/// Premisa: [construir] devuelve un repositorio con los datos de demostración
/// (una cuenta `19100000004521` con S/ 1,250.40 y los movimientos
/// `tx-demo-1..3`). El `Memory*` los trae; el test HTTP los sirve desde un
/// backend simulado con el JSON real del router. [construir] acepta `pageSize`
/// (tamaño de página del servidor) para poder probar la paginación con tres
/// movimientos.
void probarContratoDeCuentas(
  String nombre,
  AccountRepository Function({int? pageSize}) construir,
) {
  AccountFailure falloDe(Result<AccountFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<AccountFailure>>());
    return (failure! as ServerFailure<AccountFailure>).failure;
  }

  T valorDe<T>(Result<AccountFailure, T> r) =>
      r.match((f) => fail('No debía fallar: $f'), (v) => v);

  Future<Account> primeraCuenta(AccountRepository repo) async =>
      valorDe(await repo.cuentas()).first;

  group('$nombre · contrato de AccountRepository', () {
    test('devuelve al menos una cuenta activa en soles', () async {
      final cuentas = valorDe(await construir().cuentas());

      expect(cuentas, isNotEmpty);
      expect(cuentas.first.moneda, Currency.pen);
      expect(cuentas.first.estado, 'activa');
    });

    test('cada cuenta trae tipo, moneda y nombre', () async {
      final c = await primeraCuenta(construir());

      expect(c.tipo, AccountType.ahorro);
      expect(c.moneda, Currency.pen);
      expect(c.nombre, isNull);
    });

    test('el saldo es Money en céntimos exactos', () async {
      final c = await primeraCuenta(construir());

      expect(c.saldoDisponible, const Money.soles(125040));
      expect(c.saldoContable, const Money.soles(125040));
    });

    test('el número enmascarado son los últimos cuatro dígitos', () async {
      final c = await primeraCuenta(construir());

      expect(c.numeroMasked, '••••${c.numero.substring(c.numero.length - 4)}');
      expect(c.numeroMasked, '••••4521');
    });

    test(
      'una cuenta inexistente devuelve accountNotFound, no una excepción',
      () async {
        final r = await construir().movimientos('no-existe');

        expect(falloDe(r), isA<AccountNotFound>());
      },
    );

    test(
      'el detalle de un movimiento inexistente devuelve accountNotFound',
      () async {
        final r = await construir().movimiento('tx-ajena');

        expect(falloDe(r), isA<AccountNotFound>());
      },
    );

    test('la página inicial no trae cursor cuando no hay más', () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final pagina = valorDe(await repo.movimientos(cuenta.id));

      expect(pagina.items, hasLength(3));
      expect(pagina.nextCursor, isNull);
    });

    test(
      'la primera página trae cursor y la segunda lo consume y cierra',
      () async {
        final repo = construir(pageSize: 2);
        final cuenta = await primeraCuenta(repo);

        final p1 = valorDe(await repo.movimientos(cuenta.id));
        expect(p1.items.map((m) => m.transactionId), [
          'tx-demo-1',
          'tx-demo-2',
        ]);
        expect(p1.nextCursor, isNotNull);

        final p2 = valorDe(
          await repo.movimientos(cuenta.id, cursor: p1.nextCursor),
        );
        expect(p2.items.map((m) => m.transactionId), ['tx-demo-3']);
        expect(p2.nextCursor, isNull);
      },
    );

    test('recorrer todas las páginas no repite ni salta movimientos', () async {
      final repo = construir(pageSize: 1);
      final cuenta = await primeraCuenta(repo);

      final vistos = <String>[];
      String? cursor;
      var vueltas = 0;
      do {
        final p = valorDe(await repo.movimientos(cuenta.id, cursor: cursor));
        vistos.addAll(p.items.map((m) => m.transactionId));
        cursor = p.nextCursor;
      } while (cursor != null && ++vueltas < 10);

      expect(vistos, ['tx-demo-1', 'tx-demo-2', 'tx-demo-3']);
    });

    test('los movimientos vienen del más reciente al más antiguo', () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final pagina = valorDe(await repo.movimientos(cuenta.id));

      expect(pagina.items.map((m) => m.transactionId), [
        'tx-demo-1',
        'tx-demo-2',
        'tx-demo-3',
      ]);
      final fechas = pagina.items.map((m) => m.fecha).toList();
      expect(fechas[0].isAfter(fechas[1]), isTrue);
      expect(fechas[1].isAfter(fechas[2]), isTrue);
    });

    test('las fechas se entregan en UTC', () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final pagina = valorDe(await repo.movimientos(cuenta.id));

      expect(pagina.items.every((m) => m.fecha.isUtc), isTrue);
    });

    test('el monto es positivo y el sentido lo da la dirección', () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final items = valorDe(await repo.movimientos(cuenta.id)).items;

      expect(items.every((m) => m.monto > Money.zero(Currency.pen)), isTrue);
      expect(items[0].direccion, MovementDirection.debito);
      expect(items[0].monto, const Money.soles(4500));
      expect(items[0].contraparte, 'B*** D*** A***');
      expect(items[1].direccion, MovementDirection.credito);
      expect(items[1].monto, const Money.soles(120000));
      expect(items[1].contraparte, 'Jenny Marisol Ruiz');
      expect(items[2].direccion, MovementDirection.debito);
      expect(items[2].monto, const Money.soles(1850));
      expect(items[2].contraparte, 'M*** L*** C***');
    });

    test(
      'la contraparte va enmascarada al enviar y completa al recibir',
      () async {
        // El historial es el dato MÁS visible de la app, y es el que destapaba
        // el nombre completo de un desconocido a cambio de un céntimo: quien
        // envía solo puede ver lo que `/directory/resolve` le dio.
        final repo = construir();
        final cuenta = await primeraCuenta(repo);
        final items = valorDe(await repo.movimientos(cuenta.id)).items;
        final enmascarado = RegExp(r'^\S\*\*\*( \S\*\*\*)*$');

        final enviados = items
            .where((m) => m.direccion == MovementDirection.debito)
            .toList();
        final recibidos = items
            .where(
              (m) =>
                  m.direccion == MovementDirection.credito &&
                  m.tipo == MovementKind.transferencia,
            )
            .toList();
        expect(enviados, isNotEmpty);
        expect(recibidos, isNotEmpty);
        for (final m in enviados) {
          expect(
            m.contraparte,
            matches(enmascarado),
            reason: '\${m.transactionId}',
          );
        }
        for (final m in recibidos) {
          expect(
            m.contraparte,
            isNot(contains('***')),
            reason: '\${m.transactionId}',
          );
        }
      },
    );

    test(
      'el saldo posterior del más reciente es el saldo de la cuenta',
      () async {
        final repo = construir();
        final cuenta = await primeraCuenta(repo);
        final items = valorDe(await repo.movimientos(cuenta.id)).items;

        expect(items.first.saldoPosterior, cuenta.saldoContable);
      },
    );

    test(
      'el detalle de tx-demo-1 trae estado y cuenta destino enmascarada',
      () async {
        final MovementDetail d = valorDe(
          await construir().movimiento('tx-demo-1'),
        );

        expect(d.transactionId, 'tx-demo-1');
        expect(d.tipo, MovementKind.transferencia);
        expect(d.estado, 'confirmada');
        expect(d.monto, const Money.soles(4500));
        expect(d.cuentaDestinoMasked, matches(RegExp(r'^••••\d{4}$')));
        expect(d.fecha.isUtc, isTrue);
      },
    );

    test('el detalle coincide con la fila del historial', () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final fila = valorDe(await repo.movimientos(cuenta.id)).items[1];
      final detalle = valorDe(await repo.movimiento(fila.transactionId));

      expect(detalle.monto, fila.monto);
      expect(detalle.direccion, fila.direccion);
      expect(detalle.contraparte, fila.contraparte);
      expect(detalle.saldoPosterior, fila.saldoPosterior);
      expect(detalle.fecha, fila.fecha);
    });

    group('todosLosMovimientos', () {
      test('cada fila dice de qué cuenta es', () async {
        final page = valorDe(await construir().todosLosMovimientos());

        expect(
          page.items.map((m) => m.transactionId),
          containsAll(['tx-demo-1', 'tx-demo-2', 'tx-demo-3']),
        );
        for (final m in page.items) {
          expect(m.cuenta?.id, 'acc-demo-1');
          expect(m.cuenta?.numeroMasked, '••••4521');
          expect(m.cuenta?.tipo, AccountType.ahorro);
          expect(m.cuenta?.moneda, Currency.pen);
          expect(m.entrePropias, isFalse);
        }
      });

      test('respeta el límite y pagina sin repetir ni saltar', () async {
        final repo = construir();
        final primera = valorDe(await repo.todosLosMovimientos(limit: 2));
        expect(primera.items, hasLength(2));
        expect(primera.nextCursor, isNotNull);

        final resto = valorDe(
          await repo.todosLosMovimientos(cursor: primera.nextCursor, limit: 2),
        );
        expect(resto.nextCursor, isNull);
        expect([...primera.items, ...resto.items].map((m) => m.transactionId), [
          'tx-demo-1',
          'tx-demo-2',
          'tx-demo-3',
        ]);
      });

      test(
        'el historial de una cuenta no trae la cuenta en cada fila',
        () async {
          final repo = construir();
          final c = await primeraCuenta(repo);
          final page = valorDe(await repo.movimientos(c.id));
          expect(page.items.every((m) => m.cuenta == null), isTrue);
        },
      );
    });

    test('abrir una cuenta la agrega a la lista', () async {
      final repo = construir();
      final nueva = valorDe(
        await repo.abrir(
          tipo: AccountType.corriente,
          moneda: Currency.usd,
          nombre: 'Viaje',
          pin: '000000',
          idempotencyKey: 'abrir-contrato-01',
        ),
      );

      expect(nueva.tipo, AccountType.corriente);
      expect(nueva.moneda, Currency.usd);
      expect(nueva.nombre, 'Viaje');
      expect(nueva.saldoDisponible, Money.zero(Currency.usd));
      final ids = valorDe(await repo.cuentas()).map((c) => c.id);
      expect(ids, contains(nueva.id));
    });

    test(
      'reintentar la apertura con la misma clave devuelve la misma cuenta',
      () async {
        final repo = construir();
        Future<Account> abrir() async => valorDe(
          await repo.abrir(
            tipo: AccountType.ahorro,
            moneda: Currency.pen,
            pin: '000000',
            idempotencyKey: 'abrir-contrato-02',
          ),
        );
        final a = await abrir();
        final b = await abrir();
        expect(b.id, a.id);
      },
    );

    test('renombrar devuelve la cuenta con su nombre nuevo', () async {
      final repo = construir();
      final c = await primeraCuenta(repo);
      expect(valorDe(await repo.renombrar(c.id, 'Casa')).nombre, 'Casa');
      expect(valorDe(await repo.renombrar(c.id, null)).nombre, isNull);
    });

    test('renombrar una cuenta inexistente es accountNotFound', () async {
      expect(
        falloDe(await construir().renombrar('no-existe', 'X')),
        isA<AccountNotFound>(),
      );
    });
  });
}
