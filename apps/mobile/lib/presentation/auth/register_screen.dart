import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'auth_error_text.dart';
import 'bloc/auth_bloc.dart';

/// Registro stub del Sprint 1: DNI + PIN. Las pantallas reales (validación
/// DNI/rostro) llegan después.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _dni = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _dni.dispose();
    _pin.dispose();
    super.dispose();
  }

  // TODO(register-wizard): _submit será manejado por RegisterBloc (Task 3+).
  void _submit() {}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle)),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final unauth =
                state is AuthUnauthenticated ? state : const AuthUnauthenticated();
            final error = unauth.error;
            return ListView(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              children: [
                Text(l10n.registerHeadline,
                    style: CuyCashTypography.headlineMd),
                const SizedBox(height: CuyCashSpacing.stackXl),
                CuyCashTextField(
                  label: l10n.dniLabel,
                  hint: 'Ej. 12345678',
                  controller: _dni,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: CuyCashSpacing.stackLg),
                CuyCashTextField(
                  label: l10n.pinLabel,
                  hint: '****',
                  controller: _pin,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  errorText: error == null ? null : authErrorText(l10n, error),
                ),
                const SizedBox(height: CuyCashSpacing.stackXl),
                PrimaryButton(
                  label: l10n.registerCta,
                  loading: unauth.status == FormStatus.submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                GhostButton(
                  label: l10n.goToLogin,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
