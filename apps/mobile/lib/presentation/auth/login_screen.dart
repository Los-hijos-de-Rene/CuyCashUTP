import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'auth_error_text.dart';
import 'bloc/auth_bloc.dart';

/// Login con DNI (8 dígitos) + PIN de 6 dígitos (casillas). "Ingresar" se
/// habilita solo cuando ambos campos están completos.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _dni = TextEditingController();
  final _pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dni.addListener(_onChanged);
    _pin.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _dni.dispose();
    _pin.dispose();
    super.dispose();
  }

  bool get _isReady => _dni.text.length == 8 && _pin.text.length == 6;

  void _submit() {
    context.read<AuthBloc>().add(AuthEvent.loginSubmitted(
          identifier: _dni.text.trim(),
          pin: _pin.text.trim(),
        ));
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final unauth = state is AuthUnauthenticated
                ? state
                : const AuthUnauthenticated();
            final error = unauth.error;
            final submitting = unauth.status == FormStatus.submitting;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(
                        CuyCashSpacing.containerPadding),
                    children: [
                      Text(l10n.loginHeadline,
                          style: CuyCashTypography.headlineSm),
                      const SizedBox(height: CuyCashSpacing.stackXs),
                      Text(l10n.loginSubtitle,
                          style: CuyCashTypography.bodyMd
                              .copyWith(color: CuyCashColors.secondaryText)),
                      const SizedBox(height: CuyCashSpacing.stackXl),
                      CuyCashTextField(
                        label: l10n.dniFieldLabel,
                        hint: l10n.dniHint,
                        controller: _dni,
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                      ),
                      const SizedBox(height: CuyCashSpacing.stackLg),
                      _PinField(
                        controller: _pin,
                        errorText:
                            error == null ? null : authErrorText(l10n, error),
                      ),
                      const SizedBox(height: CuyCashSpacing.stackSm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GhostButton(
                          label: l10n.forgotPin,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(height: CuyCashSpacing.stackXl),
                      PrimaryButton(
                        label: l10n.loginCta,
                        loading: submitting,
                        onPressed: _isReady ? _submit : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: CuyCashSpacing.stackLg),
                  child: GhostButton(
                    label: l10n.goToRegister,
                    onPressed: () => context.go(AppRoutes.registro),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Campo de PIN: label + 6 casillas (`PinBoxes`) con un input numérico oculto
/// que captura el teclado. Muestra [errorText] en carmín si hay error.
class _PinField extends StatelessWidget {
  const _PinField({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pinLabel, style: CuyCashTypography.labelMd),
        const SizedBox(height: CuyCashSpacing.stackSm),
        Stack(
          children: [
            PinBoxes(pin: controller.text),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: CuyCashSpacing.stackSm),
          Text(errorText!,
              style: CuyCashTypography.labelSm
                  .copyWith(color: CuyCashColors.error)),
        ],
      ],
    );
  }
}
