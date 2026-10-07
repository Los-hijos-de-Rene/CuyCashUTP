import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/infrastructure/http_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_repository_contract.dart';

/// Reproduce `services/api/app/api/v1/routers/profile.py` (`/v1/me*`).
class FakeProfileBackend implements HttpClientAdapter {
  String alias = '@jenny';

  /// Alias de otros titulares: el alias es único.
  static const tomados = {'@luis'};
  ({int status, Object? body})? forced;
  DioException? throwIt;

  static final _alias = RegExp(r'^@(?=[a-z0-9_.]*[a-z])[a-z0-9_.]{3,20}$');

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
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  (int, Object?) _route(RequestOptions o) {
    if (o.uri.path == '/v1/me' && o.method == 'GET') {
      return (200, {
        'dni': '71234567',
        'nombres': 'Jenny Marisol',
        'apellidos': 'Ruiz',
        'email_masked': 'j•••••@correo.pe',
        'alias': alias,
        'kyc_status': 'pending',
        'created_at': '2026-09-01T15:00:00.000000Z',
      });
    }
    if (o.uri.path == '/v1/me/alias' && o.method == 'PATCH') {
      final crudo = ((o.data as Map)['alias'] as String).trim().toLowerCase();
      final nuevo = crudo.startsWith('@') ? crudo : '@$crudo';
      if (!_alias.hasMatch(nuevo)) {
        return (422, {'code': 'INVALID_ALIAS', 'detail': 'x'});
      }
      if (nuevo != alias && tomados.contains(nuevo)) {
        return (409, {'code': 'ALIAS_TAKEN', 'detail': 'x'});
      }
      alias = nuevo;
      return (200, {'alias': nuevo});
    }
    return (404, {'code': 'NOPE', 'detail': 'x'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  HttpProfileRepository construir([FakeProfileBackend? backend]) {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://x',
      validateStatus: (s) => s != null && s < 500,
    ))..httpClientAdapter = backend ?? FakeProfileBackend();
    return HttpProfileRepository(dio: dio);
  }

  probarContratoDePerfil(
    'HttpProfileRepository',
    construir,
    dni: '71234567',
    aliasInicial: '@jenny',
    aliasDeOtro: '@luis',
  );

  ProfileFailure? falloDe(Result<ProfileFailure, Object?> r) =>
      switch (r.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      };

  test('401 es unauthenticated', () async {
    final backend = FakeProfileBackend()
      ..forced = (status: 401, body: {'code': 'UNAUTHENTICATED', 'detail': 'x'});
    expect(falloDe(await construir(backend).me()), isA<ProfileUnauthenticated>());
  });

  test('sin red es network', () async {
    final backend = FakeProfileBackend()
      ..throwIt = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    expect(falloDe(await construir(backend).me()), isA<ProfileNetworkFailure>());
  });

  test('kyc_status verified es kycVerified=true', () async {
    final backend = FakeProfileBackend();
    final repo = construir(backend);
    backend.forced = (status: 200, body: {
      'dni': '71234567',
      'nombres': 'J',
      'apellidos': 'R',
      'email_masked': 'j•••••@c.pe',
      'alias': '@j',
      'kyc_status': 'verified',
      'created_at': '2026-09-01T15:00:00.000000Z',
    });
    final datos = (await repo.me()).getRight().toNullable();
    expect(datos?.kycVerified, isTrue);
  });

  test('kyc_status distinto de verified es kycVerified=false', () async {
    final backend = FakeProfileBackend();
    final repo = construir(backend);
    backend.forced = (status: 200, body: {
      'dni': '71234567',
      'nombres': 'J',
      'apellidos': 'R',
      'email_masked': 'j•••••@c.pe',
      'alias': '@j',
      'kyc_status': 'pending',
      'created_at': '2026-09-01T15:00:00.000000Z',
    });
    final datos = (await repo.me()).getRight().toNullable();
    expect(datos?.kycVerified, isFalse);
  });
}
