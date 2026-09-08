import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/auth/application/auth_actions.dart';
import '../../feature/device/application/device_actions.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/quick_access_bloc.dart';
import 'widgets/switch_user_dialog.dart';

/// Acceso rápido para el usuario recordado en este dispositivo.
class QuickAccessScreen extends StatelessWidget {
  const QuickAccessScreen({super.key});

  Future<void> _switchUser(BuildContext context, String name) async {
    final auth = context.read<AuthActions>();
    final device = context.read<DeviceActions>();
    final router = GoRouter.of(context);
    final confirmed = await showSwitchUserDialog(context, name: name);
    if (confirmed != true) return;
    await auth.signOut();
    await device.clearUser();
    router.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      body: SafeArea(
        child: BlocConsumer<QuickAccessBloc, QuickAccessState>(
          listenWhen: (p, c) => p.lockedUntil != c.lockedUntil && c.lockedUntil != null,
          listener: (context, state) => context.go(AppRoutes.blocked),
          builder: (context, state) {
            final bloc = context.read<QuickAccessBloc>();
            final user = state.user;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(CuyCashSpacing.stackSm),
                    child: GhostButton(
                      label: l10n.notYou(user.firstName),
                      onPressed: () => _switchUser(context, user.firstName),
                    ),
                  ),
                ),
                const SizedBox(height: CuyCashSpacing.stackLg),
                InitialsAvatar(initials: user.initials),
                const SizedBox(height: CuyCashSpacing.stackMd),
                Text(l10n.quickAccessGreeting(user.firstName),
                    style: CuyCashTypography.headlineSm),
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(l10n.quickAccessPrompt,
                    style: CuyCashTypography.bodyMd
                        .copyWith(color: CuyCashColors.secondaryText)),
                const SizedBox(height: CuyCashSpacing.stackXl),
                PinDots(filled: state.pin.length),
                const SizedBox(height: CuyCashSpacing.stackLg),
                if (state.lastWrong)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile),
                    child: _ErrorBanner(
                      title: l10n.pinWrongAttempts(state.attemptsLeft),
                      hint: l10n.pinWrongHint,
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CuyCashSpacing.stackLg),
                  child: PinKeypad(
                    onDigit: (d) =>
                        bloc.add(QuickAccessEvent.digitPressed(d)),
                    onBackspace: () =>
                        bloc.add(const QuickAccessEvent.backspace()),
                    onBiometric: () =>
                        bloc.add(const QuickAccessEvent.biometric()),
                  ),
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                GhostButton(label: l10n.forgotPinAction, onPressed: () {}),
                const SizedBox(height: CuyCashSpacing.stackSm),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CuyCashColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(CuyCashRadii.input),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 18, color: CuyCashColors.error),
              const SizedBox(width: CuyCashSpacing.stackSm),
              Flexible(
                child: Text(title,
                    style: CuyCashTypography.bodyMd.copyWith(
                        color: CuyCashColors.error,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: CuyCashSpacing.stackXs),
          Text(hint,
              textAlign: TextAlign.center,
              style: CuyCashTypography.labelSm
                  .copyWith(color: CuyCashColors.secondaryText)),
        ],
      ),
    );
  }
}
