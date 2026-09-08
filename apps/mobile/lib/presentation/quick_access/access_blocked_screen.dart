import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Pantalla de acceso bloqueado con cuenta regresiva hasta [lockedUntil].
/// Al expirar invoca [onExpired] (el router decide a dónde volver).
class AccessBlockedScreen extends StatefulWidget {
  const AccessBlockedScreen({
    required this.lockedUntil,
    this.onExpired,
    super.key,
  });

  final DateTime lockedUntil;
  final VoidCallback? onExpired;

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
        widget.onExpired?.call();
      }
      if (mounted) setState(() => _remaining = left);
    });
  }

  Duration _computeRemaining() {
    final left = widget.lockedUntil.difference(DateTime.now());
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
              PrimaryButton(label: l10n.blockedRecoverPin, onPressed: () {}),
              const SizedBox(height: CuyCashSpacing.stackSm),
              GhostButton(label: l10n.blockedSupport, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
