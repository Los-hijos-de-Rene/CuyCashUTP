import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../presentation/auth/bloc/auth_bloc.dart';
import '../app_dependencies.dart';
import 'device_module.dart';
import 'lockout_module.dart';

/// Wiring de auth: arma `AuthActions` desde el `AuthRepository` y la inyecta al
/// `AuthBloc` (el bloc nunca recibe el repository directo).
abstract final class AuthModule {
  static List<BlocProvider<AuthBloc>> blocProviders(AppDependencies deps) => [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            AuthActions(deps.authRepository),
            DeviceModule.create(deps),
            LockoutModule.create(deps),
          ),
        ),
      ];
}
