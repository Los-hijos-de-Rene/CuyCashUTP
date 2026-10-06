import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/security/secure_screen_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../../pin/pin_entry_view.dart';
import 'bloc/biometric_settings_bloc.dart';

/// Acceso biométrico: un interruptor. Encender pide el PIN (aquí, con
/// `PinEntryView`) y después la huella del sistema.
///
/// [onLocked] lo provee el router: cerrar la sesión y llevar a `/bloqueado`
/// no es asunto de esta pantalla.
class BiometricSettingsScreen extends StatelessWidget {
  const BiometricSettingsScreen({required this.onLocked, super.key});

  final void Function(DateTime until) onLocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<BiometricSettingsBloc, BiometricSettingsState>(
      listener: (context, state) {
        if (state.lockedUntil case final until?) onLocked(until);
        if (state.justEnabled) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.biometricSettingsEnabled)),
            );
        }
      },
      listenWhen: (p, c) =>
          p.lockedUntil != c.lockedUntil || (!p.justEnabled && c.justEnabled),
      builder: (context, state) {
        final bloc = context.read<BiometricSettingsBloc>();
        final pidiendoPin =
            state.status == BiometricSettingsStatus.askingPin ||
            (state.status == BiometricSettingsStatus.working &&
                state.pin.length == 6);
        if (pidiendoPin) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                bloc.add(const BiometricSettingsEvent.pinCancelled());
              }
            },
            child: SecureScreenScope(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(l10n.biometricSettingsTitle),
                  leading: BackButton(
                    onPressed: () =>
                        bloc.add(const BiometricSettingsEvent.pinCancelled()),
                  ),
                ),
                body: SafeArea(
                  child: PinEntryView(
                    headline: l10n.biometricSettingsPinHeadline,
                    subtitle: l10n.biometricSettingsPinSubtitle,
                    pin: state.pin,
                    hasError: state.error == BiometricSettingsError.wrongPin,
                    errorText: state.error == BiometricSettingsError.wrongPin
                        ? l10n.biometricSettingsWrong(state.attemptsLeft ?? 0)
                        : null,
                    onDigit: (d) => bloc.add(
                      BiometricSettingsEvent.pinDigit(
                        d,
                        reason: l10n.biometricSettingsReason,
                      ),
                    ),
                    onBackspace: () =>
                        bloc.add(const BiometricSettingsEvent.pinBackspace()),
                  ),
                ),
              ),
            ),
          );
        }
        final listo = state.status == BiometricSettingsStatus.ready;
        return Scaffold(
          backgroundColor: CuyCashColors.surfaceContainerLow,
          appBar: AppBar(
            title: Text(l10n.biometricSettingsTitle),
            backgroundColor: CuyCashColors.surfaceContainerLow,
          ),
          body: ListView(
            padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
            children: [
              SurfaceCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      color: CuyCashColors.primaryContainer,
                    ),
                    const SizedBox(width: CuyCashSpacing.stackSm + 4),
                    Expanded(
                      child: Text(
                        l10n.biometricSettingsSwitch,
                        style: CuyCashTypography.labelMd,
                      ),
                    ),
                    Switch(
                      value: state.enabled,
                      onChanged: listo && (state.available || state.enabled)
                          ? (on) => bloc.add(
                              on
                                  ? const BiometricSettingsEvent.enableRequested()
                                  : const BiometricSettingsEvent.disableRequested(),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              InfoStrip(
                icon: Icons.info_outline,
                text:
                    state.available ||
                        state.status == BiometricSettingsStatus.loading
                    ? l10n.biometricSettingsBody
                    : l10n.biometricSettingsUnavailable,
              ),
              if (state.error == BiometricSettingsError.generic) ...[
                const SizedBox(height: CuyCashSpacing.stackSm),
                Text(
                  l10n.errorGeneric,
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.error,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
