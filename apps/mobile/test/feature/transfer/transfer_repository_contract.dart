import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/transfer/domain/recipient_directory.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/domain/transfer_receipt.dart';
import 'package:cuycash/feature/transfer/domain/transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// La MISMA batería contra el `Memory*` y contra el HTTP.
///
/// Es lo que impide que el flavor `mock` mienta: si el repositorio en memoria
/// se comporta distinto del real, la app que se demuestra no es la que se
/// despliega.
///
/// Premisas del escenario que [construir] debe entregar, SIEMPRE con estado
/// nuevo en cada llamada (cada test gasta saldo, intentos y presupuesto):
///
/// - Titular [dniPropio] con la cuenta [cuentaOrigenId] y S/ 1,250.40.
/// - El cliente destinatario [dniDestino], con alias [aliasDestino] (nombre
///   enmascarado), tiene la
///   cuenta [cuentaDestinoId] en soles, al menos otra cuenta en soles y la
///   cuenta [cuentaOtraMonedaId] en otra moneda que la de origen.
/// - PIN válido [pinValido]; [maxIntentos] PIN errados seguidos bloquean por
///   DNI. El número NO se fija aquí: se lo pasa cada lado, y es lo que impide
///   que la batería certifique un número inventado (el backend real lo tiene
///   en `IDENTIFIER_MAX_ATTEMPTS`). Se exige >= 2.
/// - Presupuesto de [consultasMaximas] consultas de destinatario, compartido
///   entre `resolverDestinatario` y `enviar`.
void probarContratoDeTransferencias(
  String nombre,
  TransferRepository Function() construir, {
  required String pinValido,
  required String cuentaOrigenId,
  required String dniPropio,
  required String dniDestino,
  required String aliasDestino,
  required String cuentaDestinoId,
  required String cuentaOtraMonedaId,
  required int consultasMaximas,
  required int maxIntentos,
}) {
  assert(maxIntentos >= 2, 'La batería necesita al menos dos intentos');
  TransferFailure falloDe(Result<TransferFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<TransferFailure>>(), reason: '$r');
    return (failure! as ServerFailure<TransferFailure>).failure;
  }

  T valorDe<T>(Result<TransferFailure, T> r) =>
      r.match((f) => fail('No debía fallar: $f'), (v) => v);

  FutureResult<TransferFailure, TransferReceipt> enviar(
    TransferRepository repo, {
    int centimos = 10000,
    String? pin,
    String clave = 'clave-0001',
    String? destino,
    String? cuenta,
    String? motivo,
  }) => repo.enviar(
    cuentaOrigenId: cuenta ?? cuentaOrigenId,
    cuentaDestinoId: destino ?? cuentaDestinoId,
    monto: Money.soles(centimos),
    motivo: motivo,
    pin: pin ?? pinValido,
    idempotencyKey: clave,
  );

  FutureResult<TransferFailure, TransferReceipt> recargar(
    TransferRepository repo, {
    int centimos = 5000,
    String clave = 'recarga-0001',
    String? cuenta,
  }) => repo.recargar(
    cuentaId: cuenta ?? cuentaOrigenId,
    monto: Money.soles(centimos),
    idempotencyKey: clave,
  );

  group('$nombre · contrato de TransferRepository', () {
    group('resolverDestinatario', () {
      test(
        'un DNI conocido devuelve su nombre enmascarado y sus cuentas',
        () async {
          final RecipientDirectory d = valorDe(
            await construir().resolverDestinatario(dniDestino),
          );

          expect(d.alias, aliasDestino);
          expect(d.nombreEnmascarado, contains('***'));
          expect(d.cuentas, isNotEmpty);
          expect(d.cuentas.map((c) => c.cuentaId), contains(cuentaDestinoId));
          for (final c in d.cuentas) {
            expect(c.numeroMasked, startsWith('••••'));
            expect(c.nombre, isNull, reason: 'el nombre de un tercero no sale');
          }
        },
      );

      test(
        'el propio DNI lista mis cuentas, con su nombre si lo tienen',
        () async {
          final d = valorDe(await construir().resolverDestinatario(dniPropio));
          expect(d.cuentas.map((c) => c.cuentaId), contains(cuentaOrigenId));
        },
      );

      test(
        'su alias encuentra a la misma persona y las mismas cuentas',
        () async {
          final porDni = valorDe(
            await construir().resolverDestinatario(dniDestino),
          );
          // Sin `@` y en mayúsculas: se normaliza como al guardarlo.
          final consulta = aliasDestino.substring(1).toUpperCase();
          final porAlias = valorDe(
            await construir().resolverDestinatario(consulta),
          );

          expect(porAlias.alias, aliasDestino);
          expect(porAlias.nombreEnmascarado, porDni.nombreEnmascarado);
          expect(
            porAlias.cuentas.map((c) => c.cuentaId),
            porDni.cuentas.map((c) => c.cuentaId),
          );
        },
      );

      test('un alias desconocido devuelve recipientNotFound', () async {
        final r = await construir().resolverDestinatario('@nadie');

        expect(falloDe(r), isA<RecipientNotFound>());
      });

      test('un DNI desconocido devuelve recipientNotFound', () async {
        final r = await construir().resolverDestinatario('99999999');

        expect(falloDe(r), isA<RecipientNotFound>());
      });

      test('agotado el presupuesto devuelve rateLimited', () async {
        final repo = construir();
        for (var i = 0; i < consultasMaximas; i++) {
          // Aciertos y fallos cuestan lo mismo.
          await repo.resolverDestinatario(i.isEven ? dniDestino : '99999999');
        }

        final r = await repo.resolverDestinatario(dniDestino);

        expect(falloDe(r), isA<RateLimited>());
      });

      test('rateLimited trae cuánto esperar', () async {
        final repo = construir();
        for (var i = 0; i < consultasMaximas; i++) {
          await repo.resolverDestinatario(dniDestino);
        }

        final f = falloDe(await repo.resolverDestinatario(dniDestino));

        expect((f as RateLimited).reintentarEn, isNotNull);
        expect(f.reintentarEn! > Duration.zero, isTrue);
      });
    });

    group('enviar', () {
      test('un envío válido devuelve la constancia', () async {
        final c = valorDe(
          await enviar(construir(), centimos: 25000, motivo: 'Cena compartida'),
        );

        expect(c.monto, const Money.soles(25000));
        expect(c.transactionId, isNotEmpty);
        expect(c.fecha.isUtc, isTrue);
        expect(c.reutilizada, isFalse);
      });

      test('repetir la clave devuelve la MISMA constancia', () async {
        final repo = construir();

        final primera = valorDe(await enviar(repo));
        final segunda = valorDe(await enviar(repo));

        expect(segunda.transactionId, primera.transactionId);
        expect(segunda.monto, primera.monto);
        expect(segunda.fecha, primera.fecha);
        expect(primera.reutilizada, isFalse);
        expect(segunda.reutilizada, isTrue);
      });

      test('un reintento NO descuenta dos veces', () async {
        final repo = construir();
        valorDe(await enviar(repo, centimos: 100000, clave: 'clave-A001'));
        valorDe(await enviar(repo, centimos: 100000, clave: 'clave-A001'));

        // Quedan S/ 250.40: si el reintento hubiera descontado otra vez, no
        // alcanzaría para S/ 250.00.
        final r = await enviar(repo, centimos: 25000, clave: 'clave-B001');

        expect(r.isRight(), isTrue, reason: '$r');
      });

      test(
        'la misma clave con otro monto devuelve idempotencyKeyReused',
        () async {
          final repo = construir();
          valorDe(await enviar(repo, centimos: 10000));

          final r = await enviar(repo, centimos: 20000);

          expect(falloDe(r), isA<IdempotencyKeyReused>());
        },
      );

      test('un envío fallido no consume la clave', () async {
        final repo = construir();
        expect(falloDe(await enviar(repo, pin: '111111')), isA<WrongPin>());

        final r = await enviar(repo);

        expect(r.isRight(), isTrue, reason: '$r');
      });

      test(
        'un PIN errado devuelve wrongPin con los intentos restantes',
        () async {
          final f = falloDe(await enviar(construir(), pin: '111111'));

          expect(f, isA<WrongPin>());
          expect((f as WrongPin).intentosRestantes, maxIntentos - 1);
        },
      );

      test('los intentos restantes bajan con cada PIN errado', () async {
        final repo = construir();
        // Todos los fallos menos el que bloquearía.
        for (var i = 1; i < maxIntentos - 1; i++) {
          await enviar(repo, pin: '111111', clave: 'mala-000$i');
        }

        final f = falloDe(
          await enviar(repo, pin: '111111', clave: 'otra-0002'),
        );

        expect((f as WrongPin).intentosRestantes, 1);
      });

      test('un PIN correcto reinicia la cuenta de intentos', () async {
        final repo = construir();
        for (var i = 1; i < maxIntentos; i++) {
          await enviar(repo, pin: '111111', clave: 'mala-000$i');
        }
        valorDe(await enviar(repo, clave: 'otra-0003'));

        final f = falloDe(
          await enviar(repo, pin: '111111', clave: 'otra-0004'),
        );

        expect((f as WrongPin).intentosRestantes, maxIntentos - 1);
      });

      test('el último PIN errado bloquea y no se queda en wrongPin', () async {
        final repo = construir();
        for (var i = 1; i < maxIntentos; i++) {
          expect(
            falloDe(await enviar(repo, pin: '111111', clave: 'mala-000$i')),
            isA<WrongPin>(),
            reason: 'intento $i de $maxIntentos',
          );
        }

        final f = falloDe(
          await enviar(repo, pin: '111111', clave: 'mala-ultima'),
        );

        expect(f, isA<IdentifierLocked>());
        expect((f as IdentifierLocked).hasta.isUtc, isTrue);
      });

      test('bloqueado, ni el PIN correcto envía', () async {
        final repo = construir();
        for (var i = 1; i <= maxIntentos; i++) {
          await enviar(repo, pin: '111111', clave: 'mala-000$i');
        }

        final r = await enviar(repo, clave: 'buena-001');

        expect(falloDe(r), isA<IdentifierLocked>());
      });

      test('enviar más de lo disponible devuelve insufficientFunds', () async {
        // Dentro del rango (S/ 2,000) pero por encima de S/ 1,250.40.
        final r = await enviar(construir(), centimos: 200000);

        expect(falloDe(r), isA<InsufficientFunds>());
      });

      test('fuera de rango devuelve amountOutOfRange', () async {
        final repo = construir();

        for (final c in [0, -5, 200001]) {
          expect(
            falloDe(await enviar(repo, centimos: c)),
            isA<AmountOutOfRange>(),
            reason: '$c',
          );
        }
      });

      test('los límites del rango son válidos', () async {
        final repo = construir();

        expect(
          (await enviar(repo, centimos: 1, clave: 'limite-001')).isRight(),
          isTrue,
        );
        expect(
          falloDe(await enviar(repo, centimos: 200000, clave: 'limite-002')),
          isA<InsufficientFunds>(),
        );
      });

      test('a la misma cuenta de origen es sameAccount', () async {
        expect(
          falloDe(await enviar(construir(), destino: cuentaOrigenId)),
          isA<SameAccount>(),
        );
      });

      test(
        'a una cuenta de otra moneda es currencyMismatch y no gasta PIN',
        () async {
          final repo = construir();
          expect(
            falloDe(
              await enviar(repo, destino: cuentaOtraMonedaId, pin: '999999'),
            ),
            isA<CurrencyMismatch>(),
          );
          // El PIN errado no se llegó a mirar: el siguiente envío correcto
          // pasa.
          expect((await enviar(repo, clave: 'clave-0002')).isRight(), isTrue);
        },
      );

      test('a una cuenta inexistente es recipientNotFound', () async {
        expect(
          falloDe(await enviar(construir(), destino: 'no-existe')),
          isA<RecipientNotFound>(),
        );
      });

      test(
        'la misma clave hacia otra cuenta es idempotencyKeyReused',
        () async {
          final repo = construir();
          valorDe(await enviar(repo));
          // Otra cuenta destino válida del mismo DNI, en la misma moneda: la
          // tiene que dar el escenario (en memoria, `acc-ext-2`).
          final otra = valorDe(await repo.resolverDestinatario(dniDestino))
              .cuentas
              .firstWhere(
                (c) =>
                    c.cuentaId != cuentaDestinoId && c.moneda == Currency.pen,
              );
          expect(
            falloDe(await enviar(repo, destino: otra.cuentaId)),
            isA<IdempotencyKeyReused>(),
          );
        },
      );

      test('una cuenta de origen ajena devuelve accountNotFound', () async {
        final r = await enviar(construir(), cuenta: 'acc-ajena');

        expect(falloDe(r), isA<TransferAccountNotFound>());
      });

      test(
        'el PIN se verifica al final: un monto inválido no gasta intentos',
        () async {
          final repo = construir();
          for (var i = 0; i <= maxIntentos; i++) {
            await enviar(repo, centimos: 0, pin: '111111', clave: 'mala-000$i');
          }

          final f = falloDe(
            await enviar(repo, pin: '111111', clave: 'mala-0009'),
          );

          expect((f as WrongPin).intentosRestantes, maxIntentos - 1);
        },
      );

      test('enviar también gasta el presupuesto de consultas', () async {
        final repo = construir();
        for (var i = 0; i < consultasMaximas; i++) {
          await repo.resolverDestinatario(dniDestino);
        }

        final r = await enviar(repo);

        expect(falloDe(r), isA<RateLimited>());
      });
    });

    group('recargar', () {
      test('acredita sin necesitar destinatario', () async {
        final c = valorDe(await recargar(construir()));

        expect(c.monto, const Money.soles(5000));
      });

      test('repetir la clave devuelve la misma constancia', () async {
        final repo = construir();

        final primera = valorDe(await recargar(repo));
        final segunda = valorDe(await recargar(repo));

        expect(segunda.transactionId, primera.transactionId);
        expect(segunda.reutilizada, isTrue);
      });

      test(
        'la misma clave con otro monto devuelve idempotencyKeyReused',
        () async {
          final repo = construir();
          valorDe(await recargar(repo, centimos: 5000));

          expect(
            falloDe(await recargar(repo, centimos: 6000)),
            isA<IdempotencyKeyReused>(),
          );
        },
      );

      test(
        'no pide PIN: acredita aunque el titular esté bloqueado por PIN',
        () async {
          final repo = construir();
          for (var i = 0; i < maxIntentos; i++) {
            await enviar(repo, pin: '111111', clave: 'mala-000$i');
          }
          expect(
            falloDe(await enviar(repo, clave: 'bloqueado')),
            isA<IdentifierLocked>(),
          );

          expect((await recargar(repo)).isRight(), isTrue);
        },
      );

      test('fuera de rango devuelve amountOutOfRange', () async {
        expect(
          falloDe(await recargar(construir(), centimos: 200001)),
          isA<AmountOutOfRange>(),
        );
      });

      test('una cuenta ajena devuelve accountNotFound', () async {
        expect(
          falloDe(await recargar(construir(), cuenta: 'acc-ajena')),
          isA<TransferAccountNotFound>(),
        );
      });

      test('una recarga sube el saldo: luego alcanza para enviar más', () async {
        final repo = construir();
        // Saldo S/ 1,250.40 + S/ 1,000.00 = S/ 2,250.40: alcanza para S/ 2,000.
        valorDe(await recargar(repo, centimos: 100000));

        final r = await enviar(repo, centimos: 200000);

        expect(r.isRight(), isTrue, reason: '$r');
      });
    });
  });
}
