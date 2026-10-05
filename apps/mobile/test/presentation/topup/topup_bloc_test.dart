import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/transfer/application/pending_transfer_actions.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/pending_transfer_store.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/domain/transfer_receipt.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_pending_transfer_store.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:cuycash/presentation/topup/bloc/topup_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../transfer/fake_transfer_repositories.dart';

const _cuentaId = MemoryTransferRepository.cuentaId;
const _monto = Money.fromCentimos(10000);

TopUpBloc _bloc(
  TransferActions actions, {
  PendingTransferActions? pending,
  String userId = 'u1',
  String Function()? newKey,
}) => TopUpBloc(
  actions,
  pending: pending ?? pendientesDePrueba(),
  userId: userId,
  newKey: newKey,
);

TopUpBloc _blocFake(
  FakeTransferRepository repo, {
  PendingTransferActions? pending,
  String userId = 'u1',
  String Function()? newKey,
}) => _bloc(
  TransferActions(repo),
  pending: pending,
  userId: userId,
  newKey: newKey,
);

/// Abierto, con el monto fijado y la clave ya nacida.
Future<TopUpBloc> _preparado(
  FakeTransferRepository repo, {
  PendingTransferActions? pending,
  PendingTransferStore? store,
  String userId = 'u1',
  String Function()? newKey,
  Money monto = _monto,
}) async {
  final b = _blocFake(
    repo,
    pending:
        pending ?? (store == null ? null : pendientesDePrueba(store: store)),
    userId: userId,
    newKey: newKey,
  );
  b.add(const TopUpEvent.opened(cuentaId: _cuentaId));
  b.add(TopUpEvent.amountChanged(monto));
  await b.stream.firstWhere((s) => s.monto == monto);
  return b;
}

String Function() _claves() {
  var n = 0;
  return () => 'clave-generada-${++n}';
}

Future<void> _pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  blocTest<TopUpBloc, TopUpState>(
    'una recarga válida deja la constancia en el estado',
    build: () =>
        _bloc(TransferActions(MemoryTransferRepository(clock: DateTime.now))),
    act: (bloc) {
      bloc.add(const TopUpEvent.opened(cuentaId: _cuentaId));
      bloc.add(TopUpEvent.amountChanged(_monto));
      bloc.add(const TopUpEvent.submitted(pin: '000000'));
    },
    expect: () => [
      isA<TopUpState>(),
      isA<TopUpState>().having((s) => s.monto, 'monto', _monto),
      isA<TopUpState>().having(
        (s) => s.status,
        'status',
        TopUpStatus.submitting,
      ),
      isA<TopUpState>()
          .having((s) => s.status, 'status', TopUpStatus.done)
          .having((s) => s.constancia, 'constancia', isNotNull),
    ],
  );

  blocTest<TopUpBloc, TopUpState>(
    'una recarga NUNCA falla por fondos',
    build: () =>
        _bloc(TransferActions(MemoryTransferRepository(clock: DateTime.now))),
    act: (bloc) {
      bloc.add(const TopUpEvent.opened(cuentaId: _cuentaId));
      bloc.add(TopUpEvent.amountChanged(const Money.fromCentimos(200000)));
      bloc.add(const TopUpEvent.submitted(pin: '000000'));
    },
    verify: (bloc) {
      expect(bloc.state.failure, isNot(isA<InsufficientFunds>()));
      expect(bloc.state.status, TopUpStatus.done);
    },
  );

  for (final centimos in [300000, 200001]) {
    test('$centimos céntimos se rechaza sin llamar al backend', () async {
      final repo = FakeTransferRepository();
      final b = await _preparado(repo, monto: Money.fromCentimos(centimos));
      addTearDown(b.close);

      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();

      expect(b.state.failure, isA<AmountOutOfRange>());
      expect(b.state.status, TopUpStatus.editing);
      expect(repo.recargas, 0);
    });
  }

  test('sin monto no hay envío', () async {
    final repo = FakeTransferRepository();
    final b = _blocFake(repo)
      ..add(const TopUpEvent.opened(cuentaId: _cuentaId));
    addTearDown(b.close);
    await _pump();
    b.add(const TopUpEvent.submitted(pin: '000000'));
    await _pump();
    expect(repo.recargas, 0);
  });

  group('clave de idempotencia', () {
    test('nace al abrir, antes de pulsar nada', () async {
      final b = _blocFake(FakeTransferRepository(), newKey: _claves());
      addTearDown(b.close);
      b.add(const TopUpEvent.opened(cuentaId: _cuentaId));
      await _pump();
      expect(b.state.idempotencyKey, 'clave-generada-1');
    });

    test('dos toques seguidos con repo lento hacen UNA sola llamada', () async {
      final lento = Completer<Result<TransferFailure, TransferReceipt>>();
      final repo = FakeTransferRepository(alRecargar: (_) => lento.future);
      final b = await _preparado(repo);
      addTearDown(() {
        // Si el test falla antes de completar, close() no debe colgarse.
        if (!lento.isCompleted) {
          lento.complete(left(const GlobalFailure.noConnection()));
        }
        b.close();
      });

      b.add(const TopUpEvent.submitted(pin: '000000'));
      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      expect(repo.recargas, 1);

      lento.complete(right(FakeTransferRepository.constanciaDe(_monto)));
      await _pump();
      expect(b.state.status, TopUpStatus.done);
      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      expect(repo.recargas, 1);
    });

    test(
      'con un ALMACÉN lento, dos toques seguidos hacen UNA sola llamada',
      () async {
        final disco = StoreLento();
        final repo = FakeTransferRepository();
        final b = await _preparado(repo, store: disco);
        addTearDown(() {
          if (!disco.abrir.isCompleted) disco.abrir.complete();
          b.close();
        });
        // Abrir también consulta el almacén (hasPending): se libera una vez y
        // se deja pasar; las lecturas siguientes también avanzan.
        b.add(const TopUpEvent.submitted(pin: '000000'));
        b.add(const TopUpEvent.submitted(pin: '000000'));
        await _pump();

        // Con el almacén aún detenido el estado YA es `submitting`: el segundo
        // evento salió sin hacer nada.
        expect(b.state.status, TopUpStatus.submitting);
        expect(repo.recargas, 0);

        disco.abrir.complete();
        await _pump();
        expect(repo.recargas, 1);
        expect(b.state.status, TopUpStatus.done);
      },
    );

    test('un PIN errado conserva monto y clave, y no se sella', () async {
      final repo = FakeTransferRepository(
        alRecargar: (_) async =>
            FakeTransferRepository.falla(const TransferFailure.wrongPin(2)),
      );
      final b = await _preparado(repo, newKey: _claves());
      addTearDown(b.close);

      b.add(const TopUpEvent.submitted(pin: '111111'));
      await _pump();
      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();

      expect(repo.clavesRecarga, ['clave-generada-2', 'clave-generada-2']);
      expect(b.state.outcomeUnknown, isFalse);
      expect(b.state.status, TopUpStatus.editing);
      expect(b.state.monto, _monto);
    });

    test('un amountChanged con el MISMO monto conserva la clave', () async {
      final b = await _preparado(FakeTransferRepository(), newKey: _claves());
      addTearDown(b.close);
      final antes = b.state.idempotencyKey;
      b.add(TopUpEvent.amountChanged(_monto));
      await _pump();
      expect(b.state.idempotencyKey, antes);
    });

    test('cambiar el monto cambia la clave', () async {
      final repo = FakeTransferRepository();
      final b = await _preparado(repo, newKey: _claves());
      addTearDown(b.close);
      final antes = b.state.idempotencyKey;
      b.add(TopUpEvent.amountChanged(const Money.fromCentimos(5000)));
      await _pump();
      expect(b.state.idempotencyKey, isNot(antes));
    });
  });

  group('resultado desconocido', () {
    for (final (nombre, falla) in [
      ('red', const TransferFailure.network()),
      ('429', const TransferFailure.rateLimited(Duration(seconds: 30))),
      ('inesperado', const TransferFailure.unexpected()),
    ]) {
      test(
        '$nombre sella la intención y el reintento lleva la MISMA clave',
        () async {
          final repo = FakeTransferRepository(
            alRecargar: (n) async => n == 1
                ? FakeTransferRepository.falla(falla)
                : FakeTransferRepository.falla(const TransferFailure.network()),
          );
          final b = await _preparado(repo, newKey: _claves());
          addTearDown(b.close);

          b.add(const TopUpEvent.submitted(pin: '000000'));
          await _pump();
          expect(b.state.outcomeUnknown, isTrue);

          // Sellada: el monto ya no se edita.
          b.add(TopUpEvent.amountChanged(const Money.fromCentimos(5000)));
          await _pump();
          expect(b.state.monto, _monto);

          b.add(const TopUpEvent.submitted(pin: '000000'));
          await _pump();
          expect(repo.clavesRecarga, ['clave-generada-2', 'clave-generada-2']);
        },
      );
    }

    test('una vez confirmada tras el reintento la entrada se borra', () async {
      final store = MemoryPendingTransferStore();
      final pending = pendientesDePrueba(store: store);
      final repo = FakeTransferRepository(
        alRecargar: (n) async => n == 1
            ? FakeTransferRepository.falla(const TransferFailure.network())
            : right(FakeTransferRepository.constanciaDe(_monto)),
      );
      final b = await _preparado(repo, pending: pending);
      addTearDown(b.close);

      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      expect(await pending.hasPending('u1'), isTrue);

      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      expect(b.state.status, TopUpStatus.done);
      expect(await pending.hasPending('u1'), isFalse);
    });

    test('un 409 es definitivo: borra la entrada', () async {
      final pending = pendientesDePrueba();
      final repo = FakeTransferRepository(
        alRecargar: (_) async => FakeTransferRepository.falla(
          const TransferFailure.idempotencyKeyReused(),
        ),
      );
      final b = await _preparado(repo, pending: pending);
      addTearDown(b.close);
      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      expect(await pending.hasPending('u1'), isFalse);
    });
  });

  group('persistencia de la clave', () {
    test(
      'tras un resultado desconocido, un bloc NUEVO recupera la clave',
      () async {
        final store = MemoryPendingTransferStore();
        final repo = FakeTransferRepository(
          alRecargar: (n) async => n == 1
              ? FakeTransferRepository.falla(const TransferFailure.network())
              : right(FakeTransferRepository.constanciaDe(_monto)),
        );
        final primero = await _preparado(
          repo,
          pending: pendientesDePrueba(store: store),
          newKey: _claves(),
        );
        primero.add(const TopUpEvent.submitted(pin: '000000'));
        await _pump();
        await primero.close(); // el usuario sale / mata la app

        final segundo = await _preparado(
          repo,
          pending: pendientesDePrueba(store: store),
          newKey: () => 'clave-NUEVA',
        );
        addTearDown(segundo.close);
        // Al abrir ya avisa de la operación sin resolver.
        expect(segundo.state.pendingElsewhere, isTrue);

        segundo.add(const TopUpEvent.submitted(pin: '000000'));
        await _pump();

        expect(repo.clavesRecarga, ['clave-generada-2', 'clave-generada-2']);
        expect(segundo.state.status, TopUpStatus.done);
      },
    );

    test('con otro monto no se recupera: clave propia, con aviso', () async {
      final store = MemoryPendingTransferStore();
      final repo = FakeTransferRepository(
        alRecargar: (n) async => n == 1
            ? FakeTransferRepository.falla(const TransferFailure.network())
            : right(FakeTransferRepository.constanciaDe(_monto)),
      );
      final primero = await _preparado(
        repo,
        pending: pendientesDePrueba(store: store),
      );
      primero.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      await primero.close();

      final segundo = await _preparado(
        repo,
        pending: pendientesDePrueba(store: store),
        monto: const Money.fromCentimos(2000),
        newKey: () => 'clave-NUEVA',
      );
      addTearDown(segundo.close);
      expect(segundo.state.pendingElsewhere, isTrue);
      expect(segundo.state.outcomeUnknown, isFalse);
      segundo.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      expect(repo.clavesRecarga.last, 'clave-NUEVA');
    });

    test(
      'la clave de un usuario no se recupera en la sesión de otro',
      () async {
        final store = MemoryPendingTransferStore();
        final repo = FakeTransferRepository(
          alRecargar: (n) async => n == 1
              ? FakeTransferRepository.falla(const TransferFailure.network())
              : right(FakeTransferRepository.constanciaDe(_monto)),
        );
        final a = await _preparado(
          repo,
          pending: pendientesDePrueba(store: store),
          userId: 'ana',
        );
        a.add(const TopUpEvent.submitted(pin: '000000'));
        await _pump();
        await a.close();

        final b = await _preparado(
          repo,
          pending: pendientesDePrueba(store: store),
          userId: 'beto',
          newKey: () => 'clave-de-beto',
        );
        addTearDown(b.close);
        expect(b.state.pendingElsewhere, isFalse);
        b.add(const TopUpEvent.submitted(pin: '000000'));
        await _pump();
        expect(repo.clavesRecarga.last, 'clave-de-beto');
      },
    );

    test('una entrada de más de 24 h no revive', () async {
      final store = MemoryPendingTransferStore();
      final huella = PendingTransferActions.huellaRecarga(
        cuentaId: _cuentaId,
        monto: _monto,
      );
      await sembrarPendiente(
        store,
        huella: huella,
        creada: DateTime.utc(2026, 10, 4, 17),
      );
      final repo = FakeTransferRepository();
      final b = await _preparado(
        repo,
        pending: pendientesDePrueba(store: store),
        newKey: () => 'clave-NUEVA',
      );
      addTearDown(b.close);
      b.add(const TopUpEvent.submitted(pin: '000000'));
      await _pump();
      expect(repo.clavesRecarga, ['clave-NUEVA']);
      expect(b.state.outcomeUnknown, isFalse);
    });

    test(
      'si no se pudo anotar la clave, queda marcado (aviso fuerte)',
      () async {
        final repo = FakeTransferRepository(
          alRecargar: (_) async =>
              FakeTransferRepository.falla(const TransferFailure.network()),
        );
        final b = await _preparado(
          repo,
          pending: pendientesDePrueba(store: StoreQueNoEscribe()),
        );
        addTearDown(b.close);
        b.add(const TopUpEvent.submitted(pin: '000000'));
        await _pump();
        // El envío NO se tumba por un fallo de disco.
        expect(repo.recargas, 1);
        expect(b.state.keyUnsaved, isTrue);
        expect(b.state.outcomeUnknown, isTrue);
      },
    );

    test('las huellas de recarga y de envío no chocan', () {
      final recarga = PendingTransferActions.huellaRecarga(
        cuentaId: 'c1',
        monto: _monto,
      );
      final envio = PendingTransferActions.huella(
        cuentaId: 'c1',
        destinatarioDni: '87654321',
        monto: _monto,
      );
      expect(recarga, isNot(envio));
      expect(recarga, startsWith('recarga|'));
    });
  });
}
