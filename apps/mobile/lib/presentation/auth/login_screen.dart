import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'auth_error_text.dart';
import 'bloc/auth_bloc.dart';

/// Login con DNI/Alias + PIN.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(AuthEvent.loginSubmitted(
          identifier: _identifier.text.trim(),
          pin: _pin.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final unauth =
                state is AuthUnauthenticated ? state : const AuthUnauthenticated();
            final error = unauth.error;
            return ListView(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              children: [
                Text(l10n.loginHeadline,
                    style: CuyCashTypography.headlineMd),
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(l10n.loginSubtitle, style: CuyCashTypography.bodyMd),
                const SizedBox(height: CuyCashSpacing.stackXl),
                CuyCashTextField(
                  label: l10n.identifierLabel,
                  hint: 'Ej. 12345678',
                  controller: _identifier,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: CuyCashSpacing.stackLg),
                CuyCashTextField(
                  label: l10n.pinLabel,
                  hint: '••••••',
                  controller: _pin,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  errorText: error == null ? null : authErrorText(l10n, error),
                ),
                const SizedBox(height: CuyCashSpacing.stackXl),
                PrimaryButton(
                  label: l10n.loginCta,
                  loading: unauth.status == FormStatus.submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                GhostButton(
                  label: l10n.goToRegister,
                  onPressed: () => context.go(AppRoutes.registro),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
