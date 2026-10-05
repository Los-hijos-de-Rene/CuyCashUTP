import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/account/domain/account.dart';
import '../../feature/transfer/domain/recipient.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/transfer_bloc.dart';
import 'transfer_error_text.dart';

/// Paso 1 del envío: a quién. Al completar los 8 dígitos del DNI se resuelve
/// contra el backend, que devuelve el nombre ENMASCARADO.
class RecipientScreen extends StatefulWidget {
  const RecipientScreen({required this.cuenta, this.frecuentes, super.key});

  /// Cuenta de origen: la que el inicio ya muestra.
  final Account cuenta;

  /// Hueco de la fila de "Frecuentes". `feature/beneficiary` nace en la tarea
  /// 16; hasta entonces queda vacío y nada lo rellena.
  final Widget? frecuentes;

  @override
  State<RecipientScreen> createState() => _RecipientScreenState();
}

class _RecipientScreenState extends State<RecipientScreen> {
  static const _dniLength = 8;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TransferBloc>().add(TransferEvent.started(widget.cuenta));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String dni) {
    final bloc = context.read<TransferBloc>();
    if (dni.length == _dniLength) {
      bloc.add(TransferEvent.recipientRequested(dni));
    } else if (bloc.state.status != TransferStatus.idle ||
        bloc.state.failure != null) {
      bloc.add(const TransferEvent.recipientCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferRecipientTitle)),
      body: SafeArea(
        child: BlocBuilder<TransferBloc, TransferState>(
          builder: (context, state) {
            final failure = state.failure;
            final destinatario = state.destinatario;
            return Padding(
              padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.transferRecipientHeadline,
                    style: CuyCashTypography.headlineSm,
                  ),
                  const SizedBox(height: CuyCashSpacing.stackXs),
                  Text(
                    l10n.transferRecipientSubtitle,
                    style: CuyCashTypography.bodyLg.copyWith(
                      color: CuyCashColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    label: l10n.transferDniLabel,
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: _dniLength,
                    autofocus: true,
                    prefixIcon: Icons.badge_outlined,
                    onChanged: _onChanged,
                    errorText: failure == null
                        ? null
                        : transferResolveErrorText(l10n, failure),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackMd),
                  if (state.status == TransferStatus.resolving)
                    Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: l10n.transferSearching,
                      ),
                    ),
                  if (destinatario != null)
                    _RecipientCard(recipient: destinatario),
                  ?widget.frecuentes,
                  const Spacer(),
                  PrimaryButton(
                    label: l10n.transferContinue,
                    onPressed: destinatario == null
                        ? null
                        : () => context.push(AppRoutes.enviarMonto),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.recipient});

  final Recipient recipient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SurfaceCard(
      child: Row(
        children: [
          InitialsAvatar(
            initials: recipient.nombreEnmascarado.isEmpty
                ? ''
                : recipient.nombreEnmascarado.substring(0, 1),
            size: 44,
          ),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.nombreEnmascarado,
                  style: CuyCashTypography.titleMd,
                ),
                Text(
                  l10n.transferRecipientAccount(recipient.cuentaDestinoMasked),
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
