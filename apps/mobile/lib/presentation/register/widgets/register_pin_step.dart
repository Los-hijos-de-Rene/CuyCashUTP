import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'pin_boxes.dart';

/// Paso 4 · Seguridad. PIN de 6 dígitos + reglas + toggle biométrico.
class RegisterPinStep extends StatefulWidget {
  const RegisterPinStep({super.key});

  @override
  State<RegisterPinStep> createState() => _RegisterPinStepState();
}

class _RegisterPinStepState extends State<RegisterPinStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final pin = state.draft.pin;
        final len6 = pin.length == 6;
        final noSeq = RegisterValidators.pinValid(pin);
        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile),
          children: [
            Text(l10n.pinHeadline, style: CuyCashTypography.headlineSm),
            const SizedBox(height: CuyCashSpacing.stackLg),
            // Campo oculto que captura el teclado numérico; las casillas son visuales.
            Stack(
              children: [
                PinBoxes(pin: pin),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) =>
                          bloc.add(RegisterEvent.pinChanged(v)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _rule(l10n.pinRule6, len6),
            _rule(l10n.pinRuleNoSequence, noSeq),
            _ruleAdvisory(l10n.pinRuleNoBirthdate),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _BiometricCard(
              enabled: state.draft.biometricEnabled,
              onChanged: (v) => bloc.add(RegisterEvent.biometricToggled(v)),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: CuyCashColors.secondaryText),
                const SizedBox(width: CuyCashSpacing.stackSm),
                Expanded(
                  child: Text(l10n.securityNote,
                      style: CuyCashTypography.labelSm),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _rule(String text, bool done) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: done
                    ? CuyCashColors.primaryContainer
                    : CuyCashColors.outlineVariant),
            const SizedBox(width: CuyCashSpacing.stackMd),
            Text(text,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.onSurface)),
          ],
        ),
      );

  Widget _ruleAdvisory(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const Icon(Icons.circle,
                size: 8, color: CuyCashColors.outlineVariant),
            const SizedBox(width: CuyCashSpacing.stackMd),
            Text(text,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
          ],
        ),
      );
}

class _BiometricCard extends StatelessWidget {
  const _BiometricCard({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      decoration: BoxDecoration(
        color: CuyCashColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CuyCashRadii.card),
        boxShadow: const [
          BoxShadow(
              color: CuyCashColors.ambientShadow,
              blurRadius: 12,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint, color: CuyCashColors.primaryContainer),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.biometricTitle,
                    style: CuyCashTypography.titleMd.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(l10n.biometricSubtitle,
                    style: CuyCashTypography.bodyMd
                        .copyWith(color: CuyCashColors.secondaryText)),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: CuyCashColors.primaryContainer,
          ),
        ],
      ),
    );
  }
}
