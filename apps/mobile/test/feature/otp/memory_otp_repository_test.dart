import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/otp/domain/otp_challenge.dart';
import 'package:cuycash/feature/otp/domain/otp_failure.dart';
import 'package:cuycash/feature/otp/domain/otp_policy.dart';
import 'package:cuycash/feature/otp/infrastructure/memory_otp_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Reloj de prueba: los tres relojes de `OtpPolicy` solo son verificables si se
/// puede adelantar el tiempo sin esperarlo.
class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration by) => now = now.add(by);
}

/// Extrae el `OtpFailure` de un resultado que se espera fallido.
OtpFailure failureOf(Either<GlobalFailure<OtpFailure>, Object?> result) {
  final failure = result.getLeft().toNullable();
  expect(failure, isA<ServerFailure<OtpFailure>>(),
      reason: 'se esperaba un fallo de negocio');
  return (failure! as ServerFailure<OtpFailure>).failure;
}

void main() {
  const email = 'juan.perez@gmail.com';
  late TestClock clock;
  late MemoryOtpRepository repo;

  setUp(() {
    clock = TestClock(DateTime(2026, 3, 1, 10));
    repo = MemoryOtpRepository(clock: clock.call);
  });

  Future<OtpChallenge> open() async {
    final result = await repo.request(email);
    return result.getRight().toNullable()!;
  }

  test('request enmascara el correo y arma los dos relojes', () async {
    final challenge = await open();
    expect(challenge.maskedEmail, 'j•••••@gmail.com');
    expect(challenge.expiresAt, clock.now.add(OtpPolicy.ttl));
    expect(challenge.cooldownUntil, clock.now.add(OtpPolicy.cooldown));
  });

  test('CP-01 · código correcto → ok y el reto se consume', () async {
    final challenge = await open();

    final ok = await repo.verify(
        challengeId: challenge.id, code: OtpPolicy.validCode);
    expect(ok.isRight(), isTrue);

    // Consumido: no se puede reutilizar.
    final again = await repo.verify(
        challengeId: challenge.id, code: OtpPolicy.validCode);
    expect(failureOf(again), isA<ChallengeNotFound>());
  });

  test('CP-02 · código incorrecto → quedan 2 intentos', () async {
    final challenge = await open();

    final result = await repo.verify(challengeId: challenge.id, code: '000000');

    expect(failureOf(result), isA<InvalidCode>());
    expect((failureOf(result) as InvalidCode).attemptsLeft, 2);
  });

  test('CP-03 · tercer código incorrecto → cancelado por intentos', () async {
    final challenge = await open();

    await repo.verify(challengeId: challenge.id, code: '000000');
    await repo.verify(challengeId: challenge.id, code: '000001');
    final third =
        await repo.verify(challengeId: challenge.id, code: '000002');

    final failure = failureOf(third);
    expect(failure, isA<ChallengeCancelled>());
    expect((failure as ChallengeCancelled).reason, OtpCancelReason.attempts);

    // Invalidado: ni siquiera el código bueno entra.
    final withValid = await repo.verify(
        challengeId: challenge.id, code: OtpPolicy.validCode);
    expect(failureOf(withValid), isA<ChallengeCancelled>());
  });

  test('CP-04 · a los 601 s el código venció', () async {
    final challenge = await open();

    clock.advance(const Duration(seconds: 601));
    final result = await repo.verify(
        challengeId: challenge.id, code: OtpPolicy.validCode);

    expect(failureOf(result), isA<CodeExpired>());
  });

  test('el vencimiento NO consume intentos', () async {
    final challenge = await open();
    clock.advance(const Duration(seconds: 601));

    await repo.verify(challengeId: challenge.id, code: '000000');
    final resent = await repo.resend(challenge.id);

    expect(resent.getRight().toNullable()!.attemptsLeft, OtpPolicy.maxAttempts);
  });

  test('CP-05 · a los 59 s el reenvío sigue en enfriamiento', () async {
    final challenge = await open();

    clock.advance(const Duration(seconds: 59));

    expect(challenge.isCooling(clock.now), isTrue);
    // El enfriamiento corriendo no vence el código: son relojes distintos.
    expect(challenge.isExpired(clock.now), isFalse);
  });

  test('CP-06 · a los 60 s el reenvío está disponible', () async {
    final challenge = await open();

    clock.advance(const Duration(seconds: 60));

    expect(challenge.isCooling(clock.now), isFalse);
    expect(challenge.isExpired(clock.now), isFalse);
  });

  test('CP-07 · reenviar reinicia vencimiento y enfriamiento', () async {
    final challenge = await open();
    clock.advance(const Duration(seconds: 90));

    final resent = (await repo.resend(challenge.id)).getRight().toNullable()!;

    expect(resent.expiresAt, clock.now.add(OtpPolicy.ttl));
    expect(resent.cooldownUntil, clock.now.add(OtpPolicy.cooldown));
    expect(resent.expiresAt, isNot(challenge.expiresAt));
    expect(resent.resendsLeft, OtpPolicy.maxResends - 1);
  });

  test('CP-08 · el cuarto reenvío cancela el reto', () async {
    final challenge = await open();

    for (var i = 0; i < OtpPolicy.maxResends; i++) {
      expect((await repo.resend(challenge.id)).isRight(), isTrue);
    }
    final fourth = await repo.resend(challenge.id);

    final failure = failureOf(fourth);
    expect(failure, isA<ChallengeCancelled>());
    expect((failure as ChallengeCancelled).reason, OtpCancelReason.resends);
  });

  test('CP-09 · tras cancelar, verify y resend responden cancelado', () async {
    final challenge = await open();
    await repo.verify(challengeId: challenge.id, code: '000000');
    await repo.verify(challengeId: challenge.id, code: '000001');
    await repo.verify(challengeId: challenge.id, code: '000002');

    final verify = await repo.verify(
        challengeId: challenge.id, code: OtpPolicy.validCode);
    final resend = await repo.resend(challenge.id);

    expect(failureOf(verify), isA<ChallengeCancelled>());
    expect(failureOf(resend), isA<ChallengeCancelled>());
  });

  test('CP-10 · tras cancelar, el identificador queda bloqueado 900 s',
      () async {
    final challenge = await open();
    final cancelledAt = clock.now;
    await repo.verify(challengeId: challenge.id, code: '000000');
    await repo.verify(challengeId: challenge.id, code: '000001');
    await repo.verify(challengeId: challenge.id, code: '000002');

    final blocked = await repo.request(email);
    final failure = failureOf(blocked);
    expect(failure, isA<IdentifierLocked>());
    expect((failure as IdentifierLocked).until,
        cancelledAt.add(OtpPolicy.lockout));

    // A los 899 s sigue bloqueado; a los 901 s ya se puede reintentar.
    clock.advance(const Duration(seconds: 899));
    expect(failureOf(await repo.request(email)), isA<IdentifierLocked>());
    clock.advance(const Duration(seconds: 2));
    expect((await repo.request(email)).isRight(), isTrue);
  });

  test('cancelar deja constancia del aviso al correo', () async {
    final challenge = await open();
    await repo.verify(challengeId: challenge.id, code: '000000');
    await repo.verify(challengeId: challenge.id, code: '000001');
    await repo.verify(challengeId: challenge.id, code: '000002');

    expect(repo.notifications, hasLength(1));
    expect(repo.notifications.single, contains('j•••••@gmail.com'));
  });
}
