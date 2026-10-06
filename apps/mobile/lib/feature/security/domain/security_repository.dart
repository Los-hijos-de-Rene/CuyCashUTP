import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import 'linked_device.dart';
import 'security_failure.dart';

/// Seguridad de la cuenta con sesión abierta. Nunca lanza.
abstract interface class SecurityRepository {
  /// Devuelve cuántas sesiones de OTROS teléfonos se cerraron.
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  });

  FutureResult<SecurityFailure, List<LinkedDevice>> devices();

  FutureResult<SecurityFailure, Unit> unlinkDevice(String id);

  /// El secreto que la huella liberará; el servidor solo guarda su hash.
  FutureResult<SecurityFailure, String> enrollBiometric(String pin);

  FutureResult<SecurityFailure, Unit> revokeBiometric();
}
