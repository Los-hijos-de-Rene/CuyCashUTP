import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';

import 'kyc_failure.dart';
import 'liveness_challenge.dart';
import 'liveness_step.dart';

/// Contrato del servicio de KYC facial (domain). Nunca lanza: devuelve
/// `Result`.
///
/// El teléfono NO ejecuta modelos: captura ráfagas y pregunta. Todo el análisis
/// (pose, parpadeo, match facial) corre en el servidor, que además impone el
/// orden de las tareas.
abstract interface class KycRepository {
  /// Abre un desafío. El servidor decide qué tareas y en qué orden.
  FutureResult<KycFailure, LivenessChallenge> requestChallenge();

  /// Evalúa UNA tarea. La siguiente solo se desbloquea con `passed:true`.
  ///
  /// [framesBase64] son JPEG en base64 sin el prefijo `data:`. Son datos
  /// biométricos: no deben escribirse a disco ni aparecer en logs.
  FutureResult<KycFailure, StepEvaluation> evaluateStep({
    required String token,
    required LivenessStep step,
    required List<String> framesBase64,
  });

  /// Verificación final: documento + los segmentos ya validados.
  ///
  /// [segments] debe traer TODAS las tareas del desafío, con la ráfaga que
  /// pasó en `evaluateStep`.
  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    required Map<LivenessStep, List<String>> segments,
  });
}
