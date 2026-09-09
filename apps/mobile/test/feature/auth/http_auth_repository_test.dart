import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/infrastructure/http_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Adaptador con respuestas preparadas: prueba el mapeo del contrato sin
/// levantar el backend.
class FakeAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Map<String, dynamic> body = const {};
  DioException? throwIt;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (throwIt case final error?) throw error;
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

AuthFailure failureOf(Either<GlobalFailure<AuthFailure>, Object?> result) {
  final failure = result.getLeft().toNullable();
  expect(failure, isA<ServerFailure<AuthFailure>>());
  return (failure! as ServerFailure<AuthFailure>).failure;
}

void main() {
  late FakeAdapter adapter;
  late HttpAuthRepository repo;

  setUp(() {
    adapter = FakeAdapter();
    final dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8001',
      headers: {'X-Device-Id': 'telefono-1'},
      validateStatus: (status) => status != null && status < 500,
    ))..httpClientAdapter = adapter;
    repo = HttpAuthRepository(dio: dio, deviceId: 'telefono-1');
  });

  Future<Either<GlobalFailure<AuthFailure>, Object?>> autenticar() =>
      repo.authenticate(identifier: '12345678', pin: '024689');

  test('el identificador del teléfono viaja en cada llamada', () async {
    adapter.body = {'result': 'device_verification_required'};

    await autenticar();

    // El backend lo exige para reconocer dispositivos de confianza y para su
    // propio contador de intentos.
    expect(adapter.lastRequest?.headers['X-Device-Id'], 'telefono-1');
  });

  test('un teléfono de confianza recibe la sesión hecha', () async {
    adapter.body = {
      'result': 'session',
      'session_token': 'tok',
      'user': {'id': 'u1', 'alias': '@juan'},
    };

    final session = (await autenticar()).getRight().toNullable();

    expect((session! as dynamic).alias, '@juan');
  });

  test('un teléfono desconocido NO abre sesión con signIn', () async {
    adapter.body = {
      'result': 'device_verification_required',
      'pending_token': 'pend',
    };

    final resultado = await repo.signIn(identifier: '12345678', pin: '024689');

    // El PIN correcto no basta: falta el OTP de dispositivo.
    expect(resultado.isLeft(), isTrue);
    expect(repo.currentSession, isNull);
  });

  test('los intentos restantes los informa el SERVIDOR', () async {
    adapter.statusCode = 401;
    adapter.body = {'code': 'INVALID_CREDENTIALS', 'attempts_left': 2};

    final failure = failureOf(await autenticar());

    // Contarlos en el teléfono permitiría ponerlos a cero reinstalando la app.
    expect(failure, isA<TooManyAttempts>());
    expect((failure as TooManyAttempts).attemptsLeft, 2);
  });

  test('el bloqueo llega con su vencimiento, por DNI o por dispositivo',
      () async {
    adapter.statusCode = 423;
    for (final code in ['IDENTIFIER_LOCKED', 'DEVICE_LOCKED']) {
      adapter.body = {
        'code': code,
        'locked_until': '2026-09-09T21:18:00Z',
      };

      final failure = failureOf(await autenticar());

      expect(failure, isA<AccessLocked>(), reason: code);
      expect((failure as AccessLocked).until.isUtc, isTrue);
    }
  });

  test('el mapeo va por `code` y NO por el texto del detalle', () async {
    adapter.statusCode = 400;
    adapter.body = {
      'code': 'PIN_UNCHANGED',
      // Un cambio de redacción no debe romper la app: es la lección del
      // servicio de KYC (R2 del ADR-0001).
      'detail': 'cualquier texto que a alguien se le ocurra mañana',
    };

    final failure = failureOf(
      await repo.resetPin(
          identifier: 'j@p.pe', newPin: '314159', otpTicket: 't'),
    );

    expect(failure, isA<PinUnchanged>());
  });

  test('el backend caído se distingue de un rechazo del usuario', () async {
    adapter.throwIt = DioException.connectionTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: RequestOptions(path: '/'),
    );

    expect(failureOf(await autenticar()), isA<AuthUnavailable>());
  });

  test('restablecer el PIN deja el teléfono sin sesión', () async {
    adapter.body = {
      'result': 'session',
      'session_token': 'tok',
      'user': {'id': 'u1'},
    };
    await repo.signIn(identifier: '12345678', pin: '024689');
    expect(repo.currentSession, isNotNull);

    adapter.body = {'revoked_sessions': 1};
    await repo.resetPin(
        identifier: 'j@p.pe', newPin: '314159', otpTicket: 't');

    // El servidor revocó todas las sesiones, incluida la de este teléfono:
    // restablecer no otorga acceso.
    expect(repo.currentSession, isNull);
  });
}
