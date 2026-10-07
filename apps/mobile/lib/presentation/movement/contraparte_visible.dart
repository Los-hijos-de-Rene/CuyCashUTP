import 'package:core_kernel/core_kernel.dart';

import '../../feature/account/domain/movement.dart';

/// La contraparte tal como se pinta. En una transferencia es el nombre de una
/// persona (guardado en minúsculas, o enmascarado): lleva mayúscula al inicio
/// de cada palabra. En una recarga es un texto del sistema y queda igual.
String? contraparteVisible(Movement movement) => switch (movement.contraparte) {
  null => null,
  final c when movement.tipo == MovementKind.transferencia => formatNombre(c),
  final c => c,
};
