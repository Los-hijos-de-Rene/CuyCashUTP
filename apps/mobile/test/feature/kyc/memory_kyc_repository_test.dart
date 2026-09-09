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

  /// Ráfaga de la longitud que el servicio considera suficiente.
  List<String> burst([int frames = 10]) =>
      List.generate(frames, (i) => 'frame-$i');

  setUp(() {
    clock = TestClock(DateTime(2026, 3, 1, 10));
    repo = MemoryKycRepository(clock: clock.call);
  });

  Future<LivenessChallenge> open() async =>
      (await repo.requestChallenge()).getRight().toNullable()!;

  test('el desafío trae las tareas y su vencimiento', () async {
    final challenge = await open();

    expect(challenge.steps, isNotEmpty);
    expect(challenge.expiresAt, clock.now.add(repo.ttl));
    expect(challenge.isExpired(clock.now), isFalse);
  });

  test('el orden lo impone el servidor: una tarea fuera de turno se rechaza',
      () async {
    final challenge = await open();
    // Se elige a propósito una tarea que NO es la pendiente.
    final fuera = challenge.steps.last;
    expect(fuera, isNot(challenge.steps.first));

    final result = await repo.evaluateStep(
        token: challenge.token, step: fuera, framesBase64: burst());

    final failure = failureOf(result);
    expect(failure, isA<StepOutOfOrder>());
    expect((failure as StepOutOfOrder).expected, challenge.steps.first);
  });

  test('una tarea solo desbloquea la siguiente si pasa', () async {
    final challenge = await open();

    // Ráfaga corta: no pasa, y el pendiente sigue siendo el mismo.
    final corta = await repo.evaluateStep(
        token: challenge.token,
        step: challenge.steps.first,
        framesBase64: burst(2));
    expect(corta.getRight().toNullable()!.passed, isFalse);

    final segunda = await repo.evaluateStep(
        token: challenge.token,
        step: challenge.steps[1],
        framesBase64: burst());
    expect(failureOf(segunda), isA<StepOutOfOrder>());
  });

  test('un `passed:false` NO es un failure: es el usuario reintentando',
      () async {
    final challenge = await open();

    final result = await repo.evaluateStep(
        token: challenge.token,
        step: challenge.steps.first,
        framesBase64: burst(2));

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()!.passed, isFalse);
  });

  test('el token vence a los 180 s', () async {
    final challenge = await open();

    clock.advance(const Duration(seconds: 181));
    final result = await repo.evaluateStep(
        token: challenge.token,
        step: challenge.steps.first,
        framesBase64: burst());

    expect(failureOf(result), isA<ChallengeExpired>());
  });

  test('completadas todas las tareas, evaluar otra vez responde completado',
      () async {
    final challenge = await open();
    for (final step in challenge.steps) {
      await repo.evaluateStep(
          token: challenge.token, step: step, framesBase64: burst());
    }

    final result = await repo.evaluateStep(
        token: challenge.token,
        step: challenge.steps.first,
        framesBase64: burst());

    expect(failureOf(result), isA<ChallengeCompleted>());
  });

  test('verify-full aprueba solo con el desafío completo y consume el token',
      () async {
    final challenge = await open();
    final segments = <LivenessStep, List<String>>{};
    for (final step in challenge.steps) {
      await repo.evaluateStep(
          token: challenge.token, step: step, framesBase64: burst());
      segments[step] = burst();
    }

    final result = await repo.verifyFull(
      token: challenge.token,
      documentImage: Uint8List.fromList([1, 2, 3]),
      segments: segments,
    );

    final veredicto = result.getRight().toNullable()!;
    expect(veredicto.approved, isTrue);
    expect(veredicto.isLive, isTrue);
    expect(veredicto.faceMatch, isTrue);

    // Consumido: no se puede reutilizar.
    final again = await repo.verifyFull(
      token: challenge.token,
      documentImage: Uint8List.fromList([1, 2, 3]),
      segments: segments,
    );
    expect(failureOf(again), isA<ChallengeExpired>());
  });

  test('verify-full sin todas las tareas validadas no aprueba', () async {
    final challenge = await open();
    await repo.evaluateStep(
        token: challenge.token,
        step: challenge.steps.first,
        framesBase64: burst());

    final result = await repo.verifyFull(
      token: challenge.token,
      documentImage: Uint8List.fromList([1, 2, 3]),
      segments: {challenge.steps.first: burst()},
    );

    expect(result.getRight().toNullable()!.approved, isFalse);
  });
}
