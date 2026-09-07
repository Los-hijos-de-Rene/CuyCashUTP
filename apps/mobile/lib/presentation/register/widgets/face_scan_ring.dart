import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Anillo circular del viewport de escaneo facial (placeholder visual, sin
/// cámara real). El color ocre indica escaneo activo.
class FaceScanRing extends StatelessWidget {
  const FaceScanRing({required this.active, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? CuyCashColors.immersiveOcre
                    : CuyCashColors.immersiveMuted,
                width: 3,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CuyCashColors.immersivePanel,
            ),
            child: const Icon(Icons.person_outline,
                size: 120, color: CuyCashColors.immersiveMuted),
          ),
        ],
      ),
    );
  }
}
