import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/injection/app_dependencies.dart';
import '../../core/injection/modules/register_module.dart';
import '../auth/bloc/auth_bloc.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_screen.dart';
import '../register/bloc/register_bloc.dart';
import '../register/register_flow_screen.dart';
import '../shell/app_shell.dart';
import '../splash/splash_screen.dart';
import '../auth/login_screen.dart';
import 'app_redirect.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

/// Router: gate de auth + shell de 2 tabs (Home, Perfil).
GoRouter createAppRouter(AppDependencies deps, AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      if (state.matchedLocation == AppRoutes.splash) return null;
      return appRedirect(authBloc.state, state.matchedLocation);
    },
    routes: [
      GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.registro,
        builder: (context, state) => BlocProvider<RegisterBloc>(
          create: (_) => RegisterModule.create(deps),
          child: const RegisterFlowScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.perfil,
                builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}
