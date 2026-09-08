import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/otp_bloc.dart';
import 'otp_config.dart';

/// Pantalla de verificación por código, compartida por la recuperación de PIN
/// y por la verificación de un teléfono nuevo. Todo lo que las distingue viaja
/// en [config] y en los callbacks: esta clase no las conoce.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.config,
    required this.onVerified,
    this.onChangeEmail,
    super.key,
  });

  final OtpConfig config;

  /// El código fue correcto y el reto quedó consumido.
  final ValueChanged<String> onVerified;

  /// Solo se ofrece si `config.allowChangeEmail`.
  final VoidCallback? onChangeEmail;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Tras un código incorrecto el bloc limpia el código: se vacía el campo y
  /// el foco vuelve a la primera casilla.
  void _syncField(OtpState state) {
    if (_controller.text != state.code) {
      _controller.value = TextEditingValue(
        text: state.code,
        selection: TextSelection.collapsed(offset: state.code.length),
      );
      if (state.code.isEmpty) _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = widget.config;

    return BlocConsumer<OtpBloc, OtpState>(
      listener: (context, state) {
        _syncField(state);
        if (state.cancelled) {
          context.go(config.cancelledRoute);
          return;
        }
        if (state.verified) widget.onVerified(state.challengeId ?? '');
      },
      builder: (context, state) {
        final bloc = context.read<OtpBloc>();
        final expired = state.codeState == OtpCodeState.expired;
        return Scaffold(
          appBar: AppBar(
            title: Text(config.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.login),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(
                        CuyCashSpacing.containerPadding),
                    children: [
                      Text(
                        config.heading,
                        textAlign: TextAlign.center,
                        style: CuyCashTypography.headlineMd,
                      ),
                      const SizedBox(height: CuyCashSpacing.stackSm),
                      Text(
                        config.subtitleBuilder(state.maskedEmail),
                        textAlign: TextAlign.center,
                        style: CuyCashTypography.bodyLg
                            .copyWith(color: CuyCashColors.secondaryText),
                      ),
                      const SizedBox(height: CuyCashSpacing.stackXl),
                      _CodeField(
                        controller: _controller,
                        focusNode: _focus,
                        code: state.code,
                        hasError: state.codeState == OtpCodeState.invalid ||
                            expired,
                        enabled: !expired,
                        onChanged: (value) =>
                            bloc.add(OtpEvent.codeChanged(value)),
                      ),
                      if (state.codeState == OtpCodeState.invalid) ...[
                        const SizedBox(height: CuyCashSpacing.stackSm),
                        Text(
                          l10n.otpWrongCode(state.attemptsLeft),
                          textAlign: TextAlign.center,
                          style: CuyCashTypography.bodyMd
                              .copyWith(color: CuyCashColors.error),
                        ),
                        const SizedBox(height: CuyCashSpacing.stackXs),
                        Text(
                          config.attemptsWarning,
                          textAlign: TextAlign.center,
                          style: CuyCashTypography.labelSm,
                        ),
                      ],
                      if (expired) ...[
                        const SizedBox(height: CuyCashSpacing.stackSm),
                        Text(
                          l10n.otpExpiredMessage,
                          textAlign: TextAlign.center,
                          style: CuyCashTypography.bodyMd
                              .copyWith(color: CuyCashColors.error),
                        ),
                      ],
                      if (config.notice case final notice?) ...[
                        const SizedBox(height: CuyCashSpacing.stackLg),
                        InfoStrip(icon: notice.icon, text: notice.text),
                      ],
                      if (state.showsResendRow) ...[
                        const SizedBox(height: CuyCashSpacing.stackLg),
                        _ResendRow(
                          state: state,
                          onResend: () =>
                              bloc.add(const OtpEvent.resendRequested()),
                        ),
                      ],
                      if (config.allowChangeEmail) ...[
                        const SizedBox(height: CuyCashSpacing.stackSm),
                        Center(
                          child: GhostButton(
                            label: l10n.otpChangeEmail,
                            onPressed: widget.onChangeEmail,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(
                      CuyCashSpacing.containerPadding),
                  child: PrimaryButton(
                    label: expired
                        ? l10n.otpRequestNewCode
                        : config.submitLabel,
                    loading: state.status != OtpStatus.idle,
                    onPressed: state.canSubmit
                        ? () => bloc.add(expired
                            ? const OtpEvent.resendRequested()
                            : const OtpEvent.submitted())
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Las seis casillas se comportan como UN solo campo: un `TextField`
/// transparente encima captura el teclado, así pegar un código de 6 dígitos
/// las llena todas, escribir avanza y el retroceso vuelve a la anterior.
class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.focusNode,
    required this.code,
    required this.hasError,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String code;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OtpBoxes(code: code, hasError: hasError),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila de reenvío. Mientras corre el enfriamiento es UNA sola línea; la
/// leyenda del spam aparece recién cuando el reenvío está disponible.
class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.state, required this.onResend});

  final OtpState state;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        switch (state.resendState) {
          OtpResendState.cooling => Text(
              l10n.otpResendIn(formatCountdown(state.cooldownRemaining)),
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.secondaryText),
            ),
          OtpResendState.available =>
            GhostButton(label: l10n.otpResendNow, onPressed: onResend),
          OtpResendState.exhausted => Text(
              l10n.otpResendNow,
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.outlineVariant),
            ),
        },
        if (state.showsSpamHint)
          Text(l10n.otpSpamHint, style: CuyCashTypography.labelSm),
      ],
    );
  }
}

/// `MM:SS` para la cuenta regresiva del reenvío.
String formatCountdown(Duration remaining) {
  final total = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
