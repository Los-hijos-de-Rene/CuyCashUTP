import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/env/app_flavor.dart';
import '../../core/injection/app_dependencies.dart';
import '../../core/injection/modules/auth_module.dart';
import '../../core/injection/modules/device_module.dart';
import '../../feature/auth/application/auth_actions.dart';
import '../../feature/device/application/device_actions.dart';
import '../../feature/device/domain/remembered_user.dart';
import '../auth/bloc/auth_bloc.dart';
import 'cuycash_app.dart';

/// Composición raíz: recibe el grafo resuelto (`AppDependencies`) y lo provee —
/// flavor por RepositoryProvider, blocs por sus módulos.
class AppRoot extends StatelessWidget {
  const AppRoot({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppFlavor>.value(value: dependencies.flavor),
        RepositoryProvider<AuthActions>.value(
            value: AuthActions(dependencies.authRepository)),
        RepositoryProvider<DeviceActions>.value(
            value: DeviceModule.create(dependencies)),
      ],
      child: MultiBlocProvider(
        providers: [
          ...AuthModule.blocProviders(dependencies),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (p, c) => c is AuthAuthenticated,
          listener: (context, state) {
            if (state is! AuthAuthenticated) return;
            final s = state.session;
            context.read<DeviceActions>().saveUser(RememberedUser(
                  dni: s.identifier,
                  fullName: s.fullName ?? '',
                  alias: s.alias ?? '@${s.identifier}',
                ));
          },
          child: CuyCashApp(dependencies: dependencies),
        ),
      ),
    );
  }
}
