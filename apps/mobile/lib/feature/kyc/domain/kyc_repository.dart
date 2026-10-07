import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';

import 'kyc_failure.dart';
import 'liveness_challenge.dart';
import 'liveness_step.dart';

/// Contrato del servicio de KYC facial (domain). Nunca lanza: devuelve
/// `Result`.
///
/// El teléfono guía al usuario con un detector local, pero NO decide: todo el
/// análisis que cuenta (pose, parpadeo, match facial) corre en el servidor,
/// que además impone qué gestos se piden y en qué orden.
abstract interface class KycRepository {
  /// Abre un desafío. El servidor decide qué tareas y en qué orden.
  FutureResult<KycFailure, LivenessChallenge> requestChallenge();

  /// Verificación final, en UN solo envío: documento + un segmento de
  /// fotogramas por cada tarea del desafío. El servidor valida cada segmento.
  ///
  /// Los fotogramas son JPEG en base64 sin el prefijo `data:`. Son datos
  /// biométricos: no deben escribirse a disco ni aparecer en logs.
  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    required Map<LivenessStep, List<String>> segments,
  });
}
