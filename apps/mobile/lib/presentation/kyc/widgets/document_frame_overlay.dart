import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/kyc/infrastructure/document_cropper.dart';

/// Marco horizontal con la proporción del DNI sobre la vista previa.
///
/// Oscurece lo que queda fuera y marca las cuatro esquinas, como en los
/// flujos de la industria: dice dónde poner la tarjeta sin tener que leer.
/// El rectángulo es el mismo con el que luego se recorta la foto
/// ([documentFrameFor]).
class DocumentFrameOverlay extends StatelessWidget {
  const DocumentFrameOverlay({required this.hint, super.key});

  /// Indicación que se muestra encima del marco.
  final String hint;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frame = documentFrameFor(constraints.biggest);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _FramePainter(frame: frame)),
              ),
              Positioned(
                left: CuyCashSpacing.containerPadding,
                right: CuyCashSpacing.containerPadding,
                bottom: constraints.maxHeight - frame.top +
                    CuyCashSpacing.stackMd,
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: CuyCashTypography.titleMd.copyWith(
                    color: CuyCashColors.immersiveOnDark,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.frame});

  final Rect frame;

  static const _radius = Radius.circular(12);

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(frame, _radius);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(card),
      Paint()..color = CuyCashColors.immersiveDark.withValues(alpha: 0.6),
    );

    // Borde tenue completo + esquinas marcadas en ocre.
    canvas.drawRRect(
      card,
      Paint()
        ..color = CuyCashColors.immersiveOnDark.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final corner = Paint()
      ..color = CuyCashColors.immersiveOcre
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final arm = frame.shortestSide * 0.18;
    final l = frame.left, t = frame.top, r = frame.right, b = frame.bottom;
    for (final path in [
      Path()..moveTo(l, t + arm)..lineTo(l, t)..lineTo(l + arm, t),
      Path()..moveTo(r - arm, t)..lineTo(r, t)..lineTo(r, t + arm),
      Path()..moveTo(r, b - arm)..lineTo(r, b)..lineTo(r - arm, b),
      Path()..moveTo(l + arm, b)..lineTo(l, b)..lineTo(l, b - arm),
    ]) {
      canvas.drawPath(path, corner);
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.frame != frame;
}
