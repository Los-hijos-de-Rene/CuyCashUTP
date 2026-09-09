import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/kyc_failure.dart';
import '../domain/kyc_repository.dart';
import '../domain/liveness_challenge.dart';
import '../domain/liveness_step.dart';

/// Impl real contra el microservicio de KYC facial (FastAPI).
///
/// ATENCIÓN — la `X-API-Key` viaja desde la app. Todo lo que se compila en el
/// binario es extraíble, así que esta clave debe considerarse pública: sirve
/// para la demo, NO para producción. El destino correcto es un backend propio
/// que guarde la clave y llame al servicio en nombre del usuario; mientras
/// tanto, la app habla directo. Ver `AppEnv.kycApiKey`.
class HttpKycRepository implements KycRepository {
  HttpKycRepository({required Dio dio}) : _dio = dio;

  /// Construye el cliente con la base y la key ya puestas.
  factory HttpKycRepository.withConfig({
    required String baseUrl,
    required String apiKey,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      HttpKycRepository(
        dio: Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'X-API-Key': apiKey},
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          // Los 4xx se leen como respuesta, no como excepción: el servicio
          // distingue con ellos casos de negocio (token vencido, tarea fuera
          // de orden) que hay que mapear a failures concretos.
          validateStatus: (status) => status != null && status < 500,
        )),
      );

  final Dio _dio;

  static const _challengePath = '/api/v1/liveness/challenge';
  static const _evaluatePath = '/api/v1/liveness/evaluate';
  static const _verifyFullPath = '/api/v1/identity/verify-full';

  @override
  FutureResult<KycFailure, LivenessChallenge> requestChallenge() =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(_challengePath);
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data;
        final token = data?['token'];
        final rawSteps = data?['steps'];
        final expiresIn = data?['expires_in'];
        if (token is! String || rawSteps is! List || expiresIn is! int) {
          return left(const GlobalFailure.server(KycFailure.invalidResponse()));
        }

        final steps = <LivenessStep>[];
        for (final raw in rawSteps) {
          final step = raw is String ? LivenessStep.fromWire(raw) : null;
          // Una tarea que esta versión no conoce invalida el desafío entero:
          // pedirle al usuario algo que no sabemos dibujar sería peor.
          if (step == null) {
            return left(
                const GlobalFailure.server(KycFailure.invalidResponse()));
          }
          steps.add(step);
        }

        return right(LivenessChallenge(
          token: token,
          steps: steps,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        ));
      });

  @override
  FutureResult<KycFailure, StepEvaluation> evaluateStep({
    required String token,
    required LivenessStep step,
    required List<String> framesBase64,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          _evaluatePath,
          data: {
            'token': token,
            'step': step.wireName,
            'frames_base64': framesBase64,
          },
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data;
        final passed = data?['passed'];
        if (passed is! bool) {
          return left(const GlobalFailure.server(KycFailure.invalidResponse()));
        }
        return right(StepEvaluation(
          step: step,
          passed: passed,
          reason: data?['reason'] as String? ?? '',
          framesAnalyzed: data?['frames_analyzed'] as int? ?? 0,
        ));
      });

  @override
  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    required Map<LivenessStep, List<String>> segments,
  }) =>
      _guard(() async {
        final payload = jsonEncode({
          'token': token,
          'segments': {
            for (final entry in segments.entries)
              entry.key.wireName: entry.value,
          },
        });
        final form = FormData.fromMap({
          'document_image': MultipartFile.fromBytes(
            documentImage,
            filename: 'document.jpg',
          ),
          'liveness_frames': payload,
        });

        final response =
            await _dio.post<Map<String, dynamic>>(_verifyFullPath, data: form);
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data;
        final approved = data?['overall_result'];
        if (approved is! bool) {
          return left(const GlobalFailure.server(KycFailure.invalidResponse()));
        }
        return right(KycVerification(
          approved: approved,
          reason: data?['overall_reason'] as String? ?? '',
          documentValid:
              _boolAt(data, 'document_validation', 'is_valid') ?? false,
          isLive: _boolAt(data, 'liveness', 'is_live') ?? false,
          faceMatch: _boolAt(data, 'face_match', 'is_match') ?? false,
        ));
      });

  /// Traduce el estado HTTP y el texto del detalle a un failure de dominio.
  /// Devuelve null cuando la respuesta es utilizable.
  KycFailure? _failureFor(Response<Map<String, dynamic>> response) {
    final status = response.statusCode ?? 0;
    if (status == 200) return null;
    if (status == 401 || status == 403) return const KycFailure.unauthorized();
    if (status != 400) return const KycFailure.serviceUnavailable();

    // El servicio distingue tres casos de negocio dentro del mismo 400, y solo
    // por el texto del detalle. Es frágil, pero es el contrato que hay.
    final detail = (response.data?['detail'] ?? '').toString().toLowerCase();
    if (detail.contains('inválido') || detail.contains('expirado')) {
      return const KycFailure.challengeExpired();
    }
    if (detail.contains('ya fue completado')) {
      return const KycFailure.challengeCompleted();
    }
    if (detail.contains('se esperaba')) {
      final expected = LivenessStep.values.firstWhere(
        (step) => detail.contains(step.wireName),
        orElse: () => LivenessStep.parpadeo,
      );
      return KycFailure.stepOutOfOrder(expected);
    }
    return const KycFailure.invalidResponse();
  }

  static bool? _boolAt(
    Map<String, dynamic>? data,
    String section,
    String field,
  ) {
    final value = data?[section];
    return value is Map && value[field] is bool ? value[field] as bool : null;
  }

  /// Ningún `throw` cruza la capa: red caída, timeout y errores inesperados
  /// salen como failures.
  Future<Either<GlobalFailure<KycFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<KycFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (_) {
      return left(const GlobalFailure.server(KycFailure.serviceUnavailable()));
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
