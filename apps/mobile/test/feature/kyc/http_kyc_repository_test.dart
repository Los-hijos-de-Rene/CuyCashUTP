import 'dart:convert';
import 'dart:typed_data';

import 'package:cuycash/feature/kyc/domain/document_check.dart';
import 'package:cuycash/feature/kyc/domain/kyc_failure.dart';
import 'package:cuycash/feature/kyc/domain/liveness_step.dart';
import 'package:cuycash/feature/kyc/infrastructure/http_kyc_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_kyc_repository_test.dart' show failureOf;

/// Adaptador que devuelve una respuesta preparada, para poder probar el mapeo
/// de estados y textos del servicio sin levantarlo ni tocar la red.
class _FakeAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Map<String, dynamic> body = const {};
  DioException? throwIt;

  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (throwIt case final error?) throw error;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;
  late HttpKycRepository repo;

  setUp(() {
    adapter = _FakeAdapter();
    // Como el `Dio` autenticado de la app: base del backend, `X-Device-Id`,
    // y SIN ninguna clave del microservicio.
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8001',
        headers: {'X-Device-Id': 'device-1'},
        validateStatus: (status) => status != null && status < 500,
      ),
    )..httpClientAdapter = adapter;
    repo = HttpKycRepository(dio: dio);
  });

  test('habla con el proxy del backend, no con el microservicio', () async {
    adapter.body = {
      'token': 't',
      'steps': ['izquierda'],
      'expires_in': 180,
    };

    await repo.requestChallenge();

    expect(adapter.lastRequest?.path, '/v1/kyc/liveness/challenge');
    // La clave la agrega el backend: la app no debe conocerla.
    expect(adapter.lastRequest?.headers.containsKey('X-API-Key'), isFalse);
  });

  test('el desafío se lee con sus tareas en el orden del servidor', () async {
    adapter.body = {
      'token': 'w9xQ',
      'steps': ['derecha', 'parpadeo'],
      'expires_in': 180,
    };

    final challenge = (await repo.requestChallenge()).getRight().toNullable()!;

    expect(challenge.token, 'w9xQ');
    expect(challenge.steps, [LivenessStep.derecha, LivenessStep.parpadeo]);
  });

  test(
    'una tarea desconocida invalida el desafío en vez de adivinarse',
    () async {
      adapter.body = {
        'token': 'w9xQ',
        'steps': ['abajo', 'saltar'],
        'expires_in': 180,
      };

      // Pedirle al usuario algo que la app no sabe guiar sería peor que fallar.
      expect(failureOf(await repo.requestChallenge()), isA<InvalidResponse>());
    },
  );

  test(
    '401 se lee como configuración inválida, no como culpa del usuario',
    () async {
      adapter.statusCode = 401;
      adapter.body = {'detail': 'Invalid API Key'};

      expect(failureOf(await repo.requestChallenge()), isA<Unauthorized>());
    },
  );

  test(
    '503 del proxy y la red caída dan el mismo failure de servicio',
    () async {
      adapter.statusCode = 503;
      expect(
        failureOf(await repo.requestChallenge()),
        isA<ServiceUnavailable>(),
      );

      adapter.throwIt = DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: RequestOptions(path: '/'),
      );
      expect(
        failureOf(await repo.requestChallenge()),
        isA<ServiceUnavailable>(),
      );
    },
  );

  test('un 400 de token vencido o ya usado pide rehacer el desafío', () async {
    adapter.statusCode = 400;
    adapter.body = {
      'detail': 'Token de desafío inválido o expirado. Reinicia el liveness',
    };

    final result = await repo.verifyFull(
      token: 'w9xQ',
      documentImage: Uint8List.fromList([1]),
      segments: const {},
    );

    expect(failureOf(result), isA<ChallengeExpired>());
  });

  test('cualquier otro 400 es una respuesta que no encaja', () async {
    adapter.statusCode = 400;
    adapter.body = {'detail': 'Faltan segmentos de frames para: parpadeo'};

    final result = await repo.verifyFull(
      token: 'w9xQ',
      documentImage: Uint8List.fromList([1]),
      segments: const {},
    );

    expect(failureOf(result), isA<InvalidResponse>());
  });

  test(
    'verify-full manda el documento y los segmentos en UNA llamada',
    () async {
      adapter.body = {
        'overall_result': true,
        'overall_reason': 'Verificación de identidad exitosa',
        'document_validation': {'is_valid': true},
        'liveness': {'is_live': true},
        'face_match': {'is_match': true},
      };

      final result = await repo.verifyFull(
        token: 'w9xQ',
        documentImage: Uint8List.fromList([1, 2, 3]),
        segments: {
          LivenessStep.izquierda: const ['a', 'b'],
        },
      );

      final veredicto = result.getRight().toNullable()!;
      expect(veredicto.approved, isTrue);
      expect(veredicto.documentValid, isTrue);
      expect(veredicto.faceMatch, isTrue);
      expect(adapter.lastRequest?.path, '/v1/kyc/identity/verify-full');
      expect(adapter.lastRequest?.data, isA<FormData>());
      // Los modelos corren en CPU: su espera no es la general del cliente.
      expect(adapter.lastRequest?.receiveTimeout, repo.verifyTimeout);
    },
  );

  test('el frente rechazado trae sus motivos como códigos', () async {
    adapter.body = {
      'is_valid': false,
      'codes': ['blurry', 'too_dark'],
    };

    final check = (await repo.checkDocumentFront(
      Uint8List.fromList([1]),
      expectedDni: '12345678',
    )).getRight().toNullable()!;

    expect(adapter.lastRequest?.path, '/v1/kyc/document/validate');
    expect(check.issues, [DocumentIssue.blurry, DocumentIssue.tooDark]);
    // El DNI escrito viaja: el servidor comprueba que esté impreso en el frente.
    final form = adapter.lastRequest?.data as FormData;
    expect(Map.fromEntries(form.fields)['expected_dni'], '12345678');
  });

  test('un frente de otro DNI trae su propio motivo', () async {
    adapter.body = {
      'is_valid': false,
      'codes': ['front_dni_mismatch'],
    };

    final check = (await repo.checkDocumentFront(
      Uint8List.fromList([1]),
      expectedDni: '12345678',
    )).getRight().toNullable()!;

    expect(check.mainIssue, DocumentIssue.frontDniMismatch);
  });

  test(
    'reverso ilegible y reverso de otro DNI son motivos distintos',
    () async {
      adapter.body = {'found': false, 'valid': false};
      final ilegible = (await repo.checkDocumentBack(
        Uint8List.fromList([1]),
        expectedDni: '12345678',
      )).getRight().toNullable()!;
      expect(ilegible.mainIssue, DocumentIssue.backUnreadable);

      adapter.body = {
        'found': true,
        'valid': true,
        'dni': '87654321',
        'matches_expected': false,
      };
      final ajeno = (await repo.checkDocumentBack(
        Uint8List.fromList([1]),
        expectedDni: '12345678',
      )).getRight().toNullable()!;
      expect(adapter.lastRequest?.path, '/v1/kyc/document/mrz');
      expect(ajeno.mainIssue, DocumentIssue.dniMismatch);
    },
  );

  test('verify-full manda el reverso y el DNI declarado', () async {
    adapter.body = {
      'overall_result': true,
      'document_data': {'matches_expected': true},
    };

    final veredicto = (await repo.verifyFull(
      token: 't',
      documentImage: Uint8List.fromList([1]),
      documentBackImage: Uint8List.fromList([2]),
      expectedDni: '12345678',
      segments: const {},
    )).getRight().toNullable()!;

    final form = adapter.lastRequest?.data as FormData;
    expect(form.files.map((f) => f.key), contains('document_back_image'));
    expect(Map.fromEntries(form.fields)['expected_dni'], '12345678');
    expect(veredicto.dniMatches, isTrue);
  });

  test('sin `overall_result` no se inventa un veredicto', () async {
    adapter.body = {'overall_reason': 'algo'};

    final result = await repo.verifyFull(
      token: 'w9xQ',
      documentImage: Uint8List.fromList([1]),
      segments: const {},
    );

    expect(failureOf(result), isA<InvalidResponse>());
  });
}
