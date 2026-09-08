import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';

/// Confirmación del cambio de PIN. Sin barra superior: el flujo terminó.
///
/// NO auto-loguea. Restablecer no otorga sesión: que el usuario entre con el
/// PIN nuevo es la prueba de que lo recuerda.
class PinActualizadoScreen extends StatelessWidget {
  const PinActualizadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: CuyCashColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 40, color: CuyCashColors.success),
              ),
              const SizedBox(height: CuyCashSpacing.stackLg),
              Text(
                l10n.pinUpdatedHeadline,
                textAlign: TextAlign.center,
                style: CuyCashTypography.headlineSm,
              ),
              const SizedBox(height: CuyCashSpacing.stackSm),
              Text(
                l10n.pinUpdatedBody,
                textAlign: TextAlign.center,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText),
              ),
              const SizedBox(height: CuyCashSpacing.stackLg),
              InfoStrip(
                icon: Icons.devices_outlined,
                text: l10n.pinUpdatedSessionsNotice,
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.pinUpdatedCta,
                onPressed: () => context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
