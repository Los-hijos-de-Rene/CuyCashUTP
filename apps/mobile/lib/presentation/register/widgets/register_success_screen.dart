import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../feature/auth/domain/auth_session.dart';
import '../../../l10n/app_localizations.dart';

/// Pantalla de éxito tras completar el registro. Muestra el alias (copiable) y
/// la billetera; "Ir a mi cuenta" activa la sesión y "Compartir mi alias" abre
/// el share nativo.
class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({
    required this.session,
    required this.onOpenAccount,
    super.key,
  });

  final AuthSession session;
  final VoidCallback onOpenAccount;

  String get _alias => session.alias ?? '@${session.identifier}';

  /// Últimos 4 dígitos del DNI como número de billetera enmascarado (mock).
  String get _walletMasked {
    final id = session.identifier;
    final last4 = id.length >= 4 ? id.substring(id.length - 4) : id;
    return '•••• $last4';
  }

  Future<void> _copyAlias(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _alias));
    messenger.showSnackBar(SnackBar(content: Text(l10n.aliasCopied)));
  }

  Future<void> _shareAlias(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await SharePlus.instance
        .share(ShareParams(text: l10n.shareAliasMessage(_alias)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: CuyCashSpacing.marginMobile,
                    vertical: CuyCashSpacing.stackXl),
                children: [
                  const _SuccessBadge(),
                  const SizedBox(height: CuyCashSpacing.stackXl),
                  Text(l10n.successTitle,
                      textAlign: TextAlign.center,
                      style: CuyCashTypography.headlineSm),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  Text(l10n.successSubtitle,
                      textAlign: TextAlign.center,
                      style: CuyCashTypography.bodyLg
                          .copyWith(color: CuyCashColors.secondaryText)),
                  const SizedBox(height: CuyCashSpacing.stackXl),
                  _AccountCard(
                    alias: _alias,
                    walletMasked: _walletMasked,
                    aliasLabel: l10n.successAliasLabel,
                    walletLabel: l10n.successWalletLabel,
                    onCopy: () => _copyAlias(context),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  Center(child: _VerifiedBadge(label: l10n.successIdentityVerified)),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  Text(l10n.successShareHint,
                      textAlign: TextAlign.center,
                      style: CuyCashTypography.labelSm),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  CuyCashSpacing.marginMobile,
                  CuyCashSpacing.stackMd,
                  CuyCashSpacing.marginMobile,
                  CuyCashSpacing.stackLg),
              child: Column(
                children: [
                  PrimaryButton(
                      label: l10n.goToAccount, onPressed: onOpenAccount),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  GhostButton(
                    label: l10n.shareMyAlias,
                    onPressed: () => _shareAlias(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 144,
        height: 144,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _ring(144, 0.06),
            _ring(120, 0.12),
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CuyCashColors.primaryContainer,
              ),
              child: const Icon(Icons.check,
                  size: 44, color: CuyCashColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CuyCashColors.primaryContainer.withValues(alpha: opacity),
        ),
      );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.alias,
    required this.walletMasked,
    required this.aliasLabel,
    required this.walletLabel,
    required this.onCopy,
  });

  final String alias;
  final String walletMasked;
  final String aliasLabel;
  final String walletLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(aliasLabel,
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.secondaryText)),
          const SizedBox(height: CuyCashSpacing.stackXs),
          InkWell(
            onTap: onCopy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(alias, style: CuyCashTypography.headlineSm),
                const Icon(Icons.content_copy,
                    size: 20, color: CuyCashColors.primaryContainer),
              ],
            ),
          ),
          const Divider(height: CuyCashSpacing.stackLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(walletLabel,
                  style: CuyCashTypography.bodyMd
                      .copyWith(color: CuyCashColors.secondaryText)),
              Text(walletMasked,
                  style: CuyCashTypography.bodyLg
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CuyCashColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(CuyCashRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle,
              size: 14, color: CuyCashColors.primaryContainer),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Text(label.toUpperCase(),
              style: CuyCashTypography.labelSm.copyWith(
                  color: CuyCashColors.primaryContainer,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6)),
        ],
      ),
    );
  }
}
