import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'register_error_banner.dart';

/// Paso 1 · Datos. Formulario con validación inline vía RegisterBloc.
class RegisterDataStep extends StatelessWidget {
  const RegisterDataStep({super.key});

  String? _errorText(AppLocalizations l10n, FieldError? error) => switch (error) {
        FieldError.dniLength => l10n.errorDniLength,
        FieldError.emailInvalid => l10n.errorEmailInvalid,
        FieldError.requiredField => l10n.fieldRequired,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final errors = state.errors;
        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile),
          children: [
            Text(l10n.dataHeadline, style: CuyCashTypography.headlineSm),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.dataSubtitle,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Container(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              decoration: BoxDecoration(
                color: CuyCashColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(CuyCashRadii.card),
                border: Border.all(color: CuyCashColors.outlineVariant),
              ),
              child: Column(
                children: [
                  if (errors.showBanner && errors.count > 0) ...[
                    RegisterErrorBanner(
                        message: l10n.errorFixFields(errors.count)),
                    const SizedBox(height: CuyCashSpacing.stackLg),
                  ],
                  CuyCashTextField(
                    label: l10n.dniFieldLabel,
                    hint: l10n.dniHint,
                    helperText: errors.dni == null ? l10n.dniHelper : null,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    errorText: _errorText(l10n, errors.dni),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.dni, v)),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    label: l10n.nombresLabel,
                    hint: l10n.nombresHint,
                    errorText: _errorText(l10n, errors.nombres),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.nombres, v)),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    label: l10n.apellidosLabel,
                    hint: l10n.apellidosHint,
                    errorText: _errorText(l10n, errors.apellidos),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.apellidos, v)),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    label: l10n.emailLabel,
                    hint: l10n.emailHint,
                    helperText: errors.email == null ? l10n.emailHelper : null,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _errorText(l10n, errors.email),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.email, v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _InfoStrip(text: l10n.identityInfo),
          ],
        );
      },
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuyCashColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(CuyCashRadii.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: CuyCashColors.primaryContainer, size: 22),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(
            child: Text(text,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.primaryContainer)),
          ),
        ],
      ),
    );
  }
}
