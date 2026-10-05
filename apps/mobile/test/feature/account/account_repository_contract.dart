import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
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
/// backend simulado con el JSON real del router.
void probarContratoDeCuentas(
  String nombre,
  AccountRepository Function() construir,
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
      expect(cuentas.first.moneda, 'PEN');
      expect(cuentas.first.estado, 'activa');
    });

    test('el saldo es Money en céntimos exactos', () async {
      final c = await primeraCuenta(construir());

      expect(c.saldoDisponible, const Money.fromCentimos(125040));
      expect(c.saldoContable, const Money.fromCentimos(125040));
    });

    test('el número enmascarado son los últimos cuatro dígitos', () async {
      final c = await primeraCuenta(construir());

      expect(c.numeroMasked,
          '••••${c.numero.substring(c.numero.length - 4)}');
      expect(c.numeroMasked, '••••4521');
    });

    test('una cuenta inexistente devuelve accountNotFound, no una excepción',
        () async {
      final r = await construir().movimientos('no-existe');

      expect(falloDe(r), isA<AccountNotFound>());
    });

    test('el detalle de un movimiento ajeno devuelve un failure', () async {
      final r = await construir().movimiento('tx-ajena');

      expect(falloDe(r), isA<AccountNotFound>());
    });

    test('la página inicial no trae cursor cuando no hay más', () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final pagina = valorDe(await repo.movimientos(cuenta.id));

      expect(pagina.items, hasLength(3));
      expect(pagina.nextCursor, isNull);
    });

    test('los movimientos vienen del más reciente al más antiguo', () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final pagina = valorDe(await repo.movimientos(cuenta.id));

      expect(
        pagina.items.map((m) => m.transactionId),
        ['tx-demo-1', 'tx-demo-2', 'tx-demo-3'],
      );
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

      expect(items.every((m) => m.monto > Money.zero), isTrue);
      expect(items[0].direccion, MovementDirection.debito);
      expect(items[0].monto, const Money.fromCentimos(4500));
      expect(items[0].contraparte, 'Bodega Don Aurelio');
      expect(items[1].direccion, MovementDirection.credito);
      expect(items[1].monto, const Money.fromCentimos(120000));
      expect(items[1].contraparte, 'Jenny Marisol Ruiz');
      expect(items[2].direccion, MovementDirection.debito);
      expect(items[2].monto, const Money.fromCentimos(1850));
      expect(items[2].contraparte, 'Menú La Cuchara');
    });

    test('el saldo posterior del más reciente es el saldo de la cuenta',
        () async {
      final repo = construir();
      final cuenta = await primeraCuenta(repo);
      final items = valorDe(await repo.movimientos(cuenta.id)).items;

      expect(items.first.saldoPosterior, cuenta.saldoContable);
    });

    test('el detalle de tx-demo-1 trae estado y cuenta destino enmascarada',
        () async {
      final MovementDetail d =
          valorDe(await construir().movimiento('tx-demo-1'));

      expect(d.transactionId, 'tx-demo-1');
      expect(d.tipo, MovementKind.transferencia);
      expect(d.estado, 'confirmada');
      expect(d.monto, const Money.fromCentimos(4500));
      expect(d.cuentaDestinoMasked, matches(RegExp(r'^••••\d{4}$')));
      expect(d.fecha.isUtc, isTrue);
    });

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
  });
}
