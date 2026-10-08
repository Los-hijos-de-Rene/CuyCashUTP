import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../feature/dev_tools/application/dev_tools_actions.dart';
import '../../feature/dev_tools/domain/dev_tools_repository.dart';
import '../../l10n/app_localizations.dart';

/// Panel del menú de desarrollo (solo flavor `local`).
///
/// Es una herramienta para quien desarrolla, no una pantalla del producto:
/// por eso maneja su propio estado mínimo (ocupado, resultado) en vez de un
/// bloc. Lo que hace de verdad vive en `DevToolsActions` y en el backend.
class DevToolsSheet extends StatefulWidget {
  const DevToolsSheet({
    required this.actions,
    required this.onReset,
    super.key,
  });

  final DevToolsActions actions;

  /// Tras vaciar la base: limpiar la sesión y el usuario recordado del
  /// teléfono, que ya no existen en el servidor.
  final Future<void> Function() onReset;

  @override
  State<DevToolsSheet> createState() => _DevToolsSheetState();
}

class _DevToolsSheetState extends State<DevToolsSheet> {
  bool _busy = false;
  String? _error;
  DevSeed? _seed;
  List<DevOtp>? _otps;

  Future<void> _run<T>(
    FutureResult<DevToolsFailure, T> Function() call,
    void Function(T value) onSuccess,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await call();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = false;
      result.match(
        (failure) => _error = switch (failure) {
          ServerFailure(failure: DevToolsWrongKey()) => l10n.devToolsWrongKey,
          _ => l10n.devToolsUnavailable,
        },
        onSuccess,
      );
    });
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(l10n.devToolsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.devToolsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.devToolsConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var reset = false;
    await _run(widget.actions.resetAndSeed, (seed) {
      _seed = seed;
      reset = true;
    });
    if (reset) await widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seed = _seed;
    final otps = _otps;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.devToolsTitle, style: CuyCashTypography.titleMd),
            const SizedBox(height: CuyCashSpacing.stackMd),
            PrimaryButton(
              label: l10n.devToolsReset,
              loading: _busy,
              onPressed: _busy ? null : _reset,
            ),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.devToolsResetHint, style: CuyCashTypography.labelSm),
            const SizedBox(height: CuyCashSpacing.stackMd),
            SecondaryButton(
              label: l10n.devToolsSeed,
              onPressed: _busy
                  ? null
                  : () => _run(widget.actions.seed, (s) => _seed = s),
            ),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.devToolsSeedHint, style: CuyCashTypography.labelSm),
            const SizedBox(height: CuyCashSpacing.stackMd),
            SecondaryButton(
              label: l10n.devToolsOtp,
              onPressed: _busy
                  ? null
                  : () => _run(widget.actions.latestOtps, (o) => _otps = o),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: CuyCashSpacing.stackMd),
              Text(
                error,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.error),
              ),
            ],
            if (seed != null) ...[
              const SizedBox(height: CuyCashSpacing.stackLg),
              Text(
                l10n.devToolsUsers(seed.pin),
                style: CuyCashTypography.titleMd.copyWith(fontSize: 16),
              ),
              for (final user in seed.users)
                Padding(
                  padding: const EdgeInsets.only(top: CuyCashSpacing.stackXs),
                  child: SelectableText(
                    '${user.name} · DNI ${user.dni} · ${user.alias}',
                    style: CuyCashTypography.bodyMd,
                  ),
                ),
            ],
            if (otps != null) ...[
              const SizedBox(height: CuyCashSpacing.stackLg),
              if (otps.isEmpty)
                Text(l10n.devToolsOtpEmpty, style: CuyCashTypography.bodyMd)
              else
                for (final otp in otps)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: CuyCashSpacing.stackXs),
                    child: SelectableText(
                      '${otp.code} · ${otp.destination} (${otp.purpose})',
                      style: CuyCashTypography.bodyMd,
                    ),
                  ),
            ],
            const SizedBox(height: CuyCashSpacing.stackLg),
            SelectableText(
              l10n.devToolsCommandHint,
              style: CuyCashTypography.labelSm
                  .copyWith(color: CuyCashColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
