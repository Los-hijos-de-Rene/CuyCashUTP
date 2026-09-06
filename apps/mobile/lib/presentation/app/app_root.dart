import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/env/app_flavor.dart';
import '../../core/injection/app_dependencies.dart';
import '../../core/injection/modules/auth_module.dart';
import 'cuycash_app.dart';

/// Composición raíz: recibe el grafo resuelto (`AppDependencies`) y lo provee —
/// flavor por RepositoryProvider, blocs por sus módulos.
class AppRoot extends StatelessWidget {
  const AppRoot({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AppFlavor>.value(
      value: dependencies.flavor,
      child: MultiBlocProvider(
        providers: [
          ...AuthModule.blocProviders(dependencies),
        ],
        child: CuyCashApp(dependencies: dependencies),
      ),
    );
  }
}
