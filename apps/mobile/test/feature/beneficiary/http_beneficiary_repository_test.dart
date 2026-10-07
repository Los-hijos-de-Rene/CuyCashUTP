import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/http/authenticated_dio.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary_failure.dart';
import 'package:cuycash/feature/beneficiary/infrastructure/http_beneficiary_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'beneficiary_repository_contract.dart';

/// Backend simulado y CON ESTADO: reproduce el JSON, los códigos y el orden de
/// validación de `services/api/.../directory.py` (cuerpo de error PLANO
/// `{code, detail, <extras>}`; alta 201 también al actualizar; baja 204;
/// presupuesto 429).
class FakeBeneficiariesBackend implements HttpClientAdapter {
  static const dniConocido = '87654321';
  static const cuentaConocida = 'acc-ext-1';
  static const cuentaConocida2 = 'acc-ext-2';
  static const consultasMaximas = 20;
  static const nombre = 'J*** M*** R***';

  /// cuenta_id → su forma en `cuenta` (como la sirve el directorio).
  static const cuentas = <String, Map<String, Object?>>{
    cuentaConocida: {
      'cuenta_id': cuentaConocida,
      'tipo': 'ahorro',
      'moneda': 'PEN',
      'numero_masked': '••••7732',
      'nombre': null,
    },
    cuentaConocida2: {
      'cuenta_id': cuentaConocida2,
      'tipo': 'corriente',
      'moneda': 'PEN',
      'numero_masked': '••••5510',
      'nombre': null,
    },
  };

  /// Fuerza `cuenta` de cada fila en el GET (p. ej. `null` o una inválida).
  Object? cuentaForzada = _sinForzar;
  static const _sinForzar = Object();

  ({int status, Object? body})? forced;
  DioException? throwIt;
  final requests = <RequestOptions>[];

  int consultas = 0;
  int secuencia = 0;
  final filas = <Map<String, String>>[];

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
      body == null ? '' : (body is String ? body : jsonEncode(body)),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  (int, Object?) _route(RequestOptions o) {
    final path = o.uri.path;
    if (path == '/v1/beneficiaries' && o.method == 'GET') return _listar();
    if (path == '/v1/beneficiaries' && o.method == 'POST') {
      return _guardar(o.data as Map<String, dynamic>);
    }
    if (path.startsWith('/v1/beneficiaries/') && o.method == 'DELETE') {
      filas.removeWhere((f) => f['id'] == path.split('/').last);
      return (204, null);
    }
    return _error(404, 'NOPE');
  }

  (int, Object?) _listar() => (
    200,
    {
      'beneficiarios': [
        for (final f in filas.reversed)
          {
            'id': f['id'],
            'dni': f['dni'],
            'apodo': f['apodo'],
            'nombre_enmascarado': nombre,
            'cuenta': identical(cuentaForzada, _sinForzar)
                ? cuentas[f['cuenta_id']]
                : cuentaForzada,
          },
      ],
    },
  );

  (int, Object?) _guardar(Map<String, dynamic> b) {
    final cuentaId = b['cuenta_destino_id'] as String;
    final apodo = b['apodo'] as String;
    // Pydantic: apodo de 1 a 40.
    if (apodo.isEmpty || apodo.length > 40) return (422, {'detail': <Object?>[]});
    if (consultas >= consultasMaximas) {
      return _error(429, 'RATE_LIMITED', {'retry_after_seconds': 312});
    }
    consultas++;
    if (!cuentas.containsKey(cuentaId)) {
      return _error(404, 'RECIPIENT_NOT_FOUND');
    }
    final i = filas.indexWhere((f) => f['cuenta_id'] == cuentaId);
    if (i >= 0) {
      filas[i] = {...filas[i], 'apodo': apodo};
    } else {
      filas.add({
        'id': 'ben-${++secuencia}',
        'dni': dniConocido,
        'cuenta_id': cuentaId,
        'apodo': apodo,
      });
    }
    return (201, {'ok': true});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeBeneficiariesBackend backend;
  late HttpBeneficiaryRepository repo;
  var sesionVencida = 0;

  HttpBeneficiaryRepository nuevo() {
    backend = FakeBeneficiariesBackend();
    final dio = buildAuthenticatedDio(
      baseUrl: 'http://10.0.2.2:8001',
      deviceId: 'telefono-1',
      readToken: () => 'tok-1',
      onUnauthenticated: () => sesionVencida++,
    )..httpClientAdapter = backend;
    return repo = HttpBeneficiaryRepository(dio: dio);
  }

  setUp(() {
    sesionVencida = 0;
    nuevo();
  });

  probarContratoDeBeneficiarios(
    'HttpBeneficiaryRepository',
    nuevo,
    dniConocido: FakeBeneficiariesBackend.dniConocido,
    cuentaConocida: FakeBeneficiariesBackend.cuentaConocida,
    cuentaConocida2: FakeBeneficiariesBackend.cuentaConocida2,
    consultasMaximas: FakeBeneficiariesBackend.consultasMaximas,
  );

  BeneficiaryFailure falloDe(Result<BeneficiaryFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<BeneficiaryFailure>>());
    return (failure! as ServerFailure<BeneficiaryFailure>).failure;
  }

  group('HttpBeneficiaryRepository · detalles del cable', () {
    test('guardar manda cuenta_destino_id y apodo y trata el 201 como éxito',
        () async {
      final r = await repo.guardar(
        cuentaDestinoId: 'acc-ext-1',
        apodo: 'Carlos',
      );
      expect(r.isRight(), isTrue);
      final req = backend.requests.single;
      expect(req.method, 'POST');
      expect(req.data, {'cuenta_destino_id': 'acc-ext-1', 'apodo': 'Carlos'});
    });

    test('RATE_LIMITED lee retry_after_seconds de la RAÍZ', () async {
      backend.forced = (
        status: 429,
        body: {
          'code': 'RATE_LIMITED',
          'detail': 'x',
          'retry_after_seconds': 312,
        },
      );
      final f = falloDe(await repo.guardar(cuentaDestinoId: 'acc-ext-1', apodo: 'C'));
      expect(
        (f as BeneficiaryRateLimited).reintentarEn,
        const Duration(seconds: 312),
      );
    });

    test('un 401 es unauthenticated', () async {
      backend.forced = (
        status: 401,
        body: {'code': 'UNAUTHENTICATED', 'detail': 'x'},
      );
      expect(
        falloDe(await repo.listar()),
        isA<BeneficiaryUnauthenticated>(),
      );
    });

    test('sin red es network', () async {
      backend.throwIt = DioException(
        requestOptions: RequestOptions(path: '/v1/beneficiaries'),
        type: DioExceptionType.connectionError,
      );
      expect(falloDe(await repo.listar()), isA<BeneficiaryNetworkFailure>());
    });

    test('un código desconocido o un 500 es unexpected', () async {
      backend.forced = (status: 500, body: {'code': 'BOOM', 'detail': 'x'});
      expect(
        falloDe(await repo.guardar(cuentaDestinoId: 'acc-ext-1', apodo: 'C')),
        isA<BeneficiaryUnexpectedFailure>(),
      );
    });

    test('un JSON malformado no revienta: es un failure', () async {
      backend.forced = (status: 200, body: '[no es un objeto]');
      final r = await repo.listar();
      expect(r.isLeft(), isTrue);
    });

    test('un frecuente con cuenta: null se lee como null', () async {
      await repo.guardar(cuentaDestinoId: 'acc-ext-1', apodo: 'C');
      backend.cuentaForzada = null;
      final b = (await repo.listar()).getRight().toNullable()?.single;
      expect(b, isNotNull);
      expect(b?.cuenta, isNull);
      expect(b?.dni, '87654321');
    });

    test('una moneda desconocida en cuenta es un fallo inesperado', () async {
      await repo.guardar(cuentaDestinoId: 'acc-ext-1', apodo: 'C');
      backend.cuentaForzada = {
        ...FakeBeneficiariesBackend.cuentas['acc-ext-1']!,
        'moneda': 'EUR',
      };
      final r = await repo.listar();
      expect(r.getLeft().toNullable(), isA<Unexpected<BeneficiaryFailure>>());
    });
  });
}
