import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/document_check.dart';
import '../domain/kyc_failure.dart';
import '../domain/kyc_repository.dart';
import '../domain/liveness_challenge.dart';
import '../domain/liveness_step.dart';

/// Memory* FUNCIONAL del KYC (backend del flavor `mock` + contrato de tests).
///
/// Reproduce las reglas que importan del servicio real: el servidor elige las
/// tareas, el token vence y es de un solo uso, y la verificación exige un
/// segmento con frames suficientes por CADA tarea. Sin eso, la app de mock
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
    this.documentDni,
  })  : _now = clock,
        // Como el servicio: dos gestos del pool de giros laterales y parpadeo.
        _steps = steps ?? const [LivenessStep.izquierda, LivenessStep.parpadeo];

  final DateTime Function() _now;
  final List<LivenessStep> _steps;
  final Duration ttl;

  /// El servicio real descarta segmentos con muy pocos frames.
  final int minFramesPerStep;

  /// DNI "impreso" en el reverso simulado. Null = el que declare el usuario,
  /// para que el flavor `mock` se recorra sin tropiezos; las pruebas lo fijan
  /// para simular un DNI ajeno.
  final String? documentDni;

  final Map<String, LivenessChallenge> _challenges = {};
  var _seq = 0;

  @override
  FutureResult<KycFailure, DocumentCheck> checkDocumentFront(
    Uint8List image, {
    required String expectedDni,
  }) async {
    if (image.isEmpty) {
      return right(const DocumentCheck(issues: [DocumentIssue.blurry]));
    }
    // El simulado lleva impreso el mismo DNI que su reverso ([documentDni]).
    final impreso = documentDni ?? expectedDni;
    return right(impreso == expectedDni
        ? const DocumentCheck.ok()
        : const DocumentCheck(issues: [DocumentIssue.frontDniMismatch]));
  }

  @override
  FutureResult<KycFailure, DocumentCheck> checkDocumentBack(
    Uint8List image, {
    required String expectedDni,
  }) async {
    if (image.isEmpty) {
      return right(
          const DocumentCheck(issues: [DocumentIssue.backUnreadable]));
    }
    final leido = documentDni ?? expectedDni;
    return right(leido == expectedDni
        ? DocumentCheck.ok(dniRead: leido)
        : DocumentCheck(
            issues: const [DocumentIssue.dniMismatch], dniRead: leido));
  }

  @override
  FutureResult<KycFailure, LivenessChallenge> requestChallenge() async {
    final challenge = LivenessChallenge(
      token: 'kyc-${_seq++}',
      steps: List.unmodifiable(_steps),
      expiresAt: _now().add(ttl),
    );
    _challenges[challenge.token] = challenge;
    return right(challenge);
  }

  @override
  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    Uint8List? documentBackImage,
    String? expectedDni,
    required Map<LivenessStep, List<String>> segments,
  }) async {
    // Un solo uso: se consume aunque la verificación no apruebe.
    final challenge = _challenges.remove(token);
    if (challenge == null || challenge.isExpired(_now())) {
      return left(const GlobalFailure.server(KycFailure.challengeExpired()));
    }

    final completos = challenge.steps.every(
      (step) => (segments[step]?.length ?? 0) >= minFramesPerStep,
    );
    // Como el servicio: con reverso y DNI declarado, deben coincidir.
    final dniMatches = documentBackImage == null || expectedDni == null
        ? null
        : (documentDni ?? expectedDni) == expectedDni;
    final approved =
        completos && documentImage.isNotEmpty && dniMatches != false;
    return right(KycVerification(
      approved: approved,
      reason: approved
          ? 'Verificación de identidad exitosa'
          : dniMatches == false
              ? 'Falló: el DNI no coincide con el documento'
              : 'Falló: liveness no superado',
      documentValid: documentImage.isNotEmpty,
      isLive: completos,
      faceMatch: completos,
      dniMatches: dniMatches,
      ticket: approved ? 'memory-kyc-ticket-$token' : null,
    ));
  }
}
