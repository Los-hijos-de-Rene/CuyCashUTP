import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/http/authenticated_dio.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/infrastructure/http_account_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_repository_contract.dart';

/// Backend simulado: responde con el JSON EXACTO de
/// `services/api/app/api/v1/routers/accounts.py` (nombres de campo, céntimos
/// enteros, fechas UTC con microsegundos y `Z`, errores planos
/// `{code, detail}`).
class FakeAccountsBackend implements HttpClientAdapter {
  /// Si no es null, responde esto a TODO.
  ({int status, Object? body})? forced;
  DioException? throwIt;
  final requests = <RequestOptions>[];

  /// Tamaño de página del "servidor" (el real usa `limit`, 20 por defecto).
  int pageSize = 20;

  /// Cuentas abiertas por `POST /v1/accounts`, además de la de demo.
  final _abiertas = <Map<String, Object?>>[];
  final _porClave = <String, Map<String, Object?>>{};
  final _nombres = <String, String?>{};

  static const _movimientos = <Map<String, Object?>>[
    {
      'transaction_id': 'tx-demo-1',
      'tipo': 'transferencia',
      'estado': 'confirmada',
      'direccion': 'debito',
      'monto': 4500,
      'moneda': 'PEN',
      'contraparte': 'B*** D*** A***',
      'motivo': null,
      'saldo_posterior': 125040,
      'created_at': '2026-10-05T19:30:00.000000Z',
    },
    {
      'transaction_id': 'tx-demo-2',
      'tipo': 'transferencia',
      'estado': 'confirmada',
      'direccion': 'credito',
      'monto': 120000,
      'moneda': 'PEN',
      'contraparte': 'Jenny Marisol Ruiz',
      'motivo': 'Almuerzo',
      'saldo_posterior': 129540,
      'created_at': '2026-10-05T14:15:00.000000Z',
    },
    {
      'transaction_id': 'tx-demo-3',
      'tipo': 'transferencia',
      'estado': 'confirmada',
      'direccion': 'debito',
      'monto': 1850,
      'moneda': 'PEN',
      'contraparte': 'M*** L*** C***',
      'motivo': null,
      'saldo_posterior': 9540,
      'created_at': '2026-10-04T18:05:00.000000Z',
    },
  ];

  static const _destinos = {
    'tx-demo-1': '••••7732',
    'tx-demo-2': '••••4521',
    'tx-demo-3': '••••1908',
  };

  static const _error404 = {
    'code': 'ACCOUNT_NOT_FOUND',
    'detail': 'No encontramos esa cuenta.',
  };

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

  Map<String, Object?> get _demo => {
    'id': 'acc-demo-1',
    'numero': '19100000004521',
    'tipo': 'ahorro',
    'moneda': 'PEN',
    'estado': 'activa',
    'nombre': _nombres['acc-demo-1'],
    'saldo_disponible': 125040,
    'saldo_contable': 125040,
  };

  (int, Object?) _route(RequestOptions options) {
    final path = options.uri.path;
    final query = options.queryParameters;
    if (path == '/v1/accounts' && options.method == 'POST') {
      final body = options.data as Map;
      final clave = body['idempotency_key'] as String;
      if (_porClave[clave] case final previa?) return (200, previa);
      final n = _abiertas.length + 1;
      final cuenta = <String, Object?>{
        'id': 'acc-http-$n',
        'numero': '191000000099${n.toString().padLeft(2, '0')}',
        'tipo': body['tipo'],
        'moneda': body['moneda'],
        'estado': 'activa',
        'nombre': body['nombre'],
        'saldo_disponible': 0,
        'saldo_contable': 0,
      };
      _abiertas.add(cuenta);
      _porClave[clave] = cuenta;
      return (201, cuenta);
    }
    if (path == '/v1/accounts') {
      return (
        200,
        {
          'cuentas': [_demo, ..._abiertas],
        },
      );
    }
    if (path.endsWith('/nombre') && options.method == 'PATCH') {
      final id = path.split('/')[3];
      final nombre = (options.data as Map)['nombre'] as String?;
      if (id == 'acc-demo-1') {
        _nombres[id] = nombre;
        return (200, _demo);
      }
      for (final c in _abiertas) {
        if (c['id'] == id) {
          c['nombre'] = nombre;
          return (200, c);
        }
      }
      return (404, _error404);
    }
    if (path == '/v1/accounts/acc-demo-1/movements') {
      // Cursor opaco = índice del siguiente; ilegible empieza por el principio.
      final crudo = query['cursor'] as String?;
      final desde = switch (int.tryParse((crudo ?? '').replaceFirst('c', ''))) {
        final int i when i >= 0 && i < _movimientos.length => i,
        _ => 0,
      };
      final hasta = desde + pageSize;
      final hayMas = hasta < _movimientos.length;
      return (
        200,
        {
          'movimientos': _movimientos.sublist(
            desde,
            hayMas ? hasta : _movimientos.length,
          ),
          'next_cursor': hayMas ? 'c$hasta' : null,
        },
      );
    }
    if (path.startsWith('/v1/accounts/')) return (404, _error404);
    final id = path.replaceFirst('/v1/movements/', '');
    final fila = _movimientos.where((m) => m['transaction_id'] == id);
    if (path.startsWith('/v1/movements/') && fila.isNotEmpty) {
      return (200, {...fila.first, 'cuenta_destino_masked': _destinos[id]});
    }
    return (
      404,
      {
        'code': 'MOVEMENT_NOT_FOUND',
        'detail': 'No encontramos ese movimiento.',
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeAccountsBackend backend;
  late HttpAccountRepository repo;
  var sesionVencida = 0;

  setUp(() {
    backend = FakeAccountsBackend();
    sesionVencida = 0;
    final dio = buildAuthenticatedDio(
      baseUrl: 'http://10.0.2.2:8001',
      deviceId: 'telefono-1',
      readToken: () => 'tok-1',
      onUnauthenticated: () => sesionVencida++,
    )..httpClientAdapter = backend;
    repo = HttpAccountRepository(dio: dio);
  });

  probarContratoDeCuentas('HttpAccountRepository', ({int? pageSize}) {
    if (pageSize != null) backend.pageSize = pageSize;
    return repo;
  });

  AccountFailure falloDe(Result<AccountFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<AccountFailure>>());
    return (failure! as ServerFailure<AccountFailure>).failure;
  }

  group('HttpAccountRepository · mapeo de errores', () {
    test(
      '401 UNAUTHENTICATED es unauthenticated y avisa de sesión vencida',
      () async {
        backend.forced = (
          status: 401,
          body: {'code': 'UNAUTHENTICATED', 'detail': 'Sesión inválida.'},
        );

        expect(falloDe(await repo.cuentas()), isA<Unauthenticated>());
        expect(sesionVencida, 1);
      },
    );

    test(
      'ACCOUNT_NOT_FOUND y MOVEMENT_NOT_FOUND son accountNotFound',
      () async {
        expect(falloDe(await repo.movimientos('x')), isA<AccountNotFound>());
        expect(falloDe(await repo.movimiento('x')), isA<AccountNotFound>());
      },
    );

    test('un 404 con otro code es unexpected', () async {
      backend.forced = (status: 404, body: {'code': 'OTRA', 'detail': 'x'});

      expect(falloDe(await repo.cuentas()), isA<UnexpectedFailure>());
    });

    test('un 500 es unexpected', () async {
      backend.forced = (status: 500, body: {'detail': 'boom'});

      expect(falloDe(await repo.cuentas()), isA<UnexpectedFailure>());
    });

    test('timeout y caída de conexión son network', () async {
      for (final tipo in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        backend.throwIt = DioException(
          requestOptions: RequestOptions(path: '/v1/accounts'),
          type: tipo,
        );
        expect(
          falloDe(await repo.cuentas()),
          isA<NetworkFailure>(),
          reason: '$tipo',
        );
      }
    });

    test(
      'un cuerpo que no es JSON de objeto no lanza: devuelve failure',
      () async {
        backend.forced = (status: 200, body: '<html>proxy</html>');

        final r = await repo.cuentas();

        expect(r.isLeft(), isTrue);
      },
    );

    test('un tipo de cuenta desconocido es inesperado', () async {
      backend.forced = (
        status: 200,
        body: {
          'cuentas': [
            {
              'id': 'x',
              'numero': '19100000000099',
              'tipo': 'cts',
              'moneda': 'PEN',
              'estado': 'activa',
              'nombre': null,
              'saldo_disponible': 0,
              'saldo_contable': 0,
            },
          ],
        },
      );

      expect((await repo.cuentas()).isLeft(), isTrue);
    });

    test('una cuenta con moneda desconocida es inesperada, no soles', () async {
      backend.forced = (
        status: 200,
        body: {
          'cuentas': [
            {
              'id': 'acc-x',
              'numero': '19100000004521',
              'tipo': 'ahorro',
              'moneda': 'EUR',
              'estado': 'activa',
              'saldo_disponible': 1,
              'saldo_contable': 1,
            },
          ],
        },
      );

      final r = await repo.cuentas();

      expect(r.getLeft().toNullable(), isA<Unexpected<AccountFailure>>());
    });

    test('una dirección desconocida no se adivina: failure', () async {
      backend.forced = (
        status: 200,
        body: {
          'movimientos': [
            {
              'transaction_id': 't',
              'tipo': 'transferencia',
              'estado': 'confirmada',
              'direccion': 'raro',
              'monto': 1,
              'moneda': 'PEN',
              'contraparte': null,
              'motivo': null,
              'saldo_posterior': 1,
              'created_at': '2026-10-05T19:30:00.000000Z',
            },
          ],
          'next_cursor': null,
        },
      );

      expect((await repo.movimientos('acc-demo-1')).isLeft(), isTrue);
    });
  });

  group('errores de abrir', () {
    Future<AccountFailure> falla(int status, Map<String, Object?> body) async {
      backend.forced = (status: status, body: body);
      final r = await repo.abrir(
        tipo: AccountType.ahorro,
        moneda: Currency.pen,
        pin: '1',
        idempotencyKey: 'k-000001',
      );
      return falloDe(r);
    }

    test('mapea cada code', () async {
      expect(
        await falla(409, {'code': 'ACCOUNT_LIMIT_REACHED'}),
        isA<AccountLimitReached>(),
      );
      expect(
        await falla(409, {'code': 'SALARY_ACCOUNT_EXISTS'}),
        isA<SalaryAccountExists>(),
      );
      expect(
        await falla(400, {'code': 'INVALID_ACCOUNT_CURRENCY'}),
        isA<InvalidAccountCurrency>(),
      );
      expect(
        await falla(400, {'code': 'INVALID_ACCOUNT_NAME'}),
        isA<InvalidAccountName>(),
      );
      expect(
        await falla(409, {'code': 'IDEMPOTENCY_KEY_REUSED'}),
        isA<AccountKeyReused>(),
      );
      expect(
        await falla(403, {'code': 'INVALID_CREDENTIALS', 'intentos_restantes': 2}),
        isA<AccountWrongPin>().having((f) => f.intentosRestantes, 'restantes', 2),
      );
      expect(
        await falla(423, {
          'code': 'DEVICE_LOCKED',
          'locked_until': '2026-10-06T15:00:00+00:00',
        }),
        isA<AccountLocked>(),
      );
    });

    test('abrir manda el body del contrato', () async {
      await repo.abrir(
        tipo: AccountType.sueldo,
        moneda: Currency.pen,
        nombre: 'Planilla',
        pin: '000000',
        idempotencyKey: 'k-000002',
      );
      final req = backend.requests.last;
      expect(req.method, 'POST');
      expect(req.path, '/v1/accounts');
      expect(req.data, {
        'tipo': 'sueldo',
        'moneda': 'PEN',
        'nombre': 'Planilla',
        'pin': '000000',
        'idempotency_key': 'k-000002',
      });
    });
  });

  group('HttpAccountRepository · contrato JSON', () {
    test(
      'un movimiento con moneda desconocida es inesperado, no soles',
      () async {
        backend.forced = (
          status: 200,
          body: {
            'movimientos': [
              {
                'transaction_id': 'tx-x',
                'tipo': 'transferencia',
                'estado': 'confirmada',
                'direccion': 'debito',
                'monto': 100,
                'moneda': 'EUR',
                'contraparte': null,
                'motivo': null,
                'saldo_posterior': 0,
                'created_at': '2026-10-05T19:30:00.000000Z',
              },
            ],
            'next_cursor': null,
          },
        );

        final r = await repo.movimientos('acc-demo-1');
        expect(r.isLeft(), isTrue);
        expect(r.getLeft().toNullable(), isA<Unexpected<AccountFailure>>());
      },
    );

    test('las fechas con Z se leen como UTC, sin desplazarlas', () async {
      final items = (await repo.movimientos(
        'acc-demo-1',
      )).getRight().toNullable()!.items;

      expect(items.first.fecha, DateTime.utc(2026, 10, 5, 19, 30));
      expect(items.first.fecha.isUtc, isTrue);
    });

    test('el cursor viaja como query solo cuando existe', () async {
      await repo.movimientos('acc-demo-1', cursor: 'abc=');

      expect(backend.requests.last.queryParameters['cursor'], 'abc=');
      await repo.movimientos('acc-demo-1');
      expect(
        backend.requests.last.queryParameters.containsKey('cursor'),
        isFalse,
      );
    });

    test('un tipo desconocido cae en otro; el motivo se conserva', () async {
      backend.forced = (
        status: 200,
        body: {
          'movimientos': [
            {
              'transaction_id': 't',
              'tipo': 'pago_qr',
              'estado': 'confirmada',
              'direccion': 'debito',
              'monto': 1,
              'moneda': 'PEN',
              'contraparte': null,
              'motivo': null,
              'saldo_posterior': 1,
              'created_at': '2026-10-05T19:30:00.000000Z',
            },
          ],
          'next_cursor': 'siguiente',
        },
      );

      final p = (await repo.movimientos('acc-demo-1')).getRight().toNullable()!;
      expect(p.items.single.tipo.name, 'otro');
      expect(p.nextCursor, 'siguiente');
    });
  });
}
