import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import 'bloc/edit_alias_bloc.dart';

/// Editar alias: un campo con `@` fijo y validación en vivo. Cierra con
/// `pop(true)` al guardar; el perfil avisa.
class EditAliasScreen extends StatefulWidget {
  const EditAliasScreen({super.key});

  @override
  State<EditAliasScreen> createState() => _EditAliasScreenState();
}

class _EditAliasScreenState extends State<EditAliasScreen> {
  late final _controller =
      TextEditingController(text: context.read<EditAliasBloc>().state.input);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _errorText(AppLocalizations l10n, EditAliasState state) =>
      switch (state.error) {
        AliasError.invalid => l10n.aliasInvalid,
        AliasError.taken => l10n.aliasTaken,
        AliasError.network => l10n.aliasNetwork,
        AliasError.generic => l10n.errorGeneric,
        null => state.showsFormatError ? l10n.aliasInvalid : null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<EditAliasBloc, EditAliasState>(
      listenWhen: (p, c) => c.status == EditAliasStatus.saved,
      listener: (context, _) => context.pop(true),
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l10n.aliasTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CuyCashTextField(
                  label: l10n.aliasLabel,
                  controller: _controller,
                  autofocus: true,
                  prefixText: '@',
                  errorText: _errorText(l10n, state),
                  onChanged: (v) => context
                      .read<EditAliasBloc>()
                      .add(EditAliasEvent.changed(v)),
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                Text(
                  l10n.aliasHelp,
                  style: CuyCashTypography.labelSm.copyWith(
                    color: CuyCashColors.secondaryText,
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: l10n.aliasSave,
                  loading: state.status == EditAliasStatus.saving,
                  onPressed: state.canSave
                      ? () => context
                          .read<EditAliasBloc>()
                          .add(const EditAliasEvent.submitted())
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
