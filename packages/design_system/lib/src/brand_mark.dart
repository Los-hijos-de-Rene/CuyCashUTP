import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Logo placeholder "CC" (dos anillos entrelazados eucalipto/ocre). Se
/// reemplaza por el asset vectorial final cuando esté disponible.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _Ring(size: size * 0.7, color: CuyCashColors.surface),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _Ring(size: size * 0.7, color: CuyCashColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: size * 0.14),
      ),
    );
  }
}
