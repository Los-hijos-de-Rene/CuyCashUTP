import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/secure_screen_scope.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../pin/pin_entry_view.dart';
import 'bloc/reset_pin_bloc.dart';

/// Restablecer PIN en DOS pasos sobre la misma ruta: primero se crea, luego se
/// confirma. Una sola fila de casillas a la vez, para que el teclado propio
/// quepa siempre.
///
/// No hay botón primario: el sexto dígito es el commit. Eso libera los 52px del
/// botón y elimina un estado deshabilitado que ocupaba sitio sin hacer nada.
///
/// La barra cambia de ícono con el paso: X en el primero, porque salir es
/// abandonar la recuperación; flecha en el segundo, porque solo se vuelve a
/// elegir el PIN.
///
/// El teclado es propio a propósito (ver `PinKeypad`) y la ventana se marca
/// como segura mientras la pantalla vive, para que el PIN no acabe en una
/// captura ni en la vista de apps recientes.
class RestablecerPinScreen extends StatelessWidget {
  const RestablecerPinScreen({super.key});

  /// El paso 1 abandona el flujo (con confirmación); el paso 2 solo retrocede,
  /// porque ahí sí hay un paso al que volver.
  Future<void> _onClose(BuildContext context, ResetPinState state) async {
    if (state.step == ResetPinStep.confirmar) {
      context.read<ResetPinBloc>().add(const ResetPinEvent.backToFirstStep());
      return;
    }
    final l10n = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetPinExitTitle),
        content: Text(l10n.resetPinExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.resetPinExitConfirm),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SecureScreenScope(
      child: BlocConsumer<ResetPinBloc, ResetPinState>(
        listener: (context, state) {
          if (state.done) context.go(AppRoutes.recuperarListo);
        },
        builder: (context, state) {
          final bloc = context.read<ResetPinBloc>();
          final confirmando = state.step == ResetPinStep.confirmar;
          return PopScope(
            canPop: false,
            // El gesto de retroceso del sistema hace lo mismo que la X.
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _onClose(context, state);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.resetPinTitle),
                leading: IconButton(
                  // El ícono declara a dónde lleva: en el paso 1 se abandona
                  // el flujo (X), en el paso 2 solo se retrocede (flecha).
                  icon: Icon(confirmando ? Icons.arrow_back : Icons.close),
                  onPressed: () => _onClose(context, state),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: _StepBar(step: state.step),
                ),
              ),
              body: SafeArea(
                child: PinEntryView(
                  headline: confirmando
                      ? l10n.resetPinConfirmHeadline
                      : l10n.resetPinHeadline,
                  subtitle: confirmando
                      ? l10n.resetPinConfirmSubtitle
                      : l10n.resetPinSubtitle,
                  pin: state.pin,
                  hasError: state.hasError,
                  errorText: switch (state.error) {
                    final error? => resetPinErrorText(l10n, error),
                    null => null,
                  },
                  extra: InfoStrip(
                    icon: Icons.lock_outline,
                    text: l10n.resetPinNotice,
                  ),
                  onDigit: (digit) =>
                      bloc.add(ResetPinEvent.digitPressed(digit)),
                  onBackspace: () => bloc.add(const ResetPinEvent.backspace()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dos segmentos de 4px: el paso activo en eucalipto. Sin texto de paso.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});

  final ResetPinStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CuyCashSpacing.marginMobile,
      ),
      child: Row(
        children: [
          const Expanded(child: _Segment(active: true)),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(child: _Segment(active: step == ResetPinStep.confirmar)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active
            ? CuyCashColors.primaryContainer
            : CuyCashColors.outlineVariant,
        borderRadius: BorderRadius.circular(CuyCashRadii.full),
      ),
    );
  }
}

/// Traduce el `ResetPinError` del bloc a copy es-PE.
String resetPinErrorText(AppLocalizations l10n, ResetPinError error) =>
    switch (error) {
      ResetPinError.samePin => l10n.resetPinSamePin,
      ResetPinError.mismatch => l10n.resetPinMismatch,
      ResetPinError.weakPin => l10n.errorWeakPin,
      ResetPinError.generic => l10n.errorGeneric,
    };
