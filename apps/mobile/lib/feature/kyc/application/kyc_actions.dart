import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';

import '../domain/kyc_failure.dart';
import '../domain/kyc_repository.dart';
import '../domain/liveness_challenge.dart';
import '../domain/liveness_step.dart';

/// Operaciones finas del KYC (delegación directa sobre el `KycRepository`). El
/// bloc la consume por constructor; nunca toca el repo directo.
class KycActions {
  const KycActions(this._repo);

  final KycRepository _repo;

  FutureResult<KycFailure, LivenessChallenge> requestChallenge() =>
      _repo.requestChallenge();

  FutureResult<KycFailure, StepEvaluation> evaluateStep({
    required String token,
    required LivenessStep step,
    required List<String> framesBase64,
  }) =>
      _repo.evaluateStep(
          token: token, step: step, framesBase64: framesBase64);

  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    required Map<LivenessStep, List<String>> segments,
  }) =>
      _repo.verifyFull(
          token: token, documentImage: documentImage, segments: segments);
}
