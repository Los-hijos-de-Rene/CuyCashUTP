import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Una regla del PIN que el sistema SÍ puede comprobar. Una checklist que
/// incluya algo no verificable (la fecha de nacimiento, por ejemplo) miente.
class PinRule {
  const PinRule({required this.label, required this.done});

  final String label;
  final bool done;
}

/// Vista de captura de un PIN: encabezado, seis casillas y teclado propio.
///
/// Es la MISMA pareja de pantallas en el registro (crear + confirmar) y en la
/// recuperación, así que vive una sola vez. Lo que cambia entre usos es el
/// encabezado, las reglas y el contenido extra, no la mecánica.
///
/// Sin botón: el sexto dígito es el commit, y así el teclado siempre cabe.
class PinEntryView extends StatelessWidget {
  const PinEntryView({
    required this.headline,
    required this.subtitle,
    required this.pin,
    required this.onDigit,
    required this.onBackspace,
    this.rules = const [],
    this.errorText,
    this.hasError = false,
    this.extra,
    super.key,
  });

  final String headline;
  final String subtitle;
  final String pin;

  /// Reglas verificables, en el orden en que se muestran.
  final List<PinRule> rules;

  final String? errorText;
  final bool hasError;

  /// Contenido opcional entre las reglas y el teclado (un aviso, por ejemplo).
  final Widget? extra;

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: CuyCashSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: CuyCashTypography.headlineSm),
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(
                  subtitle,
                  style: CuyCashTypography.bodyLg
                      .copyWith(color: CuyCashColors.secondaryText),
                ),
                const SizedBox(height: CuyCashSpacing.stackXl),
                PinBoxes(pin: pin, hasError: hasError),
                if (errorText case final errorText?) ...[
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  _ErrorLine(text: errorText),
                ],
                if (rules.isNotEmpty) ...[
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  for (final rule in rules) _RuleRow(rule: rule),
                ],
                if (extra case final extra?) ...[
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  extra,
                ],
                const SizedBox(height: CuyCashSpacing.stackLg),
              ],
            ),
          ),
        ),
        // Teclado propio anclado abajo: el PIN nunca pasa por el del sistema.
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: CuyCashSpacing.stackLg),
          child: PinKeypad(onDigit: onDigit, onBackspace: onBackspace),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});
  final PinRule rule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CuyCashSpacing.stackSm),
      child: Row(
        children: [
          Icon(
            rule.done ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: rule.done
                ? CuyCashColors.success
                : CuyCashColors.outlineVariant,
          ),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(
            child: Text(
              rule.label,
              style: CuyCashTypography.labelSm.copyWith(
                fontSize: 13,
                color: rule.done
                    ? CuyCashColors.onSurface
                    : CuyCashColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 16, color: CuyCashColors.error),
        const SizedBox(width: CuyCashSpacing.stackSm),
        Expanded(
          child: Text(
            text,
            style: CuyCashTypography.labelSm.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CuyCashColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
