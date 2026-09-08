import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../support/support_whatsapp_button.dart';
import 'blocked_args.dart';

/// ÚNICA pantalla de bloqueo del sistema: sirve a los dos orígenes, fallar el
/// PIN en acceso rápido o fallarlo en iniciar sesión. Lo que se bloqueó es
/// distinto en cada caso ([BlockedOrigin]), y de ahí depende a dónde se vuelve.
///
/// Al llegar a 00:00 NO se queda con el contador en cero y un botón muerto:
/// avisa por [onExpired] con su origen para regresar al punto de entrada.
class AccessBlockedScreen extends StatefulWidget {
  const AccessBlockedScreen({
    required this.lockedUntil,
    required this.origin,
    this.onExpired,
    this.onRecoverPin,
    this.clock,
    super.key,
  });

  final DateTime lockedUntil;

  /// De dónde vino el bloqueo; decide el regreso al expirar.
  final BlockedOrigin origin;

  /// Se invoca una sola vez, al agotarse la cuenta regresiva.
  final ValueChanged<BlockedOrigin>? onExpired;

  /// Reloj de la cuenta regresiva. Inyectable para poder adelantarlo en los
  /// tests sin esperar el bloqueo real.
  final DateTime Function()? clock;

  /// Única salida real mientras corre el bloqueo: recuperar el PIN.
  final VoidCallback? onRecoverPin;

  @override
  State<AccessBlockedScreen> createState() => _AccessBlockedScreenState();
}

class _AccessBlockedScreenState extends State<AccessBlockedScreen> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _computeRemaining();
      if (left <= Duration.zero) {
        _timer?.cancel();
        widget.onExpired?.call(widget.origin);
      }
      if (mounted) setState(() => _remaining = left);
    });
  }

  DateTime _now() => (widget.clock ?? DateTime.now)();

  Duration _computeRemaining() {
    final left = widget.lockedUntil.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final totalMinutes = _remaining.inMinutes;
    final hours = _remaining.inHours;
    if (hours >= 1) {
      final mm = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
      return '${hours.toString().padLeft(2, '0')}:$mm';
    }
    final mm = totalMinutes.toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CuyCashColors.error.withValues(alpha: 0.10)),
                child: const Icon(Icons.lock_outline,
                    size: 36, color: CuyCashColors.error),
              ),
              const SizedBox(height: CuyCashSpacing.stackLg),
              Text(l10n.blockedTitle,
                  textAlign: TextAlign.center,
                  style: CuyCashTypography.headlineSm),
              const SizedBox(height: CuyCashSpacing.stackSm),
              Text(l10n.blockedSubtitle,
                  textAlign: TextAlign.center,
                  style: CuyCashTypography.bodyLg
                      .copyWith(color: CuyCashColors.secondaryText)),
              const SizedBox(height: CuyCashSpacing.stackXl),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CuyCashColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(CuyCashRadii.card),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(l10n.blockedCountdownLabel,
                          style: CuyCashTypography.bodyMd
                              .copyWith(color: CuyCashColors.secondaryText)),
                    ),
                    Text(_formatted,
                        style: CuyCashTypography.headlineMd.copyWith(
                            color: CuyCashColors.primaryContainer,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                  label: l10n.blockedRecoverPin,
                  onPressed: widget.onRecoverPin),
              const SizedBox(height: CuyCashSpacing.stackSm),
              const SupportWhatsAppButton(),
            ],
          ),
        ),
      ),
    );
  }
}
