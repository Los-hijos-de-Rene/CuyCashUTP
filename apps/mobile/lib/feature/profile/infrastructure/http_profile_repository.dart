import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/personal_data.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';

/// Impl real contra `services/api` (`GET /v1/me`, `PATCH /v1/me/alias`).
/// [dio] debe venir de `buildAuthenticatedDio`. Errores por `code`, nunca por
/// el texto de `detail`.
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  FutureResult<ProfileFailure, PersonalData> me() => _guard(() async {
        final response = await _dio.get<dynamic>('/v1/me');
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(_datos(_cuerpo(response)));
      });

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) =>
      _guard(() async {
        final response =
            await _dio.patch<dynamic>('/v1/me/alias', data: {'alias': alias});
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(_cuerpo(response)['alias'] as String);
      });

  PersonalData _datos(Map<String, dynamic> j) => PersonalData(
        dni: j['dni'] as String,
        nombres: j['nombres'] as String,
        apellidos: j['apellidos'] as String,
        emailMasked: j['email_masked'] as String,
        alias: j['alias'] as String,
        kycVerified: j['kyc_status'] == 'verified',
        clienteDesde: DateTime.parse(j['created_at'] as String).toUtc(),
      );

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  ProfileFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;
    if (status == 401) return const ProfileFailure.unauthenticated();
    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'INVALID_ALIAS' => const ProfileFailure.invalidAlias(),
      'ALIAS_TAKEN' => const ProfileFailure.aliasTaken(),
      _ => const ProfileFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<ProfileFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<ProfileFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      return left(GlobalFailure.server(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => const ProfileFailure.network(),
        _ => const ProfileFailure.unexpected(),
      }));
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
