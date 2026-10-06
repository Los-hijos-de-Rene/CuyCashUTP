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
  static const dniPropio = '70123456';
  static const dniConocido = '87654321';
  static const dniConocido2 = '43219876';
  static const consultasMaximas = 20;
  static const nombres = {
    dniConocido: 'J*** M*** R***',
    dniConocido2: 'C*** A*** N***',
  };

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
            'nombre_enmascarado': nombres[f['dni']],
          },
      ],
    },
  );

  (int, Object?) _guardar(Map<String, dynamic> b) {
    final dni = b['dni'] as String;
    final apodo = b['apodo'] as String;
    // Pydantic: 8 dígitos, apodo de 1 a 40.
    if (!RegExp(r'^\d{8}$').hasMatch(dni) ||
        apodo.isEmpty ||
        apodo.length > 40) {
      return (422, {'detail': <Object?>[]});
    }
    if (dni == dniPropio) return _error(400, 'SELF_TRANSFER');
    if (consultas >= consultasMaximas) {
      return _error(429, 'RATE_LIMITED', {'retry_after_seconds': 312});
    }
    consultas++;
    if (!nombres.containsKey(dni)) return _error(404, 'RECIPIENT_NOT_FOUND');
    final i = filas.indexWhere((f) => f['dni'] == dni);
    if (i >= 0) {
      filas[i] = {...filas[i], 'apodo': apodo};
    } else {
      filas.add({'id': 'ben-${++secuencia}', 'dni': dni, 'apodo': apodo});
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
    dniPropio: FakeBeneficiariesBackend.dniPropio,
    dniConocido: FakeBeneficiariesBackend.dniConocido,
    dniConocido2: FakeBeneficiariesBackend.dniConocido2,
    consultasMaximas: FakeBeneficiariesBackend.consultasMaximas,
  );

  BeneficiaryFailure falloDe(Result<BeneficiaryFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<BeneficiaryFailure>>());
    return (failure! as ServerFailure<BeneficiaryFailure>).failure;
  }

  group('HttpBeneficiaryRepository · detalles del cable', () {
    test('guardar manda dni y apodo y trata el 201 como éxito', () async {
      final r = await repo.guardar('87654321', 'Carlos');
      expect(r.isRight(), isTrue);
      final req = backend.requests.single;
      expect(req.method, 'POST');
      expect(req.data, {'dni': '87654321', 'apodo': 'Carlos'});
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
      final f = falloDe(await repo.guardar('87654321', 'C'));
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
        falloDe(await repo.guardar('87654321', 'C')),
        isA<BeneficiaryUnexpectedFailure>(),
      );
    });

    test('un JSON malformado no revienta: es un failure', () async {
      backend.forced = (status: 200, body: '[no es un objeto]');
      final r = await repo.listar();
      expect(r.isLeft(), isTrue);
    });
  });
}
