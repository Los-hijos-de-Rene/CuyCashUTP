import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/kyc_failure.dart';
import '../domain/kyc_repository.dart';
import '../domain/liveness_challenge.dart';
import '../domain/liveness_step.dart';

/// Memory* FUNCIONAL del KYC (backend del flavor `mock` + contrato de tests).
///
/// Reproduce las reglas que importan del servicio real: el ORDEN lo impone
/// este lado, una tarea solo desbloquea la siguiente si pasa, el token vence, y
/// un desafío completado no admite más evaluaciones. Sin eso, la app de mock
/// permitiría recorridos que el servidor real rechaza.
///
/// El reloj entra por constructor, como en el OTP: el TTL no es testeable si el
/// repo mira el reloj de pared.
class MemoryKycRepository implements KycRepository {
  MemoryKycRepository({
    required DateTime Function() clock,
    List<LivenessStep>? steps,
    this.ttl = const Duration(seconds: 180),
    this.minFramesPerStep = 5,
  })  : _now = clock,
        _steps = steps ?? LivenessStep.values;

  final DateTime Function() _now;
  final List<LivenessStep> _steps;
  final Duration ttl;

  /// El servicio real descarta segmentos con muy pocos frames.
  final int minFramesPerStep;

  final Map<String, _Challenge> _challenges = {};
  var _seq = 0;

  @override
  FutureResult<KycFailure, LivenessChallenge> requestChallenge() async {
    final challenge = _Challenge(
      token: 'kyc-${_seq++}',
      steps: List.unmodifiable(_steps),
      expiresAt: _now().add(ttl),
    );
    _challenges[challenge.token] = challenge;
    return right(LivenessChallenge(
      token: challenge.token,
      steps: challenge.steps,
      expiresAt: challenge.expiresAt,
    ));
  }

  @override
  FutureResult<KycFailure, StepEvaluation> evaluateStep({
    required String token,
    required LivenessStep step,
    required List<String> framesBase64,
  }) async {
    final challenge = _challenges[token];
    if (challenge == null || challenge.isExpired(_now())) {
      return left(const GlobalFailure.server(KycFailure.challengeExpired()));
    }
    if (challenge.isComplete) {
      return left(const GlobalFailure.server(KycFailure.challengeCompleted()));
    }
    final expected = challenge.pending;
    if (step != expected) {
      return left(GlobalFailure.server(KycFailure.stepOutOfOrder(expected)));
    }

    // Ráfaga demasiado corta: el servicio la rechaza, y no avanzar es correcto.
    if (framesBase64.length < minFramesPerStep) {
      return right(StepEvaluation(
        step: step,
        passed: false,
        reason: 'Frames insuficientes',
        framesAnalyzed: framesBase64.length,
      ));
    }

    challenge.segments[step] = List.unmodifiable(framesBase64);
    challenge.doneIndex += 1;
    return right(StepEvaluation(
      step: step,
      passed: true,
      reason: 'Movimiento detectado',
      framesAnalyzed: framesBase64.length,
    ));
  }

  @override
  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    required Map<LivenessStep, List<String>> segments,
  }) async {
    final challenge = _challenges[token];
    if (challenge == null || challenge.isExpired(_now())) {
      return left(const GlobalFailure.server(KycFailure.challengeExpired()));
    }

    // Se aprueba solo si TODAS las tareas del desafío fueron validadas antes.
    final faltantes =
        challenge.steps.where((step) => !segments.containsKey(step)).isNotEmpty;
    final approved = challenge.isComplete && !faltantes;
    _challenges.remove(token); // el desafío se consume
    return right(KycVerification(
      approved: approved,
      reason: approved
          ? 'Verificación de identidad exitosa'
          : 'Faltan tareas del desafío por validar',
      documentValid: documentImage.isNotEmpty,
      isLive: approved,
      faceMatch: approved,
    ));
  }
}

class _Challenge {
  _Challenge({
    required this.token,
    required this.steps,
    required this.expiresAt,
  });

  final String token;
  final List<LivenessStep> steps;
  final DateTime expiresAt;
  final Map<LivenessStep, List<String>> segments = {};
  int doneIndex = 0;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
  bool get isComplete => doneIndex >= steps.length;
  LivenessStep get pending => steps[doneIndex];
}
