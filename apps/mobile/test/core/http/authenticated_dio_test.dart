import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cuycash/core/http/authenticated_dio.dart';

void main() {
  group('buildAuthenticatedDio', () {
    test('adjunta el token vigente en cada petición', () async {
      late RequestOptions vista;
      final dio = buildAuthenticatedDio(
        baseUrl: 'http://test',
        deviceId: 'dev-1',
        readToken: () => 'tok-123',
        onUnauthenticated: () {},
      );
      dio.httpClientAdapter = _Adaptador((options) {
        vista = options;
        return ResponseBody.fromString('{}', 200);
      });

      await dio.get<dynamic>('/v1/accounts');

      expect(vista.headers['Authorization'], 'Bearer tok-123');
      expect(vista.headers['X-Device-Id'], 'dev-1');
    });

    test('sin token no adjunta la cabecera', () async {
      late RequestOptions vista;
      final dio = buildAuthenticatedDio(
        baseUrl: 'http://test',
        deviceId: 'dev-1',
        readToken: () => null,
        onUnauthenticated: () {},
      );
      dio.httpClientAdapter = _Adaptador((options) {
        vista = options;
        return ResponseBody.fromString('{}', 200);
      });

      await dio.get<dynamic>('/v1/accounts');

      expect(vista.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'un 401 sin token (login fallido) no avisa de sesión vencida',
      () async {
        var avisos = 0;
        final dio = buildAuthenticatedDio(
          baseUrl: 'http://test',
          deviceId: 'dev-1',
          readToken: () => null,
          onUnauthenticated: () => avisos++,
        );
        dio.httpClientAdapter = _Adaptador(
          (options) => _json('{"code":"INVALID_CREDENTIALS"}', 401),
        );

        await dio.post<dynamic>(
          '/v1/auth/authenticate',
          data: <String, dynamic>{},
        );

        expect(avisos, 0);
      },
    );

    test(
      'un 401 sin token (login fallido) no avisa de sesión vencida',
      () async {
        var avisos = 0;
        final dio = buildAuthenticatedDio(
          baseUrl: 'http://test',
          deviceId: 'dev-1',
          readToken: () => null,
          onUnauthenticated: () => avisos++,
        );
        dio.httpClientAdapter = _Adaptador(
          (options) => _json('{"code":"UNAUTHENTICATED","detail":"x"}', 401),
        );

        await dio.post<dynamic>(
          '/v1/auth/authenticate',
          data: <String, dynamic>{},
        );

        expect(avisos, 0);
      },
    );

    test(
      'un 401 con token pero otro código (ticket inválido) no avisa',
      () async {
        var avisos = 0;
        final dio = buildAuthenticatedDio(
          baseUrl: 'http://test',
          deviceId: 'dev-1',
          readToken: () => 'vigente',
          onUnauthenticated: () => avisos++,
        );
        dio.httpClientAdapter = _Adaptador(
          (options) =>
              _json('{"code":"INVALID_CREDENTIALS","detail":"x"}', 401),
        );

        await dio.post<dynamic>(
          '/v1/auth/pin/check-current',
          data: <String, dynamic>{},
        );

        expect(avisos, 0);
      },
    );

    test('un 401 avisa una sola vez y NO reintenta', () async {
      // Review Focus 5: si la sesión vence durante un envío, el usuario debe
      // acabar en el login con la operación sin ejecutar. Reintentar en
      // silencio podría cobrarle dos veces.
      var avisos = 0;
      var peticiones = 0;
      final dio = buildAuthenticatedDio(
        baseUrl: 'http://test',
        deviceId: 'dev-1',
        readToken: () => 'vencido',
        onUnauthenticated: () => avisos++,
      );
      dio.httpClientAdapter = _Adaptador((options) {
        peticiones++;
        return _json('{"code":"UNAUTHENTICATED","detail":"x"}', 401);
      });

      final r = await dio.post<dynamic>(
        '/v1/transfers',
        data: <String, dynamic>{},
      );

      expect(avisos, 1);
      expect(peticiones, 1);
      expect(r.statusCode, 401);
    });
  });
}

class _Adaptador implements HttpClientAdapter {
  _Adaptador(this.responder);
  final ResponseBody Function(RequestOptions) responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => responder(options);
}

/// El backend responde `application/json`: sin la cabecera dio no decodifica el
/// cuerpo y el interceptor no vería el `code`.
ResponseBody _json(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
