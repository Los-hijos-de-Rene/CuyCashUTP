import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Un slide del onboarding: ilustración placeholder + título + descripción.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CuyCashSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          AspectRatio(
            aspectRatio: 1.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: CuyCashColors.outlineVariant),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(160)),
              ),
              child: const Center(child: BrandMark(size: 80)),
            ),
          ),
          const Spacer(),
          Text(title, style: CuyCashTypography.headlineLgMobile),
          const SizedBox(height: CuyCashSpacing.stackMd),
          Text(description, style: CuyCashTypography.bodyLg
              .copyWith(color: CuyCashColors.secondaryText)),
          const SizedBox(height: CuyCashSpacing.stackXl),
        ],
      ),
    );
  }
}
