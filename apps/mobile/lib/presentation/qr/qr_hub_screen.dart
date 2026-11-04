import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../feature/account/domain/account.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';

/// Entrada de QR desde el inicio: cobrar o pagar.
class QrHubScreen extends StatelessWidget {
  const QrHubScreen({required this.cuenta, super.key});

  final Account cuenta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrTitle)),
      body: ListView(
        padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
        children: [
          Text(l10n.qrHubHeadline, style: CuyCashTypography.headlineSm),
          const SizedBox(height: CuyCashSpacing.stackXs),
          Text(
            l10n.qrHubSubtitle,
            style: CuyCashTypography.bodyMd
                .copyWith(color: CuyCashColors.secondaryText),
          ),
          const SizedBox(height: CuyCashSpacing.stackLg),
          _QrOption(
            icon: Icons.qr_code_2,
            title: l10n.qrHubChargeTitle,
            body: l10n.qrHubChargeBody,
            onTap: () => context.push(AppRoutes.qrCobrar, extra: cuenta),
          ),
          const SizedBox(height: CuyCashSpacing.stackMd),
          _QrOption(
            icon: Icons.qr_code_scanner,
            title: l10n.qrHubPayTitle,
            body: l10n.qrHubPayBody,
            onTap: () => context.push(AppRoutes.qrPagar, extra: cuenta),
          ),
        ],
      ),
    );
  }
}

class _QrOption extends StatelessWidget {
  const _QrOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CuyCashColors.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(CuyCashRadii.input),
            ),
            child: Icon(icon, color: CuyCashColors.primaryContainer),
          ),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CuyCashTypography.bodyLg),
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(
                  body,
                  style: CuyCashTypography.bodyMd
                      .copyWith(color: CuyCashColors.secondaryText),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: CuyCashColors.secondaryText),
        ],
      ),
    );
  }
}
