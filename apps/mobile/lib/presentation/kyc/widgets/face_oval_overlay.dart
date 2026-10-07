import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Estado que comunica el borde del óvalo.
enum OvalTone {
  /// Todavía no hay un rostro bien encuadrado.
  idle,

  /// El rostro está bien: el usuario puede hacer el gesto.
  active,

  /// Gestos completos o identidad aprobada.
  success,

  /// El flujo se cayó o la identidad fue rechazada.
  error,
}

/// Oscurece todo lo que queda fuera del óvalo y dibuja su borde.
///
/// El óvalo dice dónde poner la cara sin necesidad de leer nada; el color del
/// borde dice si el encuadre ya está bien. Sus proporciones coinciden con las
/// que el bloc exige (rostro centrado y que ocupe buena parte del ancho).
class FaceOvalOverlay extends StatelessWidget {
  const FaceOvalOverlay({required this.tone, super.key});

  final OvalTone tone;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: _colorFor(tone)),
        duration: const Duration(milliseconds: 250),
        builder: (context, color, _) => CustomPaint(
          painter: _OvalPainter(border: color ?? _colorFor(tone)),
          size: Size.infinite,
        ),
      ),
    );
  }

  static Color _colorFor(OvalTone tone) => switch (tone) {
        OvalTone.idle => CuyCashColors.immersiveMuted,
        OvalTone.active => CuyCashColors.immersiveOcre,
        OvalTone.success => CuyCashColors.success,
        OvalTone.error => CuyCashColors.error,
      };
}

class _OvalPainter extends CustomPainter {
  const _OvalPainter({required this.border});

  final Color border;

  /// Rectángulo del óvalo: 70 % del ancho, proporción de rostro (≈ 1 : 1,3).
  static Rect ovalFor(Size size) {
    final width = size.width * 0.70;
    final height = (width * 1.3).clamp(0.0, size.height * 0.80);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.48),
      width: width,
      height: height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final oval = ovalFor(size);
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(
      shade,
      Paint()..color = CuyCashColors.immersiveDark.withValues(alpha: 0.6),
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_OvalPainter oldDelegate) => oldDelegate.border != border;
}
