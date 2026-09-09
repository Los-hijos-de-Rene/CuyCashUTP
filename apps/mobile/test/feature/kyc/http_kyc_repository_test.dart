import 'dart:convert';
import 'dart:typed_data';

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
    final dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      headers: {'X-API-Key': 'demo'},
      validateStatus: (status) => status != null && status < 500,
    ))..httpClientAdapter = adapter;
    repo = HttpKycRepository(dio: dio);
  });

  test('el desafío se lee con sus tareas en el orden del servidor', () async {
    adapter.body = {
      'token': 'w9xQ',
      'steps': ['abajo', 'izquierda', 'parpadeo'],
      'expires_in': 180,
    };

    final challenge =
        (await repo.requestChallenge()).getRight().toNullable()!;

    expect(challenge.token, 'w9xQ');
    expect(challenge.steps, [
      LivenessStep.abajo,
      LivenessStep.izquierda,
      LivenessStep.parpadeo,
    ]);
  });

  test('una tarea desconocida invalida el desafío en vez de adivinarse',
      () async {
    adapter.body = {
      'token': 'w9xQ',
      'steps': ['abajo', 'saltar'],
      'expires_in': 180,
    };

    // Pedirle al usuario algo que la app no sabe dibujar sería peor que fallar.
    expect(failureOf(await repo.requestChallenge()), isA<InvalidResponse>());
  });

  test('401 se lee como configuración inválida, no como culpa del usuario',
      () async {
    adapter.statusCode = 401;
    adapter.body = {'detail': 'Invalid API Key'};

    expect(failureOf(await repo.requestChallenge()), isA<Unauthorized>());
  });

  test('500 y la red caída dan el mismo failure de servicio', () async {
    adapter.statusCode = 503;
    expect(failureOf(await repo.requestChallenge()), isA<ServiceUnavailable>());

    adapter.throwIt = DioException.connectionTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: RequestOptions(path: '/'),
    );
    expect(failureOf(await repo.requestChallenge()), isA<ServiceUnavailable>());
  });

  group('los tres casos de negocio que el servicio mete en un mismo 400', () {
    setUp(() => adapter.statusCode = 400);

    test('token vencido → hay que rehacer el desafío', () async {
      adapter.body = {'detail': 'Token de desafío inválido o expirado'};

      final result = await repo.evaluateStep(
          token: 'x', step: LivenessStep.abajo, framesBase64: const ['a']);

      expect(failureOf(result), isA<ChallengeExpired>());
    });

    test('tarea fuera de orden → se conserva cuál esperaba el servidor',
        () async {
      adapter.body = {'detail': "Se esperaba la tarea 'izquierda'"};

      final result = await repo.evaluateStep(
          token: 'x', step: LivenessStep.abajo, framesBase64: const ['a']);

      final failure = failureOf(result);
      expect(failure, isA<StepOutOfOrder>());
      expect((failure as StepOutOfOrder).expected, LivenessStep.izquierda);
    });

    test('desafío completado → toca la verificación final', () async {
      adapter.body = {'detail': 'El desafío ya fue completado'};

      final result = await repo.evaluateStep(
          token: 'x', step: LivenessStep.abajo, framesBase64: const ['a']);

      expect(failureOf(result), isA<ChallengeCompleted>());
    });
  });

  test('un `passed:false` llega como valor, no como failure', () async {
    adapter.body = {
      'step': 'abajo',
      'passed': false,
      'reason': 'No se detectó movimiento',
      'frames_analyzed': 10,
    };

    final result = await repo.evaluateStep(
        token: 'x', step: LivenessStep.abajo, framesBase64: const ['a']);

    // Reintentar es parte del flujo normal: tratarlo como error del sistema
    // haría que la UI mostrara un fallo donde solo hubo un movimiento flojo.
    expect(result.isRight(), isTrue);
    final evaluation = result.getRight().toNullable()!;
    expect(evaluation.passed, isFalse);
    expect(evaluation.reason, 'No se detectó movimiento');
  });

  test('verify-full manda el documento y los segmentos como multipart',
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
        LivenessStep.abajo: const ['a', 'b'],
      },
    );

    final veredicto = result.getRight().toNullable()!;
    expect(veredicto.approved, isTrue);
    expect(veredicto.documentValid, isTrue);
    expect(veredicto.faceMatch, isTrue);
    expect(adapter.lastRequest?.data, isA<FormData>());
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
