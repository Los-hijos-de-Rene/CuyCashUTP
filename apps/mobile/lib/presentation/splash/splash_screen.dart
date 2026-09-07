import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';

/// Splash breve: muestra la marca y luego navega a onboarding (el gate del
/// router lo reenviará a /home si ya hay sesión).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go(AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
