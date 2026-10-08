import 'package:core_kernel/core_kernel.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/dev_tools_repository.dart';

/// Impl contra las rutas `/v1/dev/*` del backend local.
///
/// La clave viaja en `X-Dev-Key`. Es una clave de desarrollo (está en
/// `config.local.json`, que git no sube): su único fin es que alguien más en
/// el mismo Wi-Fi no pueda vaciar tu base local.
class HttpDevToolsRepository implements DevToolsRepository {
  HttpDevToolsRepository({required Dio dio, required String devKey})
      : _dio = dio,
        _key = devKey;

  final Dio _dio;
  final String _key;

  Options get _options => Options(headers: {'X-Dev-Key': _key});

  @override
  FutureResult<DevToolsFailure, DevSeed> resetAndSeed() =>
      _seedCall('/v1/dev/reset-y-seed');

  @override
  FutureResult<DevToolsFailure, DevSeed> seed() => _seedCall('/v1/dev/seed');

  @override
  FutureResult<DevToolsFailure, List<DevOtp>> latestOtps() => _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/v1/dev/otp',
          options: _options,
        );
        final failure = _failureFor(response.statusCode);
        if (failure != null) return left(GlobalFailure.server(failure));
        final codes = response.data?['codigos'];
        return right([
          if (codes is List)
            for (final item in codes)
              if (item is Map)
                DevOtp(
                  destination: '${item['destino'] ?? ''}',
                  code: '${item['codigo'] ?? ''}',
                  purpose: '${item['proposito'] ?? ''}',
                ),
        ]);
      });

  FutureResult<DevToolsFailure, DevSeed> _seedCall(String path) =>
      _guard(() async {
        final response =
            await _dio.post<Map<String, dynamic>>(path, options: _options);
        final failure = _failureFor(response.statusCode);
        if (failure != null) return left(GlobalFailure.server(failure));
        final data = response.data ?? const {};
        final users = data['usuarios'];
        return right(DevSeed(
          pin: '${data['pin'] ?? ''}',
          users: [
            if (users is List)
              for (final u in users)
                if (u is Map)
                  DevTestUser(
                    dni: '${u['dni'] ?? ''}',
                    name: '${u['nombre'] ?? ''}',
                    alias: '${u['alias'] ?? ''}',
                  ),
          ],
        ));
      });

  static DevToolsFailure? _failureFor(int? status) => switch (status) {
        200 => null,
        403 => const DevToolsFailure.wrongKey(),
        _ => const DevToolsFailure.unavailable(),
      };

  Future<Either<GlobalFailure<DevToolsFailure>, T>> _guard<T>(
    Future<Either<GlobalFailure<DevToolsFailure>, T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (_) {
      return left(const GlobalFailure.server(DevToolsFailure.unavailable()));
    } catch (error, stackTrace) {
      return left(GlobalFailure.unexpected(error, stackTrace));
    }
  }
}
