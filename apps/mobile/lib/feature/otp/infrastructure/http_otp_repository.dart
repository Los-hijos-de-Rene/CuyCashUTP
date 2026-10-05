import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/otp_challenge.dart';
import '../domain/otp_failure.dart';
import '../domain/otp_policy.dart';
import '../domain/otp_repository.dart';

/// Impl real del OTP contra `services/api`.
///
/// El código nunca llega al teléfono: se manda al correo y el servidor lo
/// verifica. Aquí solo viajan el reto y el resultado.
class HttpOtpRepository implements OtpRepository {
  HttpOtpRepository({required Dio dio}) : _dio = dio;

  factory HttpOtpRepository.withConfig({
    required String baseUrl,
    required String deviceId,
    Duration connectTimeout = const Duration(seconds: 20),
    // Más larga que la de conexión por el arranque en frío del hosting: ver
    // la nota en `HttpAuthRepository.withConfig`.
    Duration receiveTimeout = const Duration(seconds: 70),
  }) =>
      HttpOtpRepository(
        dio: Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          headers: {'X-Device-Id': deviceId},
          validateStatus: (status) => status != null && status < 500,
        )),
      );

  final Dio _dio;

  @override
  FutureResult<OtpFailure, OtpChallenge> request(String identifier) =>
      _guard(() async {
        // El propósito lo decide el identificador: un correo es recuperación;
        // un DNI, verificación de teléfono.
        final purpose = identifier.contains('@') ? 'recovery' : 'device';
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/otp/challenges',
          data: {'purpose': purpose, 'identifier': identifier},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));
        return _parseChallenge(response.data);
      });

  @override
  FutureResult<OtpFailure, String> verify({
    required String challengeId,
    required String code,
  }) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/otp/challenges/$challengeId/verify',
          data: {'code': code},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final ticket = response.data?['otp_ticket'];
        if (ticket is! String) {
          return left(const GlobalFailure.server(OtpFailure.challengeNotFound()));
        }
        return right(ticket);
      });

  @override
  FutureResult<OtpFailure, OtpChallenge> resend(String challengeId) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/v1/otp/challenges/$challengeId/resend',
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));

        final data = response.data ?? const {};
        final expires = DateTime.tryParse('${data['expires_at']}');
        final cooldown = DateTime.tryParse('${data['cooldown_until']}');
        if (expires == null || cooldown == null) {
          return left(const GlobalFailure.server(OtpFailure.challengeNotFound()));
        }
        // El reenvío no devuelve el correo enmascarado: la pantalla ya lo tiene
        // del reto original.
        return right(OtpChallenge(
          id: challengeId,
          maskedEmail: '',
          expiresAt: expires,
          cooldownUntil: cooldown,
          attemptsLeft: OtpPolicy.maxAttempts,
          resendsLeft: data['resends_left'] as int? ?? 0,
        ));
      });

  Either<GlobalFailure<OtpFailure>, OtpChallenge> _parseChallenge(
    Map<String, dynamic>? data,
  ) {
    final id = data?['challenge_id'];
    final expires = DateTime.tryParse('${data?['expires_at']}');
    final cooldown = DateTime.tryParse('${data?['cooldown_until']}');
    if (id is! String || expires == null || cooldown == null) {
      return left(const GlobalFailure.server(OtpFailure.challengeNotFound()));
    }
    return right(OtpChallenge(
      id: id,
      maskedEmail: data?['masked_email'] as String? ?? '',
      expiresAt: expires,
      cooldownUntil: cooldown,
      attemptsLeft: data?['attempts_left'] as int? ?? OtpPolicy.maxAttempts,
      resendsLeft: data?['resends_left'] as int? ?? OtpPolicy.maxResends,
    ));
  }

  /// Mapea por `code`, nunca por el texto del `detail`.
  OtpFailure? _failureFor(Response<Map<String, dynamic>> response) {
    final status = response.statusCode ?? 0;
    if (status == 200 || status == 201) return null;

    final data = response.data ?? const {};
    return switch (data['code']) {
      // Un código equivocado no cancela nada: informa cuántos intentos quedan.
      'INVALID_CREDENTIALS' =>
        OtpFailure.invalidCode(data['attempts_left'] as int? ?? 0),
      'CHALLENGE_EXPIRED' => const OtpFailure.codeExpired(),
      'CHALLENGE_CANCELLED' => OtpFailure.challengeCancelled(
          data['reason'] == 'resends'
              ? OtpCancelReason.resends
              : OtpCancelReason.attempts,
        ),
      'UNAUTHENTICATED' || 'INVALID_TICKET' =>
        const OtpFailure.challengeNotFound(),
      _ => const OtpFailure.serviceUnavailable(),
    };
  }

  Future<Either<GlobalFailure<OtpFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<OtpFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (_) {
      return left(const GlobalFailure.server(OtpFailure.serviceUnavailable()));
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
