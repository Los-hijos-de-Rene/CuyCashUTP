import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_typography.dart';

/// Teclado numérico propio de CuyCash.
///
/// El PIN NO pasa por el teclado del sistema: Gboard, SwiftKey y compañía ven
/// cada pulsación y llevan su propio historial. Dibujarlo nosotros es una
/// medida de seguridad, no de estilo — por eso el mismo componente sirve a
/// todas las pantallas de PIN, y cualquier cambio las alcanza a la vez.
///
/// Sin las letras del teclado telefónico (E.161): son herencia del marcado y no
/// aportan nada a un PIN, que nadie deletrea.
///
/// El orden de las teclas es FIJO a propósito. Barajarlo protegería del vistazo
/// por encima del hombro, pero rompe la memoria muscular en la operación más
/// repetida de la app y deja fuera a quien depende de la posición de las teclas
/// para usarla; además, con lector de pantalla habría que anunciar el dígito
/// real de cada tecla, que es justo lo que el barajado pretendía ocultar.
///
/// (El código OTP es el caso contrario: no es un secreto duradero y sí
/// queremos el autorrelleno del sistema, así que ahí se usa un campo normal.)
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    super.key,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  /// Sin biométrico la celda queda vacía: fila inferior = vacío · 0 · borrar.
  final VoidCallback? onBiometric;

  static const keyHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          _KeyRow(
            children: [
              for (final digit in row)
                _DigitKey(digit: digit, onTap: () => onDigit(digit)),
            ],
          ),
        _KeyRow(
          children: [
            _biometricKey(),
            _DigitKey(digit: 0, onTap: () => onDigit(0)),
            _IconKey(
              icon: Icons.backspace_outlined,
              onTap: onBackspace,
              label: 'Borrar',
            ),
          ],
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

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PinKeypad.keyHeight,
      child: Row(
        children: [
          for (final child in children) Expanded(child: child),
        ],
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
        child: Text(
          '$digit',
          style: CuyCashTypography.headlineSm.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: CuyCashColors.primaryContainer,
          ),
        ),
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
        child: Icon(icon,
            size: 24,
            color: CuyCashColors.primaryContainer,
            semanticLabel: label),
      ),
    );
  }
}
