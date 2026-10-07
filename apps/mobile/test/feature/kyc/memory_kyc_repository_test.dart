import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/kyc/domain/kyc_failure.dart';
import 'package:cuycash/feature/kyc/domain/liveness_challenge.dart';
import 'package:cuycash/feature/kyc/domain/liveness_step.dart';
import 'package:cuycash/feature/kyc/infrastructure/memory_kyc_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Reloj de prueba: el TTL del desafío no es verificable si el repo mira el
/// reloj de pared.
class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration by) => now = now.add(by);
}

KycFailure failureOf(Either<GlobalFailure<KycFailure>, Object?> result) {
  final failure = result.getLeft().toNullable();
  expect(failure, isA<ServerFailure<KycFailure>>());
  return (failure! as ServerFailure<KycFailure>).failure;
}

void main() {
  late TestClock clock;
  late MemoryKycRepository repo;
  final documento = Uint8List.fromList([1, 2, 3]);

  /// Segmento de la longitud que el servicio considera suficiente.
  List<String> segment([int frames = 6]) =>
      List.generate(frames, (i) => 'frame-$i');

  setUp(() {
    clock = TestClock(DateTime(2026, 3, 1, 10));
    repo = MemoryKycRepository(clock: clock.call);
  });

  Future<LivenessChallenge> open() async =>
      (await repo.requestChallenge()).getRight().toNullable()!;

  Map<LivenessStep, List<String>> todos(LivenessChallenge challenge) =>
      {for (final step in challenge.steps) step: segment()};

  test('el desafío trae dos gestos y su vencimiento, como el servicio',
      () async {
    final challenge = await open();

    expect(challenge.steps, hasLength(2));
    expect(challenge.expiresAt, clock.now.add(repo.ttl));
    expect(challenge.isExpired(clock.now), isFalse);
  });

  test('con un segmento suficiente por gesto, aprueba', () async {
    final challenge = await open();

    final result = await repo.verifyFull(
      token: challenge.token,
      documentImage: documento,
      segments: todos(challenge),
    );

    expect(result.getRight().toNullable()!.approved, isTrue);
  });

  test('si falta el segmento de un gesto, rechaza (no es un error)', () async {
    final challenge = await open();

    final result = await repo.verifyFull(
      token: challenge.token,
      documentImage: documento,
      segments: {challenge.steps.first: segment()},
    );

    final veredicto = result.getRight().toNullable()!;
    expect(veredicto.approved, isFalse);
    expect(veredicto.isLive, isFalse);
  });

  test('un segmento demasiado corto no cuenta', () async {
    final challenge = await open();

    final result = await repo.verifyFull(
      token: challenge.token,
      documentImage: documento,
      segments: {
        for (final step in challenge.steps) step: segment(2),
      },
    );

    expect(result.getRight().toNullable()!.approved, isFalse);
  });

  test('el token vencido obliga a rehacer el desafío', () async {
    final challenge = await open();
    clock.advance(repo.ttl);

    final result = await repo.verifyFull(
      token: challenge.token,
      documentImage: documento,
      segments: todos(challenge),
    );

    expect(failureOf(result), isA<ChallengeExpired>());
  });

  test('el token es de un solo uso, aunque la primera vez se rechace',
      () async {
    final challenge = await open();
    await repo.verifyFull(
      token: challenge.token,
      documentImage: documento,
      segments: const {},
    );

    final segunda = await repo.verifyFull(
      token: challenge.token,
      documentImage: documento,
      segments: todos(challenge),
    );

    expect(failureOf(segunda), isA<ChallengeExpired>());
  });
}
