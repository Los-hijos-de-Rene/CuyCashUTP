import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';

/// Paso 4C · acceso biométrico. Sin teclado, así que la pantalla respira y el
/// botón "Finalizar registro" cabe sin apretar nada.
class RegisterBiometricStep extends StatelessWidget {
  const RegisterBiometricStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final bloc = context.read<RegisterBloc>();
        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile),
          children: [
            Text(l10n.biometricHeadline, style: CuyCashTypography.headlineSm),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(
              l10n.biometricBody,
              style: CuyCashTypography.bodyLg
                  .copyWith(color: CuyCashColors.secondaryText),
            ),
            const SizedBox(height: CuyCashSpacing.stackXl),
            _BiometricCard(
              enabled: state.draft.biometricEnabled,
              onChanged: (value) =>
                  bloc.add(RegisterEvent.biometricToggled(value)),
            ),
          ],
        );
      },
    );
  }
}

class _BiometricCard extends StatelessWidget {
  const _BiometricCard({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(CuyCashSpacing.stackMd),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CuyCashColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(CuyCashRadii.sm),
            ),
            child: const Icon(Icons.fingerprint,
                size: 20, color: CuyCashColors.primaryContainer),
          ),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Expanded(
            child: Text(
              l10n.biometricTitle,
              style: CuyCashTypography.titleMd.copyWith(fontSize: 16),
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
