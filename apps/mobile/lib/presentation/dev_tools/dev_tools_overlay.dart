import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../feature/dev_tools/application/dev_tools_actions.dart';
import '../../l10n/app_localizations.dart';
import 'dev_tools_sheet.dart';

/// Botón "DEV" flotante sobre TODAS las pantallas que abre el menú de
/// desarrollo. Solo se monta en el flavor `local` con `DEV_TOOLS_KEY`
/// (ver `CuyCashApp`): en `production` y `mock` no existe.
///
/// Va sobre todas las pantallas, y no escondido en un gesto de una sola, para
/// que se pueda reiniciar estando en el inicio, el perfil o a mitad del
/// registro.
class DevToolsOverlay extends StatelessWidget {
  const DevToolsOverlay({
    required this.child,
    required this.actions,
    required this.navigatorKey,
    required this.onReset,
    super.key,
  });

  final Widget child;
  final DevToolsActions actions;

  /// El navegador del router: el overlay está por ENCIMA de él, así que para
  /// abrir el panel hace falta su contexto.
  final GlobalKey<NavigatorState> navigatorKey;
  final Future<void> Function() onReset;

  void _open() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DevToolsSheet(actions: actions, onReset: onReset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        child,
        Positioned(
          left: 8,
          bottom: 120,
          child: SafeArea(
            child: Semantics(
              button: true,
              label: l10n.devToolsButton,
              child: Material(
                color: CuyCashColors.immersiveDark.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(CuyCashRadii.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(CuyCashRadii.sm),
                  onTap: _open,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      l10n.devToolsBadge,
                      style: const TextStyle(
                        color: CuyCashColors.immersiveOnDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
