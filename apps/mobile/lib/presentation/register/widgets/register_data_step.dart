import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'register_error_banner.dart';

/// Paso 1 · Datos. Formulario con validación inline vía RegisterBloc.
///
/// Los campos van encadenados: "siguiente" del teclado pasa al próximo y
/// "listo" en el último intenta avanzar. El DNI (teclado numérico, sin tecla de
/// retorno en iOS) salta solo a Nombres al completar los 8 dígitos. El botón
/// vive al final del formulario para no restarle espacio al teclado abierto.
class RegisterDataStep extends StatefulWidget {
  const RegisterDataStep({super.key});

  @override
  State<RegisterDataStep> createState() => _RegisterDataStepState();
}

class _RegisterDataStepState extends State<RegisterDataStep> {
  static const _dniLength = 8;

  final _dni = FocusNode();
  final _nombres = FocusNode();
  final _apellidos = FocusNode();
  final _email = FocusNode();

  @override
  void dispose() {
    _dni.dispose();
    _nombres.dispose();
    _apellidos.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _errorText(AppLocalizations l10n, FieldError? error) => switch (error) {
        FieldError.dniLength => l10n.errorDniLength,
        FieldError.emailInvalid => l10n.errorEmailInvalid,
        FieldError.requiredField => l10n.fieldRequired,
        null => null,
      };

  /// Lleva a la vista el primer campo con error, para que el aviso del banner
  /// no deje al usuario buscando qué corregir.
  void _showFirstError(RegisterErrors errors) {
    final focus = [
      (errors.dni, _dni),
      (errors.nombres, _nombres),
      (errors.apellidos, _apellidos),
      (errors.email, _email),
    ].where((e) => e.$1 != null).map((e) => e.$2).firstOrNull;
    final ctx = focus?.context;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.1, duration: const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    void advance() {
      FocusScope.of(context).unfocus();
      bloc.add(const RegisterEvent.stepAdvanced());
      // Con datos inválidos el Bloc marca los errores; ya pintados, se muestra
      // el primero.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showFirstError(bloc.state.errors);
      });
    }

    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final errors = state.errors;
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            CuyCashSpacing.marginMobile,
            0,
            CuyCashSpacing.marginMobile,
            CuyCashSpacing.stackLg,
          ),
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
                    focusNode: _dni,
                    label: l10n.dniFieldLabel,
                    hint: l10n.dniHint,
                    helperText: errors.dni == null ? l10n.dniHelper : null,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    maxLength: _dniLength,
                    errorText: _errorText(l10n, errors.dni),
                    onChanged: (v) {
                      bloc.add(
                          RegisterEvent.fieldChanged(RegisterField.dni, v));
                      if (v.length == _dniLength) _nombres.requestFocus();
                    },
                    onSubmitted: (_) => _nombres.requestFocus(),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    focusNode: _nombres,
                    label: l10n.nombresLabel,
                    hint: l10n.nombresHint,
                    textInputAction: TextInputAction.next,
                    errorText: _errorText(l10n, errors.nombres),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.nombres, v)),
                    onSubmitted: (_) => _apellidos.requestFocus(),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    focusNode: _apellidos,
                    label: l10n.apellidosLabel,
                    hint: l10n.apellidosHint,
                    textInputAction: TextInputAction.next,
                    errorText: _errorText(l10n, errors.apellidos),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.apellidos, v)),
                    onSubmitted: (_) => _email.requestFocus(),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    focusNode: _email,
                    label: l10n.emailLabel,
                    hint: l10n.emailHint,
                    helperText: errors.email == null ? l10n.emailHelper : null,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    errorText: _errorText(l10n, errors.email),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.email, v)),
                    onSubmitted: (_) => advance(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _InfoStrip(text: l10n.identityInfo),
            const SizedBox(height: CuyCashSpacing.stackLg),
            // Siempre pulsable: con datos inválidos dispara la validación.
            PrimaryButton(label: l10n.continueCta, onPressed: advance),
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
