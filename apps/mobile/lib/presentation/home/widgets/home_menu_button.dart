import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../home_menu_option.dart';

/// Botón ⋮ del encabezado del inicio. Despliega las [HomeMenuOption]; las que
/// no aplican ahora (abrir cuenta sin cupo) salen apagadas, no ocultas, para
/// que el menú no cambie de forma.
class HomeMenuButton extends StatelessWidget {
  const HomeMenuButton({
    required this.onSelected,
    this.puedeAbrirCuenta = true,
    super.key,
  });

  final ValueChanged<HomeMenuOption> onSelected;
  final bool puedeAbrirCuenta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<HomeMenuOption>(
      tooltip: l10n.homeMenuTooltip,
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert, color: CuyCashColors.primaryContainer),
      style: IconButton.styleFrom(
        backgroundColor: CuyCashColors.surfaceContainerLowest,
        side: const BorderSide(color: CuyCashColors.divider),
        minimumSize: const Size.square(44),
      ),
      itemBuilder: (context) => [
        for (final option in HomeMenuOption.values)
          switch (option) {
            HomeMenuOption.openAccount => PopupMenuItem(
              value: option,
              enabled: puedeAbrirCuenta,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_card_outlined),
                title: Text(l10n.homeOpenAccountCta),
              ),
            ),
          },
      ],
    );
  }
}
