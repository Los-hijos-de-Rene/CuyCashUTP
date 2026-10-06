import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../transfer/domain/recipient_account.dart';
import '../domain/beneficiary.dart';
import '../domain/beneficiary_failure.dart';
import '../domain/beneficiary_repository.dart';

/// Impl real contra `services/api` (`GET/POST /v1/beneficiaries`,
/// `DELETE /v1/beneficiaries/{id}`).
///
/// [dio] debe venir de `buildAuthenticatedDio`. Errores: cuerpo PLANO
/// `{code, detail, <extras en la raíz>}`; se mapea por `code`, NUNCA por el
/// texto de `detail`. El alta responde 201 también cuando solo actualiza el
/// apodo (decisión pendiente en el backend): aquí cualquier 2xx es éxito.
class HttpBeneficiaryRepository implements BeneficiaryRepository {
  HttpBeneficiaryRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  FutureResult<BeneficiaryFailure, List<Beneficiary>> listar() =>
      _guard(() async {
        final response = await _dio.get<dynamic>('/v1/beneficiaries');
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        final lista = _cuerpo(response)['beneficiarios'] as List;
        return right([
          for (final b in lista)
            Beneficiary(
              id: (b as Map<String, dynamic>)['id'] as String,
              dni: b['dni'] as String,
              apodo: b['apodo'] as String,
              nombreEnmascarado: b['nombre_enmascarado'] as String?,
              cuenta: switch (b['cuenta']) {
                final Map<String, dynamic> c => recipientAccountFromJson(c),
                _ => null,
              },
            ),
        ]);
      });

  @override
  FutureResult<BeneficiaryFailure, Unit> guardar({
    required String cuentaDestinoId,
    required String apodo,
  }) =>
      _guard(() async {
        final response = await _dio.post<dynamic>(
          '/v1/beneficiaries',
          data: {'cuenta_destino_id': cuentaDestinoId, 'apodo': apodo},
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(unit);
      });

  @override
  FutureResult<BeneficiaryFailure, Unit> eliminar(String id) =>
      _guard(() async {
        final response = await _dio.delete<dynamic>(
          '/v1/beneficiaries/${Uri.encodeComponent(id)}',
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        return right(unit);
      });

  Map<String, dynamic> _cuerpo(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Cuerpo que no es un objeto JSON');
  }

  BeneficiaryFailure? _failureFor(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return null;
    if (status == 401) return const BeneficiaryFailure.unauthenticated();

    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'RECIPIENT_NOT_FOUND' => const BeneficiaryFailure.recipientNotFound(),
      // 429 con `retry_after_seconds` en la raíz (opcional para el failure).
      'RATE_LIMITED' => BeneficiaryFailure.rateLimited(
        switch (body['retry_after_seconds']) {
          final num s => Duration(seconds: s.ceil()),
          _ => null,
        },
      ),
      _ => const BeneficiaryFailure.unexpected(),
    };
  }

  Future<Either<GlobalFailure<BeneficiaryFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<BeneficiaryFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      return left(
        GlobalFailure.server(switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.connectionError => const BeneficiaryFailure.network(),
          _ => const BeneficiaryFailure.unexpected(),
        }),
      );
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
