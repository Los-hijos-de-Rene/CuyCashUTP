import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/secure_screen_scope.dart';
import '../../../feature/auth/domain/pin_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../../pin/pin_entry_view.dart';
import 'bloc/change_pin_bloc.dart';

/// Cambiar el PIN: tres pasos sobre la misma ruta, con la mecánica de
/// `RestablecerPinScreen` (`PinEntryView`, sexto dígito = avanzar).
///
/// [onLocked] lo provee el router: cerrar la sesión y llevar a `/bloqueado`
/// no es asunto de esta pantalla.
class ChangePinScreen extends StatelessWidget {
  const ChangePinScreen({required this.onLocked, super.key});

  final void Function(DateTime until) onLocked;

  String? _errorText(AppLocalizations l10n, ChangePinState s) =>
      switch (s.error) {
        ChangePinError.wrongPin => l10n.changePinWrong(s.attemptsLeft ?? 0),
        ChangePinError.weakPin => l10n.errorWeakPin,
        ChangePinError.samePin => l10n.resetPinSamePin,
        ChangePinError.mismatch => l10n.resetPinMismatch,
        ChangePinError.unknownOutcome => l10n.changePinUnknown,
        ChangePinError.generic => l10n.errorGeneric,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SecureScreenScope(
      child: BlocConsumer<ChangePinBloc, ChangePinState>(
        listenWhen: (p, c) => p.lockedUntil != c.lockedUntil,
        listener: (context, state) {
          if (state.lockedUntil case final until?) onLocked(until);
        },
        builder: (context, state) {
          final bloc = context.read<ChangePinBloc>();
          if (state.status == ChangePinStatus.done) {
            return _DoneView(revoked: state.revokedSessions);
          }
          final enActual = state.step == ChangePinStep.actual;
          return PopScope(
            canPop: enActual && state.status == ChangePinStatus.idle,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) bloc.add(const ChangePinEvent.back());
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.changePinTitle),
                leading: BackButton(
                  onPressed: () => enActual
                      ? context.pop()
                      : bloc.add(const ChangePinEvent.back()),
                ),
              ),
              body: SafeArea(
                child: PinEntryView(
                  headline: switch (state.step) {
                    ChangePinStep.actual => l10n.changePinCurrentHeadline,
                    ChangePinStep.nuevo => l10n.changePinNewHeadline,
                    ChangePinStep.confirmar => l10n.changePinConfirmHeadline,
                  },
                  subtitle: switch (state.step) {
                    ChangePinStep.actual => l10n.changePinCurrentSubtitle,
                    ChangePinStep.nuevo => l10n.changePinNewSubtitle,
                    ChangePinStep.confirmar => l10n.changePinConfirmSubtitle,
                  },
                  pin: state.pin,
                  hasError: state.error != null,
                  errorText: _errorText(l10n, state),
                  rules: state.step == ChangePinStep.nuevo
                      ? [
                          PinRule(
                            label: l10n.pinRule6,
                            done: PinRules.hasSixDigits(state.pin),
                          ),
                          PinRule(
                            label: l10n.pinRuleNoRepeats,
                            done: PinRules.hasNoRepeatedDigit(state.pin),
                          ),
                          PinRule(
                            label: l10n.pinRuleNoSequence,
                            done: PinRules.hasNoSequence(state.pin),
                          ),
                        ]
                      : const [],
                  extra: state.status == ChangePinStatus.submitting
                      ? PinSubmittingNotice(
                          label: l10n.pinVerifying,
                          patienceLabel: l10n.pinVerifyingSlow,
                        )
                      : null,
                  onDigit: (d) => bloc.add(ChangePinEvent.digitPressed(d)),
                  onBackspace: () => bloc.add(const ChangePinEvent.backspace()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.revoked});

  final int revoked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 56,
                color: CuyCashColors.success,
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              Text(
                l10n.changePinDoneTitle,
                style: CuyCashTypography.headlineSm,
              ),
              const SizedBox(height: CuyCashSpacing.stackXs),
              Text(
                l10n.changePinDoneOthers(revoked),
                style: CuyCashTypography.bodyLg,
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.changePinDoneCta,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
