import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'widgets/onboarding_slide.dart';

/// Carrusel de 3 slides. El índice es estado local (UI pura, sin Bloc).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = [
      (title: l10n.onboardingTitle1, description: l10n.onboardingBody1),
      (title: l10n.onboardingTitle2, description: l10n.onboardingBody2),
      (title: l10n.onboardingTitle3, description: l10n.onboardingBody3),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
                itemCount: slides.length,
                itemBuilder: (_, index) => OnboardingSlide(
                  illustrationIndex: index,
                  title: slides[index].title,
                  description: slides[index].description,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CuyCashSpacing.marginMobile,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PageDotsIndicator(
                      count: slides.length,
                      activeIndex: _index,
                    ),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  PrimaryButton(
                    label: l10n.createAccount,
                    onPressed: () => context.go(AppRoutes.registro),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  GhostButton(
                    label: l10n.alreadyHaveAccount,
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackMd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
