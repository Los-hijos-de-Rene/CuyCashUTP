import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';

/// Perfil: muestra el identificador de la sesión y permite cerrar sesión.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AuthBloc>().state;
    final identifier =
        state is AuthAuthenticated ? state.session.identifier : '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: Padding(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profileIdentifierLabel,
                style: CuyCashTypography.labelMd),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(identifier, style: CuyCashTypography.titleMd),
            const Spacer(),
            SecondaryButton(
              label: l10n.signOut,
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthEvent.signedOut()),
            ),
          ],
        ),
      ),
    );
  }
}
