import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../core/injection/app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'router.dart';

/// MaterialApp.router con theme + l10n. Crea el router una sola vez con el
/// AuthBloc del árbol.
class CuyCashApp extends StatefulWidget {
  const CuyCashApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<CuyCashApp> createState() => _CuyCashAppState();
}

class _CuyCashAppState extends State<CuyCashApp> {
  late final router = createAppRouter(
    widget.dependencies,
    context.read<AuthBloc>(),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CuyCash',
      debugShowCheckedModeBanner: false,
      theme: CuyCashTheme.light(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
