import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/account/domain/account.dart';
import '../../../feature/account/domain/account_limits.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/account_bloc.dart';

/// Hoja para poner o quitar el nombre de una cuenta. Despacha al
/// [AccountBloc] y se cierra cuando el cambio se guardó; si falla, lo dice y
/// se queda.
class RenameAccountSheet extends StatefulWidget {
  const RenameAccountSheet({required this.cuenta, super.key});

  final Account cuenta;

  static Future<void> show(BuildContext context, Account cuenta) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => BlocProvider.value(
          value: context.read<AccountBloc>(),
          child: RenameAccountSheet(cuenta: cuenta),
        ),
      );

  @override
  State<RenameAccountSheet> createState() => _RenameAccountSheetState();
}

class _RenameAccountSheetState extends State<RenameAccountSheet> {
  late final _controller = TextEditingController(
    text: widget.cuenta.nombre ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Hubo un intento desde esta hoja: un fallo viejo del bloc no se muestra.
  bool _intentado = false;

  void _guardar(String? nombre) {
    setState(() => _intentado = true);
    context.read<AccountBloc>().add(
      AccountEvent.renameRequested(cuentaId: widget.cuenta.id, nombre: nombre),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen: (a, b) => a.renaming && !b.renaming,
      listener: (context, state) {
        if (!_intentado || state.renameFailure == null)
          Navigator.of(context).pop();
      },
      builder: (context, state) {
        final largo =
            _controller.text.trim().length > AccountLimits.nombreMaxLength;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            CuyCashSpacing.marginMobile,
            CuyCashSpacing.stackMd,
            CuyCashSpacing.marginMobile,
            MediaQuery.viewInsetsOf(context).bottom + CuyCashSpacing.stackMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.renameAccountTitle, style: CuyCashTypography.titleMd),
              const SizedBox(height: CuyCashSpacing.stackMd),
              CuyCashTextField(
                label: l10n.renameAccountTitle,
                hint: l10n.renameAccountHint,
                controller: _controller,
                autofocus: true,
                maxLength: AccountLimits.nombreMaxLength,
                onChanged: (_) => setState(() {}),
                errorText: largo
                    ? l10n.renameAccountTooLong
                    : (!_intentado || state.renameFailure == null
                          ? null
                          : l10n.renameAccountError),
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              PrimaryButton(
                label: l10n.renameAccountSave,
                loading: state.renaming,
                onPressed: largo || state.renaming
                    ? null
                    : () => _guardar(_controller.text),
              ),
              if (widget.cuenta.nombre != null) ...[
                const SizedBox(height: CuyCashSpacing.stackSm),
                SecondaryButton(
                  label: l10n.renameAccountClear,
                  onPressed: state.renaming ? null : () => _guardar(null),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
