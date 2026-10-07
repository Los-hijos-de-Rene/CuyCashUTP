import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/kyc_failure.dart';
import '../domain/kyc_repository.dart';
import '../domain/liveness_challenge.dart';
import '../domain/liveness_step.dart';

/// Impl real del KYC facial, a través del proxy de `services/api`
/// (`/v1/kyc/...`).
///
/// La app ya NO conoce la API key del microservicio: la agrega el backend, que
/// es el único que la guarda. Por eso este repositorio usa el mismo `Dio` que
/// el resto de las features (con `X-Device-Id`) y no uno propio con clave.
class HttpKycRepository implements KycRepository {
  HttpKycRepository({
    required Dio dio,
    this.verifyTimeout = const Duration(seconds: 120),
  }) : _dio = dio;

  final Dio _dio;

  /// `verify-full` corre varios modelos en CPU (detección, embeddings,
  /// MediaPipe) y, en un servicio recién despertado, además los carga. Su
  /// espera es la de esa llamada, no la general del cliente.
  final Duration verifyTimeout;

  static const _challengePath = '/v1/kyc/liveness/challenge';
  static const _verifyFullPath = '/v1/kyc/identity/verify-full';

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
          // pedirle al usuario algo que no sabemos guiar sería peor.
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

        final response = await _dio.post<Map<String, dynamic>>(
          _verifyFullPath,
          data: form,
          options: Options(
            sendTimeout: verifyTimeout,
            receiveTimeout: verifyTimeout,
          ),
        );
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

    // El servicio distingue el token vencido solo por el texto del detalle.
    // Es frágil, pero es el contrato que hay.
    final detail = (response.data?['detail'] ?? '').toString().toLowerCase();
    if (detail.contains('inválido') || detail.contains('expirado')) {
      return const KycFailure.challengeExpired();
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
