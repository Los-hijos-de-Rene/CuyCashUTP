import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../support/support_whatsapp_button.dart';

/// Cuál de los dos flujos se canceló. Solo cambia el copy y el destino de las
/// dos acciones: la pantalla es una sola.
enum FlujoCanceladoVariante { ingreso, recuperacion }

/// Callejón sin salida deliberado: el reto quedó invalidado y NO se ofrece
/// reenviar el código. Sin barra superior — sus dos acciones son las únicas
/// salidas.
class FlujoCanceladoScreen extends StatelessWidget {
  const FlujoCanceladoScreen({required this.variante, super.key});

  final FlujoCanceladoVariante variante;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (heading, body, reassurance, primaryLabel) = switch (variante) {
      FlujoCanceladoVariante.ingreso => (
          l10n.cancelledLoginHeadline,
          l10n.cancelledLoginBody,
          l10n.cancelledLoginReassurance,
          l10n.cancelledLoginPrimary,
        ),
      FlujoCanceladoVariante.recuperacion => (
          l10n.cancelledRecoveryHeadline,
          l10n.cancelledRecoveryBody,
          l10n.cancelledRecoveryReassurance,
          l10n.cancelledRecoveryPrimary,
        ),
    };
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
                  color: CuyCashColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_maybe_outlined,
                    size: 40, color: CuyCashColors.error),
              ),
              const SizedBox(height: CuyCashSpacing.stackLg),
              Text(heading,
                  textAlign: TextAlign.center,
                  style: CuyCashTypography.headlineSm),
              const SizedBox(height: CuyCashSpacing.stackSm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText),
              ),
              const SizedBox(height: CuyCashSpacing.stackLg),
              InfoStrip(
                icon: Icons.verified_user_outlined,
                text: reassurance,
                tone: InfoStripTone.success,
              ),
              const SizedBox(height: CuyCashSpacing.stackSm),
              InfoStrip(
                icon: Icons.mail_outline,
                text: l10n.cancelledEmailNotice,
              ),
              const Spacer(),
              PrimaryButton(
                label: primaryLabel,
                onPressed: () => context.go(_primaryRoute),
              ),
              const SizedBox(height: CuyCashSpacing.stackSm),
              switch (variante) {
                FlujoCanceladoVariante.ingreso =>
                  const SupportWhatsAppButton(),
                FlujoCanceladoVariante.recuperacion => GhostButton(
                    label: l10n.cancelledRecoverySecondary,
                    onPressed: () => context.go(AppRoutes.recuperar),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }

  String get _primaryRoute => switch (variante) {
        FlujoCanceladoVariante.ingreso => AppRoutes.login,
        FlujoCanceladoVariante.recuperacion => AppRoutes.onboarding,
      };
}
