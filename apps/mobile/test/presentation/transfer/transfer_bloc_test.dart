import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/recipient.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_pending_transfer_store.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/domain/transfer_receipt.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'fake_transfer_repositories.dart';

const _cuenta = Account(
  id: MemoryTransferRepository.cuentaId,
  numero: '19100000004521',
  tipo: 'ahorro',
  moneda: 'PEN',
  estado: 'activa',
  saldoDisponible: Money.fromCentimos(125040),
  saldoContable: Money.fromCentimos(125040),
);

const _monto = Money.fromCentimos(5000);

/// Listo para confirmar: destinatario, monto y clave ya fijados.
const _listo = TransferState(
  status: TransferStatus.ready,
  cuenta: _cuenta,
  destinatario: destinatarioDePrueba,
  monto: _monto,
  idempotencyKey: 'clave-fija-0001',
);

TransferBloc _bloc(FakeTransferRepository repo, {String Function()? newKey}) =>
    TransferBloc(
      TransferActions(repo),
      pending: pendientesDePrueba(),
      userId: 'u1',
      newKey: newKey,
    );

/// Lleva un bloc por el flujo real hasta la confirmación abierta, sin sembrar
/// el estado a mano.
Future<TransferBloc> _preparado(
  FakeTransferRepository repo, {
  String Function()? newKey,
}) async {
  final b = _bloc(repo, newKey: newKey);
  b.add(const TransferEvent.started(_cuenta));
  b.add(const TransferEvent.recipientRequested('87654321'));
  await b.stream.firstWhere((s) => s.status == TransferStatus.ready);
  b.add(const TransferEvent.amountEntered(monto: _monto));
  b.add(const TransferEvent.confirmationOpened());
  await b.stream.firstWhere((s) => s.idempotencyKey.isNotEmpty);
  return b;
}

/// Un contador de claves distinto en cada llamada: así un test detecta si el
/// bloc llegara a pedir una clave nueva.
String Function() _claves() {
  var n = 0;
  return () => 'clave-generada-${++n}';
}

void main() {
  group('búsqueda del destinatario', () {
    blocTest<TransferBloc, TransferState>(
      'un DNI conocido deja al destinatario listo',
      build: () => _bloc(FakeTransferRepository()),
      seed: () => const TransferState(cuenta: _cuenta),
      act: (b) => b.add(const TransferEvent.recipientRequested('87654321')),
      expect: () => [
        isA<TransferState>().having(
          (s) => s.status,
          'status',
          TransferStatus.resolving,
        ),
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.ready)
            .having(
              (s) => s.destinatario,
              'destinatario',
              destinatarioDePrueba,
            ),
      ],
    );

    for (final (nombre, falla) in [
      ('recipientNotFound', const TransferFailure.recipientNotFound()),
      ('selfTransfer', const TransferFailure.selfTransfer()),
      ('rateLimited', const TransferFailure.rateLimited(Duration(seconds: 30))),
      ('network', const TransferFailure.network()),
      ('unexpected', const TransferFailure.unexpected()),
    ]) {
      blocTest<TransferBloc, TransferState>(
        'una búsqueda que falla con $nombre queda en idle con el failure',
        build: () => _bloc(
          FakeTransferRepository(
            alResolver: (_) async => FakeTransferRepository.falla(falla),
          ),
        ),
        act: (b) => b.add(const TransferEvent.recipientRequested('11111111')),
        verify: (b) {
          expect(b.state.status, TransferStatus.idle);
          expect(b.state.failure, same(falla));
          expect(b.state.destinatario, isNull);
        },
      );
    }

    blocTest<TransferBloc, TransferState>(
      'sin conexión se aplana a network',
      build: () => _bloc(
        FakeTransferRepository(
          alResolver: (_) async => left(const GlobalFailure.noConnection()),
        ),
      ),
      act: (b) => b.add(const TransferEvent.recipientRequested('11111111')),
      verify: (b) => expect(b.state.failure, isA<TransferNetworkFailure>()),
    );

    test('la respuesta de un DNI que ya se editó se descarta', () async {
      final primera = Completer<Result<TransferFailure, Recipient>>();
      final repo = FakeTransferRepository(alResolver: (_) => primera.future);
      final b = _bloc(repo);
      addTearDown(b.close);

      b.add(const TransferEvent.recipientRequested('87654321'));
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferEvent.recipientCleared());
      await Future<void>.delayed(Duration.zero);
      primera.complete(right(destinatarioDePrueba));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(b.state.destinatario, isNull);
      expect(b.state.status, TransferStatus.idle);
    });
  });

  group('clave de idempotencia', () {
    blocTest<TransferBloc, TransferState>(
      'se fija al ABRIR la confirmación, antes de cualquier envío',
      build: () => _bloc(FakeTransferRepository(), newKey: _claves()),
      seed: () => _listo.copyWith(idempotencyKey: ''),
      act: (b) => b.add(const TransferEvent.confirmationOpened()),
      verify: (b) => expect(b.state.idempotencyKey, 'clave-generada-1'),
    );

    test('NO cambia entre un envío fallido por red y su reintento: '
        'el repositorio recibe la misma clave las dos veces', () async {
      final repo = FakeTransferRepository(
        alEnviar: (n) async => n == 1
            ? FakeTransferRepository.falla(const TransferFailure.network())
            : right(FakeTransferRepository.constanciaDe(_monto)),
      );
      final b = await _preparado(repo, newKey: _claves());
      addTearDown(b.close);

      final fijada = b.state.idempotencyKey;
      expect(fijada, isNotEmpty);

      b.add(const TransferEvent.submitted(pin: '000000'));
      await b.stream.firstWhere((s) => s.failure != null);
      expect(b.state.failure, isA<TransferNetworkFailure>());
      expect(b.state.idempotencyKey, fijada);

      b.add(const TransferEvent.submitted(pin: '000000'));
      await b.stream.firstWhere((s) => s.status == TransferStatus.done);

      expect(repo.claves, [fijada, fijada]);
      expect(b.state.idempotencyKey, fijada);
    });

    blocTest<TransferBloc, TransferState>(
      'volver a abrir la confirmación con la misma intención conserva la clave',
      build: () => _bloc(FakeTransferRepository(), newKey: _claves()),
      seed: () => _listo,
      act: (b) {
        b.add(const TransferEvent.confirmationOpened());
        b.add(const TransferEvent.confirmationOpened());
      },
      verify: (b) => expect(b.state.idempotencyKey, 'clave-fija-0001'),
    );

    blocTest<TransferBloc, TransferState>(
      'si el usuario vuelve y deja el mismo monto, la clave sigue siendo la misma',
      build: () => _bloc(FakeTransferRepository(), newKey: _claves()),
      seed: () => _listo,
      act: (b) => b.add(const TransferEvent.amountEntered(monto: _monto)),
      verify: (b) => expect(b.state.idempotencyKey, 'clave-fija-0001'),
    );

    blocTest<TransferBloc, TransferState>(
      'si cambia el monto la intención es otra: la clave se descarta (daría 409)',
      build: () => _bloc(FakeTransferRepository(), newKey: _claves()),
      seed: () => _listo,
      act: (b) => b.add(
        const TransferEvent.amountEntered(monto: Money.fromCentimos(7000)),
      ),
      verify: (b) => expect(b.state.idempotencyKey, isEmpty),
    );
  });

  group('un envío en vuelo no admite otro', () {
    test(
      'tres TransferSubmitted seguidos con un repositorio lento hacen UNA llamada',
      () async {
        final respuesta = Completer<Result<TransferFailure, TransferReceipt>>();
        final repo = FakeTransferRepository(alEnviar: (_) => respuesta.future);
        final b = await _preparado(repo, newKey: () => 'clave-fija-0001');
        addTearDown(b.close);

        b.add(const TransferEvent.submitted(pin: '000000'));
        b.add(const TransferEvent.submitted(pin: '000000'));
        b.add(const TransferEvent.submitted(pin: '000000'));
        await Future<void>.delayed(Duration.zero);

        expect(repo.llamadas, 1);
        expect(b.state.status, TransferStatus.submitting);

        respuesta.complete(right(FakeTransferRepository.constanciaDe(_monto)));
        await b.stream.firstWhere((s) => s.status == TransferStatus.done);
        expect(repo.llamadas, 1);
      },
    );

    test(
      'una vez hecho el envío, otro intento tampoco llega al repositorio',
      () async {
        final repo = FakeTransferRepository();
        final b = await _preparado(repo, newKey: () => 'clave-fija-0001');
        addTearDown(b.close);

        b.add(const TransferEvent.submitted(pin: '000000'));
        await b.stream.firstWhere((s) => s.status == TransferStatus.done);
        b.add(const TransferEvent.submitted(pin: '000000'));
        await Future<void>.delayed(Duration.zero);

        expect(repo.llamadas, 1);
      },
    );
  });

  group('un envío exitoso', () {
    blocTest<TransferBloc, TransferState>(
      'deja la constancia y conserva al destinatario para mostrarlo',
      build: () => _bloc(FakeTransferRepository()),
      seed: () => _listo,
      act: (b) => b.add(const TransferEvent.submitted(pin: '000000')),
      expect: () => [
        isA<TransferState>().having(
          (s) => s.status,
          'status',
          TransferStatus.submitting,
        ),
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.done)
            .having((s) => s.constancia?.transactionId, 'tx', 'tx-test-1')
            .having(
              (s) => s.destinatario,
              'destinatario',
              destinatarioDePrueba,
            ),
      ],
    );

    blocTest<TransferBloc, TransferState>(
      'contra el repositorio en memoria: PIN válido envía y descuenta',
      build: () => TransferBloc(
        pending: pendientesDePrueba(),
        userId: 'u1',
        TransferActions(
          MemoryTransferRepository(clock: () => DateTime.utc(2026, 10, 5, 18)),
        ),
      ),
      seed: () => _listo,
      act: (b) => b.add(const TransferEvent.submitted(pin: '000000')),
      verify: (b) => expect(b.state.status, TransferStatus.done),
    );
  });

  group('un PIN errado', () {
    blocTest<TransferBloc, TransferState>(
      'conserva el monto, el destinatario y la clave (contra el repo en memoria)',
      build: () => TransferBloc(
        pending: pendientesDePrueba(),
        userId: 'u1',
        TransferActions(
          MemoryTransferRepository(clock: () => DateTime.utc(2026, 10, 5, 18)),
        ),
      ),
      seed: () => _listo.copyWith(destinatario: _destinoMemoria),
      act: (b) => b.add(const TransferEvent.submitted(pin: '111111')),
      expect: () => [
        isA<TransferState>().having(
          (s) => s.status,
          'status',
          TransferStatus.submitting,
        ),
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.ready)
            .having((s) => s.failure, 'failure', isA<WrongPin>())
            .having((s) => s.monto, 'monto', _monto)
            .having((s) => s.destinatario, 'destinatario', _destinoMemoria)
            .having((s) => s.idempotencyKey, 'clave', 'clave-fija-0001'),
      ],
    );
  });

  group('un caso por failure del envío', () {
    final casos = <(String, TransferFailure)>[
      ('insufficientFunds', const TransferFailure.insufficientFunds()),
      ('recipientNotFound', const TransferFailure.recipientNotFound()),
      ('selfTransfer', const TransferFailure.selfTransfer()),
      ('wrongPin', const TransferFailure.wrongPin(3)),
      (
        'identifierLocked',
        TransferFailure.identifierLocked(DateTime.utc(2026, 10, 5, 19)),
      ),
      (
        'deviceLocked',
        TransferFailure.deviceLocked(DateTime.utc(2026, 10, 5, 19)),
      ),
      ('rateLimited', const TransferFailure.rateLimited(Duration(seconds: 9))),
      ('amountOutOfRange', const TransferFailure.amountOutOfRange()),
      ('accountBlocked', const TransferFailure.accountBlocked()),
      ('idempotencyKeyReused', const TransferFailure.idempotencyKeyReused()),
      ('accountNotFound', const TransferFailure.accountNotFound()),
      ('unauthenticated', const TransferFailure.unauthenticated()),
      ('network', const TransferFailure.network()),
      ('unexpected', const TransferFailure.unexpected()),
    ];
    for (final (nombre, falla) in casos) {
      blocTest<TransferBloc, TransferState>(
        '$nombre: vuelve a ready con el failure y todo lo elegido intacto',
        build: () => _bloc(
          FakeTransferRepository(
            alEnviar: (_) async => FakeTransferRepository.falla(falla),
          ),
        ),
        seed: () => _listo,
        act: (b) => b.add(const TransferEvent.submitted(pin: '000000')),
        verify: (b) {
          expect(b.state.status, TransferStatus.ready);
          expect(b.state.failure, same(falla));
          expect(b.state.monto, _monto);
          expect(b.state.destinatario, destinatarioDePrueba);
          expect(b.state.idempotencyKey, 'clave-fija-0001');
          expect(b.state.constancia, isNull);
        },
      );
    }
  });

  group('resultado desconocido: la intención queda sellada', () {
    Future<(TransferBloc, FakeTransferRepository)> tras(
      TransferFailure falla,
    ) async {
      final repo = FakeTransferRepository(
        alEnviar: (n) async => n == 1
            ? FakeTransferRepository.falla(falla)
            : right(FakeTransferRepository.constanciaDe(_monto)),
      );
      final b = await _preparado(repo, newKey: _claves());
      b.add(const TransferEvent.submitted(pin: '000000'));
      await b.stream.firstWhere((s) => s.failure != null);
      return (b, repo);
    }

    test('REPRODUCCIÓN: fallo de red, atrás, otro monto y reenvío NO puede '
        'producir una segunda clave', () async {
      final (b, repo) = await tras(const TransferFailure.network());
      addTearDown(b.close);
      final primera = b.state.idempotencyKey;

      // El usuario retrocede a la pantalla de monto y lo baja.
      b.add(const TransferEvent.amountEntered(monto: Money.fromCentimos(4000)));
      await Future<void>.delayed(Duration.zero);
      b.add(const TransferEvent.confirmationOpened());
      b.add(const TransferEvent.submitted(pin: '000000'));
      await b.stream.firstWhere((s) => s.status == TransferStatus.done);

      expect(b.state.monto, _monto, reason: 'el monto no pudo cambiar');
      expect(repo.claves, [primera, primera]);
    });

    for (final falla in [
      const TransferFailure.network(),
      const TransferFailure.unexpected(),
      const TransferFailure.rateLimited(null),
    ]) {
      test(
        '${falla.runtimeType}: monto, destinatario y DNI no se editan',
        () async {
          final (b, _) = await tras(falla);
          addTearDown(b.close);
          final antes = b.state;
          expect(antes.status, TransferStatus.ready);

          b.add(
            const TransferEvent.amountEntered(monto: Money.fromCentimos(1)),
          );
          b.add(const TransferEvent.recipientRequested('43219876'));
          b.add(const TransferEvent.recipientCleared());
          await Future<void>.delayed(Duration.zero);

          expect(b.state, antes);
        },
      );
    }

    test(
      'un fallo definitivo (PIN errado) no sella: se puede editar',
      () async {
        final (b, _) = await tras(const TransferFailure.wrongPin(3));
        addTearDown(b.close);
        expect(b.state.outcomeUnknown, isFalse);

        b.add(
          const TransferEvent.amountEntered(monto: Money.fromCentimos(4000)),
        );
        await Future<void>.delayed(Duration.zero);
        expect(b.state.monto, const Money.fromCentimos(4000));
      },
    );
  });

  group('la clave sobrevive al flujo, ligada a la intención', () {
    late MemoryPendingTransferStore store;
    late DateTime ahora;
    late String Function() claves;

    setUp(() {
      claves = _claves();
      store = MemoryPendingTransferStore();
      ahora = DateTime.utc(2026, 10, 5, 18);
    });

    TransferActions acciones(FakeTransferRepository repo) =>
        TransferActions(repo);

    /// Un flujo NUEVO (bloc nuevo = salir al inicio y reentrar, o matar la
    /// app y reabrirla) hasta la confirmación abierta.
    Future<TransferBloc> flujo(
      FakeTransferRepository repo, {
      String userId = 'u1',
      Money monto = _monto,
      String? motivo,
      String Function()? newKey,
    }) async {
      final b = TransferBloc(
        acciones(repo),
        pending: pendientesDePrueba(store: store, clock: () => ahora),
        userId: userId,
        newKey: newKey ?? claves,
      );
      addTearDown(b.close);
      b.add(const TransferEvent.started(_cuenta));
      b.add(const TransferEvent.recipientRequested('87654321'));
      await b.stream.firstWhere((s) => s.status == TransferStatus.ready);
      b.add(TransferEvent.amountEntered(monto: monto, motivo: motivo));
      b.add(const TransferEvent.confirmationOpened());
      await b.stream.firstWhere((s) => s.idempotencyKey.isNotEmpty);
      return b;
    }

    FakeTransferRepository caeEnRed() => FakeTransferRepository(
      alEnviar: (n) async => n == 1
          ? FakeTransferRepository.falla(const TransferFailure.network())
          : right(FakeTransferRepository.constanciaDe(_monto)),
    );

    Future<void> enviar(
      TransferBloc b,
      bool Function(TransferState) hasta,
    ) async {
      b.add(const TransferEvent.submitted(pin: '000000'));
      await b.stream.firstWhere(hasta);
    }

    test(
      'VARIANTE 1 y 2 (volver al inicio y reentrar / matar la app): la misma '
      'intención recupera la MISMA clave y vuelve sellada',
      () async {
        final repo1 = caeEnRed();
        final a = await flujo(repo1);
        await enviar(a, (s) => s.failure != null);
        final primera = a.state.idempotencyKey;
        await a.close(); // el ShellRoute muere: el bloc y su memoria también.

        final repo2 = FakeTransferRepository();
        // Su generador daría otra clave si se la pidieran: no debe pedirla.
        final b = await flujo(repo2, newKey: () => 'clave-NUEVA-prohibida');

        expect(b.state.idempotencyKey, primera);
        expect(b.state.outcomeUnknown, isTrue);
        await enviar(b, (s) => s.status == TransferStatus.done);
        expect(repo2.claves, [primera]);
      },
    );

    test('VARIANTE 3 (la sesión vence a mitad): la clave ya estaba guardada '
        'antes de que el envío saliera', () async {
      final nunca = Completer<Result<TransferFailure, TransferReceipt>>();
      final repo = FakeTransferRepository(alEnviar: (_) => nunca.future);
      final a = await flujo(repo);
      a.add(const TransferEvent.submitted(pin: '000000'));
      await a.stream.firstWhere((s) => s.status == TransferStatus.submitting);
      final enVuelo = a.state.idempotencyKey;
      await Future<void>.delayed(Duration.zero);
      await a.close(); // el redirect global destruye el flujo en vuelo

      final b = await flujo(FakeTransferRepository());
      expect(b.state.idempotencyKey, enVuelo);
    });

    test(
      'VARIANTE 4 (401): la clave NO se olvida, porque el 401 sin `code` de un '
      'gateway puede llegar DESPUÉS de que la petición tocara la app',
      () async {
        final repo1 = FakeTransferRepository(
          alEnviar: (_) async => FakeTransferRepository.falla(
            const TransferFailure.unauthenticated(),
          ),
        );
        final a = await flujo(repo1);
        await enviar(a, (s) => s.failure != null);
        final primera = a.state.idempotencyKey;
        await a.close(); // el 401 cierra la sesión y mata el flujo.

        final repo2 = FakeTransferRepository();
        // Si la clave se hubiera olvidado, aquí nacería una nueva y el envío
        // se cobraría DOS veces.
        final b = await flujo(repo2, newKey: () => 'clave-NUEVA-prohibida');

        expect(b.state.idempotencyKey, primera);
        await enviar(b, (s) => s.status == TransferStatus.done);
        expect(repo2.claves, [primera]);
      },
    );

    test(
      'una intención distinta (otro monto) genera otra clave, sin sello',
      () async {
        final a = await flujo(caeEnRed());
        await enviar(a, (s) => s.failure != null);
        final primera = a.state.idempotencyKey;
        await a.close();

        final b = await flujo(
          FakeTransferRepository(),
          monto: const Money.fromCentimos(4000),
        );

        expect(b.state.idempotencyKey, isNot(primera));
        expect(b.state.outcomeUnknown, isFalse);
      },
    );

    test('la entrada caduca: pasadas 24 h la intención es nueva', () async {
      final a = await flujo(caeEnRed());
      await enviar(a, (s) => s.failure != null);
      final primera = a.state.idempotencyKey;
      await a.close();

      ahora = ahora.add(const Duration(hours: 25));
      final b = await flujo(FakeTransferRepository());

      expect(b.state.idempotencyKey, isNot(primera));
      expect(b.state.outcomeUnknown, isFalse);
    });

    test('la clave de un usuario no la recupera otro', () async {
      final a = await flujo(caeEnRed());
      await enviar(a, (s) => s.failure != null);
      final primera = a.state.idempotencyKey;
      await a.close();

      final b = await flujo(FakeTransferRepository(), userId: 'u2');

      expect(b.state.idempotencyKey, isNot(primera));
    });

    test(
      'un envío confirmado borra la entrada: repetirlo es otro envío',
      () async {
        final a = await flujo(FakeTransferRepository());
        await enviar(a, (s) => s.status == TransferStatus.done);
        final primera = a.state.idempotencyKey;
        await a.close();

        final b = await flujo(FakeTransferRepository());

        expect(b.state.idempotencyKey, isNot(primera));
        expect(b.state.outcomeUnknown, isFalse);
      },
    );

    test('un fallo definitivo (saldo) borra la entrada', () async {
      final a = await flujo(
        FakeTransferRepository(
          alEnviar: (_) async => FakeTransferRepository.falla(
            const TransferFailure.insufficientFunds(),
          ),
        ),
      );
      await enviar(a, (s) => s.failure != null);
      final primera = a.state.idempotencyKey;
      await a.close();

      final b = await flujo(FakeTransferRepository());

      expect(b.state.idempotencyKey, isNot(primera));
    });

    test('R2: tras matar la app, el MISMO pago con otro motivo no se reconoce, '
        'pero la confirmación avisa que hay un envío sin resolver', () async {
      final a = await flujo(caeEnRed(), motivo: 'Cena');
      await enviar(a, (s) => s.failure != null);
      final primera = a.state.idempotencyKey;
      await a.close();

      final b = await flujo(FakeTransferRepository(), motivo: 'cena');

      expect(b.state.pendingElsewhere, isTrue);
      // No se sella: no se sabe si es la misma intención.
      expect(b.state.outcomeUnknown, isFalse);
      expect(b.state.idempotencyKey, isNot(primera));
    });

    test('sin envíos pendientes no avisa', () async {
      final b = await flujo(FakeTransferRepository());

      expect(b.state.pendingElsewhere, isFalse);
    });

    test('el pendiente de otro usuario no avisa', () async {
      await sembrarPendiente(store, userId: 'u2');

      final b = await flujo(FakeTransferRepository());

      expect(b.state.pendingElsewhere, isFalse);
    });

    test('un pendiente caducado no avisa', () async {
      await sembrarPendiente(
        store,
        creada: ahora.subtract(const Duration(hours: 25)),
      );

      final b = await flujo(FakeTransferRepository());

      expect(b.state.pendingElsewhere, isFalse);
    });

    test('con la misma huella no avisa aparte: se reconoce y sella', () async {
      final a = await flujo(caeEnRed());
      await enviar(a, (s) => s.failure != null);
      await a.close();

      final b = await flujo(FakeTransferRepository());

      expect(b.state.outcomeUnknown, isTrue);
      expect(b.state.pendingElsewhere, isFalse);
    });

    test('si el disco no escribe, el envío SIGUE pero queda marcado como sin '
        'clave guardada', () async {
      store = StoreQueNoEscribe();
      final repo = caeEnRed();
      final a = await flujo(repo);

      await enviar(a, (s) => s.failure != null);

      expect(repo.llamadas, 1, reason: 'no se tumba el envío por el disco');
      expect(a.state.keyUnsaved, isTrue);
      expect(a.state.outcomeUnknown, isTrue);
    });

    test('con el disco sano keyUnsaved queda apagado', () async {
      final a = await flujo(caeEnRed());
      await enviar(a, (s) => s.failure != null);

      expect(a.state.keyUnsaved, isFalse);
    });

    test('un fallo de red CONSERVA la entrada', () async {
      final a = await flujo(caeEnRed());
      await enviar(a, (s) => s.failure != null);

      expect(await store.readAll('u1'), hasLength(1));
    });
  });

  group('el motivo', () {
    blocTest<TransferBloc, TransferState>(
      'se recorta a 40 caracteres aunque la UI no lo hubiera hecho',
      build: () => _bloc(FakeTransferRepository()),
      seed: () => _listo,
      act: (b) =>
          b.add(TransferEvent.amountEntered(monto: _monto, motivo: 'a' * 60)),
      verify: (b) => expect(b.state.motivo, 'a' * 40),
    );

    blocTest<TransferBloc, TransferState>(
      'vacío o solo espacios queda en null (no viaja)',
      build: () => _bloc(FakeTransferRepository()),
      seed: () => _listo,
      act: (b) => b.add(
        const TransferEvent.amountEntered(monto: _monto, motivo: '   '),
      ),
      verify: (b) => expect(b.state.motivo, isNull),
    );
  });
}

const _destinoMemoria = destinatarioDePrueba;
