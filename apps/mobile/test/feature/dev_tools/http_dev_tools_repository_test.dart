import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/dev_tools/domain/dev_tools_repository.dart';
import 'package:cuycash/feature/dev_tools/infrastructure/http_dev_tools_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Map<String, dynamic> body = const {};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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

DevToolsFailure failureOf(Object? result) {
  final either = result! as dynamic;
  final failure = either.getLeft().toNullable() as GlobalFailure<DevToolsFailure>;
  return (failure as ServerFailure<DevToolsFailure>).failure;
}

void main() {
  late _FakeAdapter adapter;
  late HttpDevToolsRepository repo;

  setUp(() {
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(
      baseUrl: 'http://192.168.1.57:8001',
      validateStatus: (status) => status != null && status < 500,
    ))..httpClientAdapter = adapter;
    repo = HttpDevToolsRepository(dio: dio, devKey: 'clave-dev');
  });

  test('reiniciar llama a /v1/dev/reset-y-seed con la clave', () async {
    adapter.body = {
      'pin': '258036',
      'usuarios': [
        {'dni': '11111111', 'nombre': 'Ana Prueba', 'alias': '@ana'},
      ],
    };

    final seed = (await repo.resetAndSeed()).getRight().toNullable()!;

    expect(adapter.lastRequest?.path, '/v1/dev/reset-y-seed');
    expect(adapter.lastRequest?.headers['X-Dev-Key'], 'clave-dev');
    expect(seed.pin, '258036');
    expect(seed.users.single.alias, '@ana');
  });

  test('sembrar no borra: usa /v1/dev/seed', () async {
    adapter.body = {'pin': '258036', 'usuarios': []};

    await repo.seed();

    expect(adapter.lastRequest?.path, '/v1/dev/seed');
  });

  test('los últimos OTP se leen de /v1/dev/otp', () async {
    adapter.body = {
      'codigos': [
        {'destino': 'ana@prueba.local', 'codigo': '482167', 'proposito': 'device'},
      ],
    };

    final otps = (await repo.latestOtps()).getRight().toNullable()!;

    expect(adapter.lastRequest?.method, 'GET');
    expect(otps.single.code, '482167');
  });

  test('403 es clave equivocada; 404 es que el backend no las tiene', () async {
    adapter.statusCode = 403;
    expect(failureOf(await repo.seed()), isA<DevToolsWrongKey>());

    adapter.statusCode = 404;
    expect(failureOf(await repo.seed()), isA<DevToolsUnavailable>());
  });
}
