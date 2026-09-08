import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Un slide del onboarding con su ilustración y copy.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.illustrationIndex,
    required this.title,
    required this.description,
    super.key,
  });

  final int illustrationIndex;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CuyCashSpacing.marginMobile,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          AspectRatio(
            aspectRatio: 1.2,
            child: _OnboardingIllustration(index: illustrationIndex),
          ),
          const Spacer(),
          Text(title, style: CuyCashTypography.headlineLgMobile),
          const SizedBox(height: CuyCashSpacing.stackMd),
          Text(
            description,
            style: CuyCashTypography.bodyLg.copyWith(
              color: CuyCashColors.secondaryText,
            ),
          ),
          const SizedBox(height: CuyCashSpacing.stackXl),
        ],
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OnboardingIllustrationPainter(index: index),
      child: const SizedBox.expand(),
    );
  }
}

class _OnboardingIllustrationPainter extends CustomPainter {
  _OnboardingIllustrationPainter({required this.index});

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Paint()
      ..color = CuyCashColors.primaryContainer.withValues(alpha: .1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final ink = Paint()
      ..color = CuyCashColors.primaryContainer
      ..style = PaintingStyle.fill;
    final accent = Paint()
      ..color = CuyCashColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
    final light = Paint()
      ..color = CuyCashColors.surface
      ..style = PaintingStyle.fill;

    _paintSvgFrame(canvas, size, frame);

    switch (index) {
      case 0:
        _paintAccountCard(canvas, size, ink, accent, light);
      case 1:
        _paintTransfer(canvas, size, ink, accent);
      default:
        _paintReceive(canvas, size, ink, accent);
    }
  }

  void _paintSvgFrame(Canvas canvas, Size size, Paint frame) {
    final artworkSize = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(
      (size.width - artworkSize) / 2,
      (size.height - artworkSize) / 2,
    );
    canvas.scale(artworkSize / 256);
    final path = Path()
      ..moveTo(128, 1)
      ..cubicTo(198.14, 1, 255, 57.8598, 255, 128)
      ..lineTo(255, 254.98)
      ..lineTo(1.01953, 255)
      ..lineTo(1, 128)
      ..cubicTo(1, 57.8598, 57.8598, 1, 128, 1);
    canvas.drawPath(path, frame);
    canvas.restore();
  }

  void _paintAccountCard(
    Canvas canvas,
    Size size,
    Paint ink,
    Paint accent,
    Paint light,
  ) {
    final artworkSize = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(
      (size.width - artworkSize) / 2,
      (size.height - artworkSize) / 2,
    );
    canvas.scale(artworkSize / 256);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(64, 104, 128, 80),
        const Radius.circular(8),
      ),
      ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 116, 24, 24),
        const Radius.circular(12),
      ),
      Paint()..color = CuyCashColors.surfaceContainerLow,
    );
    final avatarRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          CuyCashColors.secondary,
        ],
        stops: const [0, .62, 1],
      ).createShader(const Rect.fromLTWH(74.5, 114.5, 27, 27));
    canvas.drawCircle(const Offset(88, 128), 13, avatarRing);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 148, 48, 4),
        const Radius.circular(2),
      ),
      light,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 158, 32, 4),
        const Radius.circular(2),
      ),
      light,
    );
    canvas.restore();
  }

  void _paintTransfer(Canvas canvas, Size size, Paint ink, Paint accent) {
    final artworkSize = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(
      (size.width - artworkSize) / 2,
      (size.height - artworkSize) / 2,
    );
    canvas.scale(artworkSize / 256);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(64, 128, 64, 64),
        const Radius.circular(8),
      ),
      ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(144, 64, 48, 48),
        const Radius.circular(8),
      ),
      ink,
    );
    final arrow = Path()
      ..moveTo(108, 148)
      ..cubicTo(121.333, 108, 138, 91.3333, 158, 98)
      ..moveTo(158, 98)
      ..lineTo(153, 93)
      ..moveTo(158, 98)
      ..lineTo(153, 103);
    canvas.drawPath(arrow, accent);
    canvas.restore();
  }

  void _paintReceive(Canvas canvas, Size size, Paint ink, Paint accent) {
    final artworkSize = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(
      (size.width - artworkSize) / 2,
      (size.height - artworkSize) / 2,
    );
    canvas.scale(artworkSize / 256);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 80, 96, 96),
        const Radius.circular(8),
      ),
      ink,
    );
    canvas.drawLine(const Offset(0, 127.25), const Offset(80, 127.25), accent);
    canvas.drawLine(
      const Offset(176, 127.25),
      const Offset(256, 127.25),
      accent,
    );
    canvas.drawLine(const Offset(127.25, 0), const Offset(127.25, 80), accent);
    _drawDiamond(canvas, const Offset(76, 128));
    _drawDiamond(canvas, const Offset(128, 76));
    _drawDiamond(canvas, const Offset(180, 128));
    canvas.restore();
  }

  void _drawDiamond(Canvas canvas, Offset center) {
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 5.657)
      ..lineTo(center.dx + 5.657, center.dy)
      ..lineTo(center.dx, center.dy + 5.657)
      ..lineTo(center.dx - 5.657, center.dy)
      ..close();
    canvas.drawPath(
      diamond,
      Paint()
        ..color = CuyCashColors.secondary
        ..style = PaintingStyle.fill,
    );
    final innerDiamond = Path()
      ..moveTo(center.dx, center.dy - 3.9)
      ..lineTo(center.dx + 3.9, center.dy)
      ..lineTo(center.dx, center.dy + 3.9)
      ..lineTo(center.dx - 3.9, center.dy)
      ..close();
    canvas.drawPath(
      innerDiamond,
      Paint()
        ..color = CuyCashColors.surface
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_OnboardingIllustrationPainter oldDelegate) =>
      oldDelegate.index != index;
}
