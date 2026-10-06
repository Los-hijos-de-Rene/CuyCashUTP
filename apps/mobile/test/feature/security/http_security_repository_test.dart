import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/infrastructure/http_security_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'security_repository_contract.dart';

/// Reproduce `auth.py` (`pin/change`, `biometric/*`) y `profile.py`
/// (`/v1/devices*`): cuerpos de error PLANOS `{code, detail, <extras>}`.
class FakeSecurityBackend implements HttpClientAdapter {
  String pin = '839201';
  int intentos = LockoutPolicy.maxAttempts;
  bool conHuella = false;
  final dispositivos = <Map<String, Object?>>[
    _disp('d-este', esEste: true),
    _disp('d-otro', esEste: false),
  ];
  ({int status, Object? body})? forced;
  DioException? throwIt;

  static Map<String, Object?> _disp(String id, {required bool esEste}) => {
        'id': id,
        'nombre': esEste ? 'Pixel 8' : null,
        'plataforma': esEste ? 'android' : null,
        'vinculado_el': '2026-09-01T15:00:00.000000Z',
        'ultimo_uso': '2026-10-06T12:00:00.000000Z',
        'es_este': esEste,
        'con_huella': false,
      };

  static (int, Object?) _err(int s, String code,
          [Map<String, Object?> x = const {}]) =>
      (s, {'code': code, 'detail': 'x', ...x});

  (int, Object?)? _verificar(String propuesto) {
    if (intentos <= 0) {
      return _err(423, 'IDENTIFIER_LOCKED',
          {'locked_until': '2026-10-06T12:15:00+00:00'});
    }
    if (propuesto == pin) return null;
    intentos--;
    if (intentos == 0) {
      return _err(423, 'IDENTIFIER_LOCKED',
          {'locked_until': '2026-10-06T12:15:00+00:00'});
    }
    return _err(401, 'INVALID_CREDENTIALS', {'attempts_left': intentos});
  }

  (int, Object?) _route(RequestOptions o) {
    final path = o.uri.path;
    final data = o.data is Map ? o.data as Map : const {};
    if (path == '/v1/auth/pin/change') {
      if (_verificar(data['current_pin'] as String) case final e?) return e;
      final nuevo = data['new_pin'] as String;
      if ({'123456', '111111', '654321'}.contains(nuevo)) {
        return _err(422, 'WEAK_PIN');
      }
      if (nuevo == pin) return _err(422, 'PIN_UNCHANGED');
      pin = nuevo;
      return (200, {'revoked_sessions': 1});
    }
    if (path == '/v1/devices' && o.method == 'GET') {
      return (200, {
        'dispositivos': [
          for (final d in dispositivos)
            {...d, 'con_huella': d['es_este'] == true && conHuella},
        ],
      });
    }
    if (path.startsWith('/v1/devices/') && o.method == 'DELETE') {
      final id = path.split('/').last;
      final i = dispositivos.indexWhere((d) => d['id'] == id);
      if (i < 0) return _err(404, 'DEVICE_NOT_FOUND');
      if (dispositivos[i]['es_este'] == true) {
        return _err(409, 'CANNOT_UNLINK_CURRENT');
      }
      dispositivos.removeAt(i);
      return (204, null);
    }
    if (path == '/v1/auth/biometric/enroll') {
      if (_verificar(data['pin'] as String) case final e?) return e;
      conHuella = true;
      return (200, {'credential': 'secreto-${DateTime.now().microsecond}'});
    }
    if (path == '/v1/auth/biometric/current' && o.method == 'DELETE') {
      conHuella = false;
      return (204, null);
    }
    return _err(404, 'NOPE');
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwIt case final e?) throw e;
    final (status, body) = switch (forced) {
      final f? => (f.status, f.body),
      _ => _route(o),
    };
    return ResponseBody.fromString(body == null ? '' : jsonEncode(body), status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  }

  @override
  void close({bool force = false}) {}
}

HttpSecurityRepository construir([FakeSecurityBackend? backend]) =>
    HttpSecurityRepository(
      dio: Dio(BaseOptions(
        baseUrl: 'http://x',
        validateStatus: (s) => s != null && s < 500,
      ))
        ..httpClientAdapter = backend ?? FakeSecurityBackend(),
    );

void main() {
  probarContratoDeSeguridad(
    'HttpSecurityRepository',
    construir,
    pin: '839201',
    otroId: 'd-otro',
    maxIntentos: LockoutPolicy.maxAttempts,
  );

  test('sin red al cambiar el PIN es network (resultado desconocido)',
      () async {
    final backend = FakeSecurityBackend()
      ..throwIt = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.receiveTimeout,
      );
    final r = await construir(backend)
        .changePin(current: '839201', nuevo: '502718');
    expect(
      switch (r.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      },
      isA<SecurityNetworkFailure>(),
    );
  });
}
