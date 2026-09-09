import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/device/domain/remembered_user.dart';
import '../../../l10n/app_localizations.dart';

/// Cabecera del perfil: quién eres según el servicio de identidad.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({required this.user, super.key});

  final RememberedUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = user.fullName.trim().isEmpty
        ? l10n.profileHeadlineFallback
        : user.fullName.trim();
    return SurfaceCard(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      child: Column(
        children: [
          InitialsAvatar(initials: user.initials),
          const SizedBox(height: CuyCashSpacing.stackMd),
          Text(name,
              textAlign: TextAlign.center,
              style: CuyCashTypography.headlineSm),
          if (user.alias.isNotEmpty) ...[
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(user.alias,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.accentText)),
          ],
          const SizedBox(height: CuyCashSpacing.stackMd),
          InfoStrip(
            icon: Icons.verified_user_outlined,
            text: l10n.profileVerified,
            tone: InfoStripTone.success,
          ),
        ],
      ),
    );
  }
}
