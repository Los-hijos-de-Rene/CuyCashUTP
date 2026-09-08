import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_typography.dart';

/// Teclado numérico del acceso rápido (1-9, biométrico, 0, backspace).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    super.key,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.4,
      children: [
        for (var n = 1; n <= 9; n++) _DigitKey(digit: n, onTap: () => onDigit(n)),
        _biometricKey(),
        _DigitKey(digit: 0, onTap: () => onDigit(0)),
        _IconKey(
          icon: Icons.backspace_outlined,
          onTap: onBackspace,
          label: 'Borrar',
        ),
      ],
    );
  }

  Widget _biometricKey() {
    if (onBiometric == null) return const SizedBox.shrink();
    return Center(
      child: Material(
        color: CuyCashColors.primaryContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onBiometric,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.fingerprint, color: CuyCashColors.onPrimary),
          ),
        ),
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onTap});
  final int digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Center(
        child: Text('$digit',
            style: CuyCashTypography.headlineMd
                .copyWith(color: CuyCashColors.primaryContainer)),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({required this.icon, required this.onTap, required this.label});
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Center(
        child: Icon(icon, color: CuyCashColors.primaryContainer, semanticLabel: label),
      ),
    );
  }
}
