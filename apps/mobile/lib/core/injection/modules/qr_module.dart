import '../../../feature/qr/application/qr_actions.dart';
import '../app_dependencies.dart';

/// Wiring de QR: expone `QrActions` sobre el repositorio del grafo.
abstract final class QrModule {
  static QrActions create(AppDependencies deps) => deps.qrActions;
}
