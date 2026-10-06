import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Bloque gris que ocupa el lugar de un contenido mientras carga.
///
/// Late entre dos tonos de superficie en vez de barrer un brillo: es más
/// barato y no compite con el saldo cuando llega. Con "reducir movimiento"
/// activado se queda quieto.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  /// `circle` para avatares e íconos; entonces [radius] no se usa.
  final BoxShape shape;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            CuyCashColors.surfaceContainerHigh,
            CuyCashColors.surfaceContainer,
            _controller.value,
          ),
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
