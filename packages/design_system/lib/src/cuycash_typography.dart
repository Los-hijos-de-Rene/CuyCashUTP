import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Escala tipográfica (DESIGN.md). Inter cuando esté en assets; hasta entonces
/// `fontFamily` = null (cae al system font). Un solo lugar para activar Inter.
abstract final class CuyCashTypography {
  static const _family = null; // 'Inter' cuando el .ttf esté en assets/fonts/

  static const displayLg = TextStyle(
    fontFamily: _family, fontSize: 36, fontWeight: FontWeight.w700,
    height: 44 / 36, letterSpacing: -0.72, color: CuyCashColors.onSurface,
  );
  static const headlineLgMobile = TextStyle(
    fontFamily: _family, fontSize: 30, fontWeight: FontWeight.w700,
    height: 38 / 30, color: CuyCashColors.onSurface,
  );
  static const headlineMd = TextStyle(
    fontFamily: _family, fontSize: 28, fontWeight: FontWeight.w700,
    height: 36 / 28, letterSpacing: -0.28, color: CuyCashColors.onSurface,
  );
  static const headlineSm = TextStyle(
    fontFamily: _family, fontSize: 24, fontWeight: FontWeight.w600,
    height: 32 / 24, color: CuyCashColors.onSurface,
  );
  static const titleMd = TextStyle(
    fontFamily: _family, fontSize: 20, fontWeight: FontWeight.w600,
    height: 28 / 20, color: CuyCashColors.onSurface,
  );
  static const bodyLg = TextStyle(
    fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w400,
    height: 24 / 16, color: CuyCashColors.onSurface,
  );
  static const bodyMd = TextStyle(
    fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w400,
    height: 20 / 14, color: CuyCashColors.secondaryText,
  );
  static const labelMd = TextStyle(
    fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w600,
    height: 20 / 14, letterSpacing: 0.14, color: CuyCashColors.primary,
  );
  static const labelSm = TextStyle(
    fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w500,
    height: 16 / 12, color: CuyCashColors.secondaryText,
  );
}
