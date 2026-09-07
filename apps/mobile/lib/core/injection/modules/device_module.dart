import '../../../feature/device/application/device_actions.dart';
import '../app_dependencies.dart';

abstract final class DeviceModule {
  static DeviceActions create(AppDependencies deps) =>
      DeviceActions(deps.deviceStore);
}
