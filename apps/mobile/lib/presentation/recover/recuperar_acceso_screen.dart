import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';

/// Paso 1 de la recuperación: un solo campo de correo.
///
/// La respuesta es IDÉNTICA exista o no la cuenta ("si el correo está
/// registrado, te enviamos un código"): decir "ese correo no existe"
/// confirmaría qué cuentas hay.
class RecuperarAccesoScreen extends StatefulWidget {
  const RecuperarAccesoScreen({super.key});

  @override
  State<RecuperarAccesoScreen> createState() => _RecuperarAccesoScreenState();
}

class _RecuperarAccesoScreenState extends State<RecuperarAccesoScreen> {
  final _email = TextEditingController();

  static final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _isValid => _emailFormat.hasMatch(_email.text.trim());

  void _submit() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.recoverNeutralNotice)));
    context.push(AppRoutes.recuperarCodigo, extra: _email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recoverTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.all(CuyCashSpacing.containerPadding),
                children: [
                  Text(l10n.recoverHeadline,
                      style: CuyCashTypography.headlineSm),
                  const SizedBox(height: CuyCashSpacing.stackXs),
                  Text(
                    l10n.recoverSubtitle,
                    style: CuyCashTypography.bodyMd
                        .copyWith(color: CuyCashColors.secondaryText),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackXl),
                  CuyCashTextField(
                    label: l10n.emailLabel,
                    hint: l10n.emailHint,
                    controller: _email,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              child: PrimaryButton(
                label: l10n.recoverCta,
                onPressed: _isValid ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
