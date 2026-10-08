import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';

import 'document_check.dart';
import 'kyc_failure.dart';
import 'liveness_challenge.dart';
import 'liveness_step.dart';

/// Contrato del servicio de KYC facial (domain). Nunca lanza: devuelve
/// `Result`.
///
/// El teléfono guía al usuario con un detector local, pero NO decide: todo el
/// análisis que cuenta (documento, pose, parpadeo, match facial) corre en el
/// servidor, que además impone qué gestos se piden y en qué orden.
abstract interface class KycRepository {
  /// Revisa el FRENTE del DNI recién fotografiado: nitidez, luz, resolución y
  /// que se vea el rostro.
  FutureResult<KycFailure, DocumentCheck> checkDocumentFront(Uint8List image);

  /// Lee el REVERSO del DNI (MRZ) y lo coteja con el DNI que escribió el
  /// usuario.
  FutureResult<KycFailure, DocumentCheck> checkDocumentBack(
    Uint8List image, {
    required String expectedDni,
  });

  /// Abre un desafío. El servidor decide qué tareas y en qué orden.
  FutureResult<KycFailure, LivenessChallenge> requestChallenge();

  /// Verificación final, en UN solo envío: frente y reverso del documento, el
  /// DNI declarado y un segmento de fotogramas por cada tarea del desafío. El
  /// servidor valida cada parte.
  ///
  /// Los fotogramas son JPEG en base64 sin el prefijo `data:`. Son datos
  /// biométricos: no deben escribirse a disco ni aparecer en logs.
  FutureResult<KycFailure, KycVerification> verifyFull({
    required String token,
    required Uint8List documentImage,
    Uint8List? documentBackImage,
    String? expectedDni,
    required Map<LivenessStep, List<String>> segments,
  });
}
