import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';

import '../domain/document_check.dart';
import '../domain/kyc_failure.dart';
import '../domain/kyc_repository.dart';
import '../domain/liveness_challenge.dart';
import '../domain/liveness_step.dart';

/// Operaciones finas del KYC (delegación directa sobre el `KycRepository`). Los
/// blocs la consumen por constructor; nunca tocan el repo directo.
class KycActions {
  const KycActions(this._repo);

  final KycRepository _repo;

  FutureResult<KycFailure, DocumentCheck> checkDocumentFront(
    Uint8List image, {
    required String expectedDni,
  }) =>
      _repo.checkDocumentFront(image, expectedDni: expectedDni);

  FutureResult<KycFailure, DocumentCheck> checkDocumentBack(
    Uint8List image, {
    required String expectedDni,
  }) =>
      _repo.checkDocumentBack(image, expectedDni: expectedDni);

  FutureResult<KycFailure, LivenessChallenge> requestChallenge() =>
      _repo.requestChallenge();

  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    Uint8List? documentBackImage,
    String? expectedDni,
    required Map<LivenessStep, List<String>> segments,
  }) =>
      _repo.verifyFull(
        token: token,
        documentImage: documentImage,
        documentBackImage: documentBackImage,
        expectedDni: expectedDni,
        segments: segments,
      );
}
