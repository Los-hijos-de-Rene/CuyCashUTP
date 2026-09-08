import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/device/application/device_actions.dart';
import '../app/app_routes.dart';

/// Splash breve: lee DeviceActions para decidir la ruta inicial.
/// - Bloqueado → /bloqueado
/// - Usuario recordado → /acceso-rapido
/// - Sin usuario → /onboarding (el gate redirigirá a /home si hay sesión)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final device = context.read<DeviceActions>();
    final lockout = await device.readLockout();
    final user = await device.readUser();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (lockout.isLocked(DateTime.now())) {
      context.go(AppRoutes.blocked);
    } else if (user != null) {
      context.go(AppRoutes.quickAccess);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuyCashColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/cuycash.png', width: 112, height: 112),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Text('CuyCash',
                style: CuyCashTypography.headlineMd
                    .copyWith(color: CuyCashColors.surface)),
            const SizedBox(height: CuyCashSpacing.stackLg),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: CuyCashColors.secondary,
                backgroundColor: CuyCashColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
