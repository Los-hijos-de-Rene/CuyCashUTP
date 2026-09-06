import 'core/boot/bootstrap.dart';
import 'core/injection/envs/production_dependencies.dart';
import 'presentation/app/app_root.dart';

Future<void> main() => bootstrap(
      () async => AppRoot(dependencies: await buildProductionDependencies()),
    );
