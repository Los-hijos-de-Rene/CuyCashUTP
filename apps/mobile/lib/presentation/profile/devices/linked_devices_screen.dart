import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/security/domain/linked_device.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/linked_devices_bloc.dart';
import 'widgets/linked_device_tile.dart';

/// Teléfonos con acceso a la cuenta. Desvincular cierra su sesión, revoca su
/// huella y le vuelve a pedir OTP.
class LinkedDevicesScreen extends StatelessWidget {
  const LinkedDevicesScreen({super.key});

  Future<void> _confirmUnlink(BuildContext context, LinkedDevice device) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<LinkedDevicesBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.devicesUnlinkTitle),
        content: Text(l10n.devicesUnlinkBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.devicesUnlink),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(LinkedDevicesEvent.unlinkRequested(device.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(l10n.devicesTitle),
        backgroundColor: CuyCashColors.surfaceContainerLow,
      ),
      body: BlocConsumer<LinkedDevicesBloc, LinkedDevicesState>(
        listenWhen: (p, c) => c.message != null && p.message != c.message,
        listener: (context, state) {
          final texto = switch (state.message) {
            DevicesMessage.unlinked => l10n.devicesUnlinked,
            DevicesMessage.cannotUnlinkCurrent =>
              l10n.devicesCannotUnlinkCurrent,
            DevicesMessage.error => l10n.errorGeneric,
            null => null,
          };
          if (texto == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(texto)));
        },
        builder: (context, state) => switch (state.status) {
          LinkedDevicesStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          LinkedDevicesStatus.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.devicesError, style: CuyCashTypography.bodyMd),
                  const SizedBox(height: CuyCashSpacing.stackMd),
                  SecondaryButton(
                    label: l10n.homeRetry,
                    onPressed: () => context.read<LinkedDevicesBloc>().add(
                      const LinkedDevicesEvent.started(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          LinkedDevicesStatus.ready => ListView(
            padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
            children: [
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, d) in state.devices.indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, color: CuyCashColors.divider),
                      LinkedDeviceTile(
                        device: d,
                        busy: state.unlinking == d.id,
                        onUnlink: () => _confirmUnlink(context, d),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              InfoStrip(icon: Icons.shield_outlined, text: l10n.devicesHelp),
            ],
          ),
        },
      ),
    );
  }
}
