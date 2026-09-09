import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/secure_screen_scope.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/register_bloc.dart';
import 'widgets/register_data_step.dart';
import 'widgets/register_document_step.dart';
import 'widgets/register_biometric_step.dart';
import 'widgets/register_face_step.dart';
import 'widgets/register_pin_confirm_step.dart';
import 'widgets/register_pin_step.dart';
import 'widgets/register_progress_bar.dart';
import 'widgets/register_success_screen.dart';

/// Wizard de registro. Chrome compartido + IndexedStack de 4 pasos. El paso 3
/// (Rostro) usa fondo oscuro inmersivo. En éxito no navega: el gate del router
/// lleva a /home cuando AuthBloc emite autenticado (sesión por el stream).
///
/// El paso 3 ya no se simula: `RegisterFaceStep` conduce el liveness real
/// contra el servicio. El IndexedStack monta todos los hijos de inmediato, así
/// que ese paso solo abre la cámara cuando tiene el DNI capturado.
class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  /// Atrás: en pasos 1-3 retrocede un paso; en el paso 0 sale del wizard
  /// (pop si hay stack, si no vuelve a onboarding — a /registro se llega con
  /// `go`, así que no siempre hay algo que popear).
  void _handleBack(BuildContext context, int step) {
    if (step > 0) {
      context.read<RegisterBloc>().add(const RegisterEvent.stepBack());
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final createdSession = state.createdSession;
        if (createdSession != null) {
          return RegisterSuccessScreen(
            session: createdSession,
            onOpenAccount: () => context.read<RegisterBloc>().add(
              const RegisterEvent.accountOpened(),
            ),
          );
        }
        final dark = state.step == 2;
        final title = switch (state.step) {
          0 => l10n.registerFlowTitle,
          1 => l10n.identityTitle,
          2 => l10n.faceTitle,
          _ => l10n.securityTitle,
        };
        final stepLabel = switch (state.step) {
          0 => l10n.stepData(1),
          1 => l10n.stepDocument(2),
          2 => l10n.stepFace(3),
          _ => l10n.stepSecurity(4),
        };
        final onSurface = dark
            ? CuyCashColors.immersiveOnDark
            : CuyCashColors.onSurface;

        return SecureScreenScope(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _handleBack(context, state.step);
            },
            child: Scaffold(
              backgroundColor: dark
                  ? CuyCashColors.immersiveDark
                  : CuyCashColors.surfaceContainerLow,
              appBar: AppBar(
                backgroundColor: dark
                    ? CuyCashColors.immersiveDark
                    : CuyCashColors.surfaceContainerLow,
                foregroundColor: onSurface,
                title: Text(
                  title,
                  style: CuyCashTypography.titleMd.copyWith(
                    color: onSurface,
                    fontSize: 18,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBack(context, state.step),
                ),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CuyCashSpacing.marginMobile,
                        0,
                        CuyCashSpacing.marginMobile,
                        CuyCashSpacing.stackLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RegisterProgressBar(step: state.step, dark: dark),
                          const SizedBox(height: CuyCashSpacing.stackSm),
                          Text(
                            stepLabel,
                            style: CuyCashTypography.labelSm.copyWith(
                              color: dark
                                  ? CuyCashColors.immersiveMuted
                                  : CuyCashColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: state.step,
                        children: [
                          const RegisterDataStep(),
                          const RegisterDocumentStep(),
                          const RegisterFaceStep(),
                          switch (state.securityStep) {
                            SecurityStep.crear => const RegisterPinStep(),
                            SecurityStep.confirmar =>
                              const RegisterPinConfirmStep(),
                            SecurityStep.biometria =>
                              const RegisterBiometricStep(),
                          },
                        ],
                      ),
                    ),
                    // Crear y confirmar el PIN avanzan con el sexto dígito: el
                    // botón solo aparece donde de verdad hay algo que pulsar.
                    if (state.step != 3 ||
                        state.securityStep == SecurityStep.biometria)
                      _Footer(state: state, dark: dark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.dark});
  final RegisterState state;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    final isLast = state.step == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CuyCashSpacing.marginMobile,
        CuyCashSpacing.stackMd,
        CuyCashSpacing.marginMobile,
        CuyCashSpacing.stackLg,
      ),
      child: PrimaryButton(
        label: isLast ? l10n.finishRegister : l10n.continueCta,
        loading: state.status == RegisterStatus.submitting,
        onPressed: state.canAdvance
            ? () => bloc.add(
                isLast
                    ? const RegisterEvent.submitted()
                    : const RegisterEvent.stepAdvanced(),
              )
            : (state.step == 0
                  ? () =>
                        bloc.add(
                          const RegisterEvent.stepAdvanced(),
                        ) // dispara validación/banner
                  : null),
      ),
    );
  }
}
