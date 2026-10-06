import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/device/application/device_actions.dart';
import '../../feature/device/domain/remembered_user.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../auth/bloc/auth_bloc.dart';
import '../quick_access/widgets/switch_user_dialog.dart';
import '../session/remembered_user_builder.dart';
import 'widgets/profile_data_row.dart';
import 'widgets/profile_identity_card.dart';
import 'widgets/profile_option_tile.dart';

/// Perfil: identidad de la sesión (dato real del servicio de auth), datos de la
/// cuenta y cierre de sesión. Las opciones sin feature detrás lo dicen en vez de
/// no hacer nada.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _notYet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  Future<void> _signOut(BuildContext context, RememberedUser user) async {
    final authBloc = context.read<AuthBloc>();
    final device = context.read<DeviceActions>();
    final confirmed = await showSwitchUserDialog(context, name: user.firstName);
    if (confirmed != true) return;
    authBloc.add(const AuthEvent.signedOut());
    await device.clearUser();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        backgroundColor: CuyCashColors.surfaceContainerLow,
      ),
      body: RememberedUserBuilder(
        builder: (context, user) => ListView(
          padding: const EdgeInsets.fromLTRB(
            CuyCashSpacing.marginMobile,
            CuyCashSpacing.stackSm,
            CuyCashSpacing.marginMobile,
            CuyCashSpacing.stackLg,
          ),
          children: [
            ProfileIdentityCard(user: user),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _SectionTitle(l10n.profileSectionAccount),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ProfileDataRow(
                      label: l10n.profileDniLabel, value: user.dni),
                  if (user.alias.isNotEmpty) ...[
                    const Divider(height: 1, color: CuyCashColors.divider),
                    ProfileDataRow(
                        label: l10n.profileAliasLabel, value: user.alias),
                  ],
                  const Divider(height: 1, color: CuyCashColors.divider),
                  ProfileOptionTile(
                    icon: Icons.badge_outlined,
                    label: l10n.profileItemPersonalData,
                    onTap: () => context.push(AppRoutes.perfilDatos),
                  ),
                  const Divider(height: 1, color: CuyCashColors.divider),
                  ProfileOptionTile(
                    icon: Icons.alternate_email,
                    label: l10n.profileItemAlias,
                    onTap: () => _notYet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _SectionTitle(l10n.profileSectionSecurity),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ProfileOptionTile(
                    icon: Icons.password_outlined,
                    label: l10n.profileItemChangePin,
                    onTap: () => _notYet(context),
                  ),
                  const Divider(height: 1, color: CuyCashColors.divider),
                  ProfileOptionTile(
                    icon: Icons.fingerprint,
                    label: l10n.profileItemBiometrics,
                    onTap: () => _notYet(context),
                  ),
                  const Divider(height: 1, color: CuyCashColors.divider),
                  ProfileOptionTile(
                    icon: Icons.devices_outlined,
                    label: l10n.profileItemDevices,
                    onTap: () => _notYet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _SectionTitle(l10n.profileSectionSupport),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ProfileOptionTile(
                    icon: Icons.help_outline,
                    label: l10n.profileItemHelp,
                    onTap: () => _notYet(context),
                  ),
                  const Divider(height: 1, color: CuyCashColors.divider),
                  ProfileOptionTile(
                    icon: Icons.description_outlined,
                    label: l10n.profileItemTerms,
                    onTap: () => _notYet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            SecondaryButton(
              label: l10n.signOut,
              onPressed: () => _signOut(context, user),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: CuyCashSpacing.stackXs,
          bottom: CuyCashSpacing.stackSm,
        ),
        child: Text(text,
            style: CuyCashTypography.labelMd
                .copyWith(color: CuyCashColors.secondaryText)),
      );
}
