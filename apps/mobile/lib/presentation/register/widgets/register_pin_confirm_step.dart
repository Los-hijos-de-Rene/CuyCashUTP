import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../pin/pin_entry_view.dart';
import '../bloc/register_bloc.dart';

/// Paso 4B · confirmación del PIN.
///
/// Sin este paso, un error de tecleo termina el registro con un PIN que el
/// usuario no conoce: quedaría fuera de su cuenta el mismo día que la abrió.
class RegisterPinConfirmStep extends StatelessWidget {
  const RegisterPinConfirmStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final bloc = context.read<RegisterBloc>();
        return PinEntryView(
          headline: l10n.pinConfirmHeadline,
          subtitle: l10n.pinConfirmSubtitle,
          pin: state.draft.confirmPin,
          hasError: state.pinMismatch,
          errorText: state.pinMismatch ? l10n.resetPinMismatch : null,
          onDigit: (digit) => bloc.add(RegisterEvent.pinDigitPressed(digit)),
          onBackspace: () => bloc.add(const RegisterEvent.pinBackspace()),
        );
      },
    );
  }
}
