import '../../env/app_flavor.dart';
import '../app_dependencies.dart';
import 'shared/shared_backend_dependencies.dart';

Future<AppDependencies> buildLocalDependencies() =>
    buildSharedBackendDependencies(AppFlavor.local);
