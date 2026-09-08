import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../pin/pin_entry_view.dart';
import '../bloc/register_bloc.dart';

/// Paso 4A · el PIN nace aquí.
///
/// Teclado propio desde el primer momento en que el secreto existe: si el del
/// sistema lo capturara, lo capturaría en su origen.
class RegisterPinStep extends StatelessWidget {
  const RegisterPinStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final bloc = context.read<RegisterBloc>();
        return PinEntryView(
          headline: l10n.pinHeadline,
          subtitle: l10n.pinSubtitle,
          pin: state.draft.pin,
          // Solo reglas que el sistema comprueba de verdad.
          rules: [
            PinRule(label: l10n.pinRule6, done: state.pinHasSixDigits),
            PinRule(
                label: l10n.pinRuleNoRepeats,
                done: state.pinHasNoRepeatedDigit),
            PinRule(
                label: l10n.pinRuleNoSequence, done: state.pinHasNoSequence),
          ],
          onDigit: (digit) => bloc.add(RegisterEvent.pinDigitPressed(digit)),
          onBackspace: () => bloc.add(const RegisterEvent.pinBackspace()),
        );
      },
    );
  }
}
