import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Dots del onboarding: el activo se alarga (barra Eucalipto).
class PageDotsIndicator extends StatelessWidget {
  const PageDotsIndicator({
    required this.count,
    required this.activeIndex,
    super.key,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          height: 6,
          width: active ? 24 : 6,
          decoration: BoxDecoration(
            color: active
                ? CuyCashColors.primary
                : CuyCashColors.outlineVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
