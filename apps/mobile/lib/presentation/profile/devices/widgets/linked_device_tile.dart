import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../feature/security/domain/linked_device.dart';
import '../../../../l10n/app_localizations.dart';

/// Una fila de "Dispositivos vinculados". Sin acción en este teléfono.
class LinkedDeviceTile extends StatelessWidget {
  const LinkedDeviceTile({
    required this.device,
    required this.busy,
    this.onUnlink,
    super.key,
  });

  final LinkedDevice device;
  final bool busy;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fecha = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      child: Row(
        children: [
          Icon(
            device.plataforma == 'ios'
                ? Icons.phone_iphone
                : Icons.phone_android,
            color: CuyCashColors.primaryContainer,
          ),
          const SizedBox(width: CuyCashSpacing.stackSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.esEste
                      ? l10n.devicesThisPhone
                      : device.nombre ?? l10n.devicesUnknownModel,
                  style: CuyCashTypography.labelMd,
                ),
                if (device.esEste && device.nombre != null)
                  Text(device.nombre ?? '', style: CuyCashTypography.labelSm),
                Text(
                  l10n.devicesLinkedOn(
                    fecha.format(device.vinculadoEl.toLocal()),
                  ),
                  style: CuyCashTypography.labelSm,
                ),
                Text(
                  l10n.devicesLastUse(fecha.format(device.ultimoUso.toLocal())),
                  style: CuyCashTypography.labelSm,
                ),
                if (device.conHuella)
                  Row(
                    children: [
                      const Icon(
                        Icons.fingerprint,
                        size: 14,
                        color: CuyCashColors.success,
                      ),
                      const SizedBox(width: CuyCashSpacing.stackXs),
                      Text(
                        l10n.devicesBiometric,
                        style: CuyCashTypography.labelSm,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!device.esEste)
            busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : GhostButton(label: l10n.devicesUnlink, onPressed: onUnlink),
        ],
      ),
    );
  }
}
