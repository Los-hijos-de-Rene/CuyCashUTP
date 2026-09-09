import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/otp/domain/otp_failure.dart';
import 'package:cuycash/feature/otp/infrastructure/http_otp_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../auth/http_auth_repository_test.dart' show FakeAdapter;

OtpFailure failureOf(Either<GlobalFailure<OtpFailure>, Object?> result) {
  final failure = result.getLeft().toNullable();
  expect(failure, isA<ServerFailure<OtpFailure>>());
  return (failure! as ServerFailure<OtpFailure>).failure;
}

void main() {
  late FakeAdapter adapter;
  late HttpOtpRepository repo;

  setUp(() {
    adapter = FakeAdapter();
    final dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8001',
      validateStatus: (status) => status != null && status < 500,
    ))..httpClientAdapter = adapter;
    repo = HttpOtpRepository(dio: dio);
  });

  test('el propósito lo decide el identificador', () async {
    adapter.body = {
      'challenge_id': 'c1',
      'masked_email': 'j•••••@correo.com',
      'expires_at': '2026-09-09T21:10:00Z',
      'cooldown_until': '2026-09-09T21:01:00Z',
      'attempts_left': 3,
      'resends_left': 3,
    };

    await repo.request('juan@correo.com');
    expect(adapter.lastRequest?.data['purpose'], 'recovery');

    await repo.request('12345678');
    expect(adapter.lastRequest?.data['purpose'], 'device');
  });

  test('verificar bien entrega el ticket, no un booleano', () async {
    adapter.body = {'otp_ticket': 'tk-123', 'purpose': 'recovery'};

    final resultado = await repo.verify(challengeId: 'c1', code: '123456');

    // Que sea un valor es lo que impide saltarse el paso: sin ticket, el
    // backend no deja cambiar el PIN ni abrir sesión.
    expect(resultado.getRight().toNullable(), 'tk-123');
  });

  test('un código equivocado informa los intentos y NO cancela', () async {
    adapter.statusCode = 400;
    adapter.body = {'code': 'INVALID_CREDENTIALS', 'attempts_left': 2};

    final failure = failureOf(await repo.verify(challengeId: 'c1', code: '000000'));

    expect(failure, isA<InvalidCode>());
    expect((failure as InvalidCode).attemptsLeft, 2);
  });

  test('la cancelación conserva el motivo, que la UI necesita', () async {
    adapter.statusCode = 400;
    for (final caso in [
      ('attempts', OtpCancelReason.attempts),
      ('resends', OtpCancelReason.resends),
    ]) {
      adapter.body = {'code': 'CHALLENGE_CANCELLED', 'reason': caso.$1};

      final failure =
          failureOf(await repo.verify(challengeId: 'c1', code: '000000'));

      expect((failure as ChallengeCancelled).reason, caso.$2);
    }
  });

  test('el código vencido se distingue del incorrecto', () async {
    adapter.statusCode = 400;
    adapter.body = {'code': 'CHALLENGE_EXPIRED'};

    // Vencer no consume intentos: la salida es pedir otro código, no reintentar.
    expect(
      failureOf(await repo.verify(challengeId: 'c1', code: '123456')),
      isA<CodeExpired>(),
    );
  });

  test('el backend caído se distingue de un rechazo', () async {
    adapter.throwIt = DioException.connectionTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: RequestOptions(path: '/'),
    );

    expect(
      failureOf(await repo.request('juan@correo.com')),
      isA<OtpServiceUnavailable>(),
    );
  });
}
