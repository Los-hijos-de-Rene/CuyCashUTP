import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/secure_screen_scope.dart';
import '../../feature/auth/application/auth_actions.dart';
import '../../feature/device/application/device_actions.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../lockout/blocked_args.dart';
import '../lockout/lockout_duration_text.dart';
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
    return SecureScreenScope(
      child: Scaffold(
        backgroundColor: CuyCashColors.surfaceContainerLow,
        body: SafeArea(
          child: BlocConsumer<QuickAccessBloc, QuickAccessState>(
            listenWhen: (p, c) =>
                (p.lockedUntil != c.lockedUntil && c.lockedUntil != null) ||
                (!p.needsDeviceVerification && c.needsDeviceVerification),
            listener: (context, state) {
              if (state.needsDeviceVerification) {
                // PIN correcto en un teléfono que ya no es de confianza: el
                // login, con el DNI puesto, corre el OTP de dispositivo.
                context.go(AppRoutes.login, extra: state.user.dni);
                return;
              }
              final lockedUntil = state.lockedUntil;
              if (lockedUntil == null) return;
              context.go(
                AppRoutes.blocked,
                // Aquí lo bloqueado es ESTE teléfono, no la cuenta.
                extra: BlockedArgs(
                  origin: BlockedOrigin.quickAccess,
                  lockedUntil: lockedUntil,
                ),
              );
            },
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
                  Text(
                    l10n.quickAccessGreeting(user.firstName),
                    style: CuyCashTypography.headlineSm,
                  ),
                  const SizedBox(height: CuyCashSpacing.stackXs),
                  Text(
                    l10n.quickAccessPrompt,
                    style: CuyCashTypography.bodyMd.copyWith(
                      color: CuyCashColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackXl),
                  PinDots(filled: state.pin.length),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  // El PIN se envía al sexto dígito, sin botón que se hunda:
                  // sin este aviso la pantalla queda igual mientras viaja la
                  // petición y el salto al inicio llega sin anunciarse.
                  if (state.status == QuickAccessStatus.verifying)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile,
                      ),
                      child: PinSubmittingNotice(
                        label: l10n.pinVerifying,
                        patienceLabel: l10n.pinVerifyingSlow,
                      ),
                    ),
                  if (state.lastWrong)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile,
                      ),
                      child: _ErrorBanner(
                        title: l10n.pinWrongAttempts(state.attemptsLeft),
                        // Sin duración conocida no se inventa una: mejor sin
                        // aviso que prometiendo una espera equivocada.
                        hint: switch (state.nextLockout) {
                          final next? => l10n.pinWrongHint(
                            lockoutDurationText(l10n, next),
                          ),
                          null => null,
                        },
                      ),
                    ),
                  if (state.unavailable)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile,
                      ),
                      child: InfoStrip(
                        icon: Icons.wifi_off,
                        text: l10n.quickAccessPinUnavailable,
                      ),
                    ),
                  if (state.biometricRevoked)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile,
                      ),
                      child: InfoStrip(
                        icon: Icons.fingerprint,
                        text: l10n.quickAccessBiometricRevoked,
                      ),
                    ),
                  if (state.biometricFailed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile,
                      ),
                      child: InfoStrip(
                        icon: Icons.fingerprint,
                        text: l10n.quickAccessBiometricFailed,
                      ),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CuyCashSpacing.stackLg,
                    ),
                    child: PinKeypad(
                      onDigit: (d) =>
                          bloc.add(QuickAccessEvent.digitPressed(d)),
                      onBackspace: () =>
                          bloc.add(const QuickAccessEvent.backspace()),
                      onBiometric: state.biometricAvailable
                          ? () => bloc.add(
                              QuickAccessEvent.biometric(
                                reason: l10n.quickAccessBiometricReason,
                              ),
                            )
                          : null,
                      enabled: state.status != QuickAccessStatus.verifying,
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
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, this.hint});
  final String title;
  final String? hint;

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
              const Icon(
                Icons.error_outline,
                size: 18,
                color: CuyCashColors.error,
              ),
              const SizedBox(width: CuyCashSpacing.stackSm),
              Flexible(
                child: Text(
                  title,
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hint case final hint?) ...[
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: CuyCashTypography.labelSm.copyWith(
                color: CuyCashColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
