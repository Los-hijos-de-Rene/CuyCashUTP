import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/transfer/application/pending_transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/pending_transfer_store.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_pending_transfer_store.dart';
import 'package:cuycash/feature/transfer/infrastructure/shared_prefs_pending_transfer_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final huella = PendingTransferActions.huella(
    cuentaId: 'acc-1',
    destinatarioDni: '87654321',
    monto: const Money.fromCentimos(5000),
    motivo: 'Almuerzo',
  );

  void contrato(String nombre, PendingTransferStore Function() crear) {
    group('$nombre · contrato', () {
      late DateTime ahora;
      late PendingTransferActions acciones;
      late PendingTransferStore store;

      setUp(() {
        SharedPreferences.setMockInitialValues({});
        ahora = DateTime.utc(2026, 10, 5, 18);
        store = crear();
        acciones = PendingTransferActions(store, clock: () => ahora);
      });

      test(
        'lo guardado se recupera, incluso con otra instancia del store',
        () async {
          await acciones.remember('u1', huella, 'clave-1');

          final otra = PendingTransferActions(crear(), clock: () => ahora);
          // Con el store en memoria "otra instancia" no comparte datos; solo el
          // persistente debe sobrevivir a ello.
          final recuperada = await acciones.recover('u1', huella);
          expect(recuperada, 'clave-1');
          if (store is SharedPrefsPendingTransferStore) {
            expect(await otra.recover('u1', huella), 'clave-1');
          }
        },
      );

      test('está separado por usuario', () async {
        await acciones.remember('u1', huella, 'clave-1');

        expect(await acciones.recover('u2', huella), isNull);
      });

      test('una intención distinta no recupera la clave', () async {
        await acciones.remember('u1', huella, 'clave-1');
        final otra = PendingTransferActions.huella(
          cuentaId: 'acc-1',
          destinatarioDni: '87654321',
          monto: const Money.fromCentimos(4000),
          motivo: 'Almuerzo',
        );

        expect(await acciones.recover('u1', otra), isNull);
      });

      test('caduca a las 24 h', () async {
        await acciones.remember('u1', huella, 'clave-1');

        ahora = ahora.add(const Duration(hours: 23, minutes: 59));
        expect(await acciones.recover('u1', huella), 'clave-1');
        ahora = ahora.add(const Duration(minutes: 2));
        expect(await acciones.recover('u1', huella), isNull);
      });

      test('reintentar no rejuvenece la entrada', () async {
        await acciones.remember('u1', huella, 'clave-1');
        ahora = ahora.add(const Duration(hours: 20));
        await acciones.remember('u1', huella, 'clave-1');
        ahora = ahora.add(const Duration(hours: 5));

        expect(await acciones.recover('u1', huella), isNull);
      });

      test('forget la borra; las demás intenciones se quedan', () async {
        await acciones.remember('u1', huella, 'clave-1');
        await acciones.remember('u1', 'otra', 'clave-2');

        await acciones.forget('u1', huella);

        expect(await acciones.recover('u1', huella), isNull);
        expect(await acciones.recover('u1', 'otra'), 'clave-2');
      });

      test('al guardar se limpian las caducadas', () async {
        await acciones.remember('u1', 'vieja', 'clave-v');
        ahora = ahora.add(const Duration(hours: 30));
        await acciones.remember('u1', huella, 'clave-1');

        expect((await store.readAll('u1')).keys, [huella]);
      });
    });
  }

  contrato('MemoryPendingTransferStore', MemoryPendingTransferStore.new);
  contrato(
    'SharedPrefsPendingTransferStore',
    () => const SharedPrefsPendingTransferStore(),
  );

  test('un valor ilegible en disco se trata como vacío, sin lanzar', () async {
    SharedPreferences.setMockInitialValues({
      'cuycash.pending_transfers.v1.u1': '{no es json',
    });

    expect(
      await const SharedPrefsPendingTransferStore().readAll('u1'),
      isEmpty,
    );
  });
}
