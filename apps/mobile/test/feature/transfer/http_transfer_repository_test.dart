import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/http/authenticated_dio.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/infrastructure/http_transfer_repository.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transfer_repository_contract.dart';

/// Backend simulado y CON ESTADO: reproduce el JSON, los códigos de estado y
/// el orden de validación de `services/api/.../transfers.py` y
/// `directory.py` (cuerpo de error PLANO `{code, detail, <extras>}`; PIN
/// errado 403, bloqueo 423, presupuesto 429).
class FakeTransfersBackend implements HttpClientAdapter {
  static const pin = '000000';
  static const dniPropio = '70123456';
  static const dniDestino = '87654321';
  static const aliasPropio = '@jheampierre';
  static const aliasDestino = '@jmrosa';
  static const cuenta = 'acc-demo-1';

  /// Cuentas que pueden recibir, por id, con su moneda (`acc-ext-*` son de
  /// [dniDestino]; `acc-demo-2` es otra cuenta propia en soles).
  static const _monedaDe = <String, String>{
    'acc-ext-1': 'PEN',
    'acc-ext-2': 'PEN',
    'acc-ext-3': 'USD',
    'acc-demo-1': 'PEN',
    'acc-demo-2': 'PEN',
  };
  static const consultasMaximas = 20;

  /// El tope REAL del backend (`IDENTIFIER_MAX_ATTEMPTS`). Transcribirlo a
  /// mano fue lo que hizo que la batería de contrato certificara un 5 que no
  /// existe en ninguno de los dos lados.
  static const maxIntentos = LockoutPolicy.maxAttempts;
  static final ahora = DateTime.utc(2026, 10, 5, 18);

  /// Si no es null, responde esto a TODO.
  ({int status, Object? body})? forced;
  DioException? throwIt;
  final requests = <RequestOptions>[];

  int saldo = 125040;
  int fallos = 0;
  DateTime? bloqueadoHasta;
  int consultas = 0;
  int secuencia = 0;
  final operaciones =
      <
        String,
        ({String huella, String? destino, Map<String, Object?> cuerpo})
      >{};

  static (int, Object?) _error(
    int status,
    String code, [
    Map<String, Object?> extra = const {},
  ]) => (status, {'code': code, 'detail': 'texto libre', ...extra});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (throwIt case final error?) throw error;
    final (status, body) = switch (forced) {
      final f? => (f.status, f.body),
      _ => _route(options),
    };
    return ResponseBody.fromString(
      body is String ? body : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  (int, Object?) _route(RequestOptions o) => switch (o.uri.path) {
    '/v1/directory/resolve' => _resolver(
      o.queryParameters['dni'] as String?,
      o.queryParameters['alias'] as String?,
    ),
    '/v1/transfers' => _mover(o.data as Map<String, dynamic>, envio: true),
    '/v1/topups' => _mover(o.data as Map<String, dynamic>, envio: false),
    _ => _error(404, 'NOPE'),
  };

  (int, Object?)? _consultar() {
    if (consultas >= consultasMaximas) {
      return _error(429, 'RATE_LIMITED', {'retry_after_seconds': 312});
    }
    consultas++;
    return null;
  }

  /// Como el backend: exactamente uno de [dni] o [alias], y por alias no
  /// se devuelve el DNI de un tercero.
  (int, Object?) _resolver(String? dni, String? alias) {
    if ((dni == null) == (alias == null)) {
      return _error(422, 'INVALID_RECIPIENT_QUERY');
    }
    if (_consultar() case final e?) return e;
    if (dni == dniPropio || alias == aliasPropio) {
      // El propio DNI o alias lista mis cuentas, CON su nombre.
      return (
        200,
        {
          'dni': dniPropio,
          'alias': aliasPropio,
          'nombre_enmascarado': 'T*** C***',
          'cuentas': [
            {
              'cuenta_id': 'acc-demo-1',
              'tipo': 'ahorro',
              'moneda': 'PEN',
              'numero_masked': '••••4521',
              'nombre': 'Gastos',
            },
            {
              'cuenta_id': 'acc-demo-2',
              'tipo': 'sueldo',
              'moneda': 'PEN',
              'numero_masked': '••••8830',
              'nombre': null,
            },
          ],
        },
      );
    }
    if (dni != dniDestino && alias != aliasDestino) {
      return _error(404, 'RECIPIENT_NOT_FOUND');
    }
    return (
      200,
      {
        'dni': dni,
        'alias': aliasDestino,
        'nombre_enmascarado': 'J*** M*** R***',
        'cuentas': [
          {
            'cuenta_id': 'acc-ext-1',
            'tipo': 'ahorro',
            'moneda': 'PEN',
            'numero_masked': '••••7732',
            'nombre': null,
          },
          {
            'cuenta_id': 'acc-ext-2',
            'tipo': 'corriente',
            'moneda': 'PEN',
            'numero_masked': '••••5510',
            'nombre': null,
          },
          {
            'cuenta_id': 'acc-ext-3',
            'tipo': 'ahorro',
            'moneda': 'USD',
            'numero_masked': '••••0419',
            'nombre': null,
          },
        ],
      },
    );
  }

  (int, Object?)? _exigirPin(String enviado) {
    if (bloqueadoHasta case final h? when h.isAfter(ahora)) {
      return _error(423, 'IDENTIFIER_LOCKED', {
        'locked_until': h.toIso8601String(),
      });
    }
    if (enviado == pin) {
      fallos = 0;
      return null;
    }
    fallos++;
    if (fallos >= maxIntentos) {
      fallos = 0;
      bloqueadoHasta = ahora.add(const Duration(minutes: 15));
      return _error(423, 'IDENTIFIER_LOCKED', {
        'locked_until': bloqueadoHasta!.toIso8601String(),
      });
    }
    return _error(403, 'INVALID_CREDENTIALS', {
      'intentos_restantes': maxIntentos - fallos,
    });
  }

  (int, Object?) _mover(Map<String, dynamic> b, {required bool envio}) {
    final cuentaId = (envio ? b['cuenta_origen_id'] : b['cuenta_id']) as String;
    final monto = b['monto_centimos'] as int;
    final clave = b['idempotency_key'] as String;
    if (cuentaId != cuenta) return _error(404, 'ACCOUNT_NOT_FOUND');
    final previa = operaciones[clave];
    final destino = b['cuenta_destino_id'] as String?;
    if (envio) {
      if (destino == cuentaId) return _error(400, 'SAME_ACCOUNT');
      if (previa != null) {
        // Reintento: no vuelve a buscar el destino ni gasta presupuesto; la
        // clave de un envío a OTRA cuenta es 409 antes del PIN.
        if (previa.destino != destino) {
          return _error(409, 'IDEMPOTENCY_KEY_REUSED');
        }
      } else {
        if (_consultar() case final e?) return e;
        final moneda = _monedaDe[destino];
        if (moneda == null) return _error(404, 'RECIPIENT_NOT_FOUND');
        if (moneda != 'PEN') return _error(400, 'CURRENCY_MISMATCH');
      }
    }
    if (monto < 1 || monto > 200000) return _error(400, 'AMOUNT_OUT_OF_RANGE');
    // Como el backend: el depósito simulado (topup) no pide PIN.
    if (envio) {
      if (_exigirPin(b['pin'] as String) case final e?) return e;
    }

    final huella =
        '$envio|$cuentaId|$destino|$monto|'
        '${(b['motivo'] as String? ?? '').trim()}';
    if (previa != null) {
      return previa.huella == huella
          ? (200, previa.cuerpo)
          : _error(409, 'IDEMPOTENCY_KEY_REUSED');
    }
    if (envio && saldo < monto) return _error(400, 'INSUFFICIENT_FUNDS');
    saldo += envio ? -monto : monto;
    final cuerpo = <String, Object?>{
      'transaction_id': 'tx-${++secuencia}',
      'estado': 'confirmada',
      'monto_centimos': monto,
      'created_at': '2026-10-05T18:00:00.000000Z',
    };
    operaciones[clave] = (huella: huella, destino: destino, cuerpo: cuerpo);
    return (201, cuerpo);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeTransfersBackend backend;
  late HttpTransferRepository repo;
  var sesionVencida = 0;

  HttpTransferRepository nuevo() {
    backend = FakeTransfersBackend();
    final dio = buildAuthenticatedDio(
      baseUrl: 'http://10.0.2.2:8001',
      deviceId: 'telefono-1',
      readToken: () => 'tok-1',
      onUnauthenticated: () => sesionVencida++,
    )..httpClientAdapter = backend;
    return repo = HttpTransferRepository(dio: dio);
  }

  setUp(() {
    sesionVencida = 0;
    nuevo();
  });

  probarContratoDeTransferencias(
    'HttpTransferRepository',
    nuevo,
    pinValido: FakeTransfersBackend.pin,
    cuentaOrigenId: FakeTransfersBackend.cuenta,
    dniPropio: FakeTransfersBackend.dniPropio,
    dniDestino: FakeTransfersBackend.dniDestino,
    aliasDestino: FakeTransfersBackend.aliasDestino,
    cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId,
    cuentaOtraMonedaId: MemoryTransferRepository.cuentaDestinoDolaresId,
    consultasMaximas: FakeTransfersBackend.consultasMaximas,
    maxIntentos: FakeTransfersBackend.maxIntentos,
  );

  TransferFailure falloDe(Result<TransferFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<TransferFailure>>());
    return (failure! as ServerFailure<TransferFailure>).failure;
  }

  Future<Result<TransferFailure, Object?>> enviar() => repo.enviar(
    cuentaOrigenId: 'acc-demo-1',
    cuentaDestinoId: 'acc-ext-1',
    monto: const Money.soles(1000),
    pin: '000000',
    idempotencyKey: 'clave-0001',
  );

  group('HttpTransferRepository · mapeo de errores', () {
    test(
      '401 UNAUTHENTICATED es unauthenticated y avisa de sesión vencida',
      () async {
        backend.forced = (
          status: 401,
          body: {'code': 'UNAUTHENTICATED', 'detail': 'Sesión inválida.'},
        );

        expect(falloDe(await enviar()), isA<TransferUnauthenticated>());
        expect(sesionVencida, 1);
      },
    );

    test('un PIN errado (403) NO cierra la sesión', () async {
      backend.forced = (
        status: 403,
        body: {
          'code': 'INVALID_CREDENTIALS',
          'detail': 'PIN incorrecto.',
          'intentos_restantes': 2,
        },
      );

      final f = falloDe(await enviar());

      expect((f as WrongPin).intentosRestantes, 2);
      expect(sesionVencida, 0);
    });

    test('INVALID_CREDENTIALS sin intentos_restantes es unexpected', () async {
      backend.forced = (
        status: 403,
        body: {'code': 'INVALID_CREDENTIALS', 'detail': 'x'},
      );

      expect(falloDe(await enviar()), isA<TransferUnexpectedFailure>());
    });

    test(
      'IDENTIFIER_LOCKED y DEVICE_LOCKED se distinguen y traen hasta',
      () async {
        for (final (code, esperado) in [
          ('IDENTIFIER_LOCKED', isA<IdentifierLocked>()),
          ('DEVICE_LOCKED', isA<DeviceLocked>()),
        ]) {
          backend.forced = (
            status: 423,
            body: {
              'code': code,
              'detail': 'x',
              'locked_until': '2026-10-05T18:15:00+00:00',
            },
          );

          final f = falloDe(await enviar());

          expect(f, esperado, reason: code);
          final hasta = switch (f) {
            IdentifierLocked(:final hasta) => hasta,
            DeviceLocked(:final hasta) => hasta,
            _ => fail('No es un bloqueo'),
          };
          expect(hasta, DateTime.utc(2026, 10, 5, 18, 15));
          expect(hasta.isUtc, isTrue);
        }
      },
    );

    test('un locked_until sin zona se lee como UTC', () async {
      backend.forced = (
        status: 423,
        body: {
          'code': 'DEVICE_LOCKED',
          'detail': 'x',
          'locked_until': '2026-10-05T18:15:00.123456',
        },
      );

      final f = falloDe(await enviar()) as DeviceLocked;

      expect(f.hasta.isUtc, isTrue);
      expect(f.hasta.hour, 18);
    });

    test('un bloqueo sin locked_until legible es unexpected', () async {
      backend.forced = (
        status: 423,
        body: {'code': 'IDENTIFIER_LOCKED', 'detail': 'x'},
      );

      expect(falloDe(await enviar()), isA<TransferUnexpectedFailure>());
    });

    test('RATE_LIMITED lee retry_after_seconds de la raíz', () async {
      backend.forced = (
        status: 429,
        body: {
          'code': 'RATE_LIMITED',
          'detail': 'x',
          'retry_after_seconds': 312,
        },
      );

      final f = falloDe(await enviar()) as RateLimited;

      expect(f.reintentarEn, const Duration(seconds: 312));
    });

    test(
      'RATE_LIMITED sin retry_after_seconds sigue siendo rateLimited',
      () async {
        backend.forced = (
          status: 429,
          body: {'code': 'RATE_LIMITED', 'detail': 'x'},
        );

        final f = falloDe(await enviar()) as RateLimited;

        expect(f.reintentarEn, isNull);
      },
    );

    test('mapea CURRENCY_MISMATCH y SAME_ACCOUNT', () async {
      backend.forced = (status: 400, body: {'code': 'CURRENCY_MISMATCH'});
      expect(falloDe(await enviar()), isA<CurrencyMismatch>());
      backend.forced = (status: 400, body: {'code': 'SAME_ACCOUNT'});
      expect(falloDe(await enviar()), isA<SameAccount>());
    });

    test('SELF_TRANSFER ya no existe: es unexpected', () async {
      backend.forced = (status: 400, body: {'code': 'SELF_TRANSFER'});
      expect(falloDe(await enviar()), isA<TransferUnexpectedFailure>());
    });

    test(
      'una cuenta con moneda o tipo desconocidos en resolve es inesperado',
      () async {
        for (final (tipo, moneda) in [('ahorro', 'EUR'), ('plazo', 'PEN')]) {
          backend.forced = (
            status: 200,
            body: {
              'dni': '87654321',
              'alias': '@jmrosa',
              'nombre_enmascarado': 'J***',
              'cuentas': [
                {
                  'cuenta_id': 'x',
                  'tipo': tipo,
                  'moneda': moneda,
                  'numero_masked': '••••1',
                  'nombre': null,
                },
              ],
            },
          );
          expect(
            (await repo.resolverDestinatario('87654321')).isLeft(),
            isTrue,
            reason: '$tipo/$moneda',
          );
        }
      },
    );

    test('ACCOUNT_BLOCKED (409) es accountBlocked', () async {
      backend.forced = (
        status: 409,
        body: {'code': 'ACCOUNT_BLOCKED', 'detail': 'x'},
      );

      expect(falloDe(await enviar()), isA<AccountBlocked>());
    });

    test('un code desconocido es unexpected', () async {
      backend.forced = (status: 400, body: {'code': 'OTRA', 'detail': 'x'});

      expect(falloDe(await enviar()), isA<TransferUnexpectedFailure>());
    });

    test('un 422 de validación (sin code) es unexpected', () async {
      backend.forced = (status: 422, body: {'detail': <Object?>[]});

      expect(falloDe(await enviar()), isA<TransferUnexpectedFailure>());
    });

    test('un 500 es unexpected', () async {
      backend.forced = (status: 500, body: {'detail': 'boom'});

      expect(falloDe(await enviar()), isA<TransferUnexpectedFailure>());
    });

    test('timeout y caída de conexión son network', () async {
      for (final tipo in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        backend.throwIt = DioException(
          requestOptions: RequestOptions(path: '/v1/transfers'),
          type: tipo,
        );
        expect(
          falloDe(await enviar()),
          isA<TransferNetworkFailure>(),
          reason: '$tipo',
        );
      }
    });

    test('un cuerpo de éxito que no es JSON de objeto no lanza', () async {
      backend.forced = (status: 201, body: '<html>proxy</html>');

      expect((await enviar()).isLeft(), isTrue);
    });
  });

  group('HttpTransferRepository · contrato JSON', () {
    test('enviar manda céntimos enteros y los campos del router', () async {
      await repo.enviar(
        cuentaOrigenId: 'acc-demo-1',
        cuentaDestinoId: 'acc-ext-1',
        monto: const Money.soles(25000),
        motivo: 'Cena',
        pin: '000000',
        idempotencyKey: 'clave-0001',
      );

      final req = backend.requests.last;
      expect(req.method, 'POST');
      expect(req.uri.path, '/v1/transfers');
      expect(req.data, {
        'cuenta_origen_id': 'acc-demo-1',
        'cuenta_destino_id': 'acc-ext-1',
        'monto_centimos': 25000,
        'motivo': 'Cena',
        'pin': '000000',
        'idempotency_key': 'clave-0001',
      });
    });

    test('sin motivo no se manda la clave motivo', () async {
      await repo.enviar(
        cuentaOrigenId: 'acc-demo-1',
        cuentaDestinoId: 'acc-ext-1',
        monto: const Money.soles(100),
        pin: '000000',
        idempotencyKey: 'clave-0001',
      );

      expect(
        (backend.requests.last.data as Map).containsKey('motivo'),
        isFalse,
      );
    });

    test('recargar va a /v1/topups con cuenta_id y sin destinatario', () async {
      await repo.recargar(
        cuentaId: 'acc-demo-1',
        monto: const Money.soles(5000),
        idempotencyKey: 'recarga-0001',
      );

      final req = backend.requests.last;
      expect(req.uri.path, '/v1/topups');
      expect(req.data, {
        'cuenta_id': 'acc-demo-1',
        'monto_centimos': 5000,
        'idempotency_key': 'recarga-0001',
      });
    });

    test('la constancia lleva la moneda del monto enviado', () async {
      final r = await repo.recargar(
        cuentaId: 'acc-demo-1',
        monto: const Money.dolares(2000),
        idempotencyKey: 'recarga-usd-1',
      );

      expect(r.getRight().toNullable()!.monto.currency, Currency.usd);
    });

    test('enviar manda cuenta_destino_id y no el DNI', () async {
      await repo.enviar(
        cuentaOrigenId: 'acc-demo-1',
        cuentaDestinoId: 'acc-ext-2',
        monto: const Money.soles(100),
        pin: '000000',
        idempotencyKey: 'clave-http-01',
      );
      final body = backend.requests.last.data as Map;
      expect(body['cuenta_destino_id'], 'acc-ext-2');
      expect(body.containsKey('destinatario_dni'), isFalse);
    });

    test('resolve lee las cuentas con tipo, moneda y nombre', () async {
      final r = await repo.resolverDestinatario('70123456');

      final d = r.getRight().toNullable();
      expect(d?.cuentas.map((c) => c.cuentaId), ['acc-demo-1', 'acc-demo-2']);
      expect(d?.cuentas.first.nombre, 'Gastos');
      expect(d?.cuentas.last.tipo, AccountType.sueldo);
      expect(d?.cuentas.last.moneda, Currency.pen);
    });

    test('resolver manda el DNI como query', () async {
      await repo.resolverDestinatario('87654321');

      expect(backend.requests.last.queryParameters, {'dni': '87654321'});
    });

    test('resolver manda el alias normalizado como query', () async {
      await repo.resolverDestinatario('  JMRosa ');

      expect(backend.requests.last.queryParameters, {'alias': '@jmrosa'});
    });

    test('ni DNI ni alias válido no llega al servidor', () async {
      for (final malo in ['1234', '123456789', 'ab', 'con espacio']) {
        final r = await repo.resolverDestinatario(malo);
        expect(r.getLeft().toNullable(), isA<ServerFailure<TransferFailure>>());
      }
      expect(backend.requests, isEmpty);
    });

    test('la fecha de la constancia con Z se lee como UTC', () async {
      final r = await repo.recargar(
        cuentaId: 'acc-demo-1',
        monto: const Money.soles(5000),
        idempotencyKey: 'recarga-0001',
      );

      final c = r.getRight().toNullable()!;
      expect(c.fecha, DateTime.utc(2026, 10, 5, 18));
      expect(c.fecha.isUtc, isTrue);
    });
  });
}
