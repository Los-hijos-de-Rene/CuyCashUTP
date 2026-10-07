import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/account/domain/account.dart';
import '../../../l10n/app_localizations.dart';
import 'add_account_card.dart';
import 'balance_card.dart';

/// Las cuentas del titular, una por página, y al final "Abrir otra cuenta".
///
/// La página visible la manda [seleccionada] (el bloc): si cambia desde
/// fuera (cuenta recién abierta), el carrusel salta a ella.
class AccountCarousel extends StatefulWidget {
  const AccountCarousel({
    required this.cuentas,
    required this.seleccionada,
    required this.onSelected,
    required this.onRename,
    this.onOpenAccount,
    super.key,
  });

  final List<Account> cuentas;
  final int seleccionada;
  final ValueChanged<int> onSelected;
  final ValueChanged<Account> onRename;

  /// `null` = ya no se puede abrir otra (tope): no hay última página.
  final VoidCallback? onOpenAccount;

  /// Alto fijo: un `PageView` necesita uno, y todas las tarjetas miden igual.
  static const height = 176.0;

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  late final PageController _controller = PageController(
    initialPage: widget.seleccionada,
  );
  late int _pagina = widget.seleccionada;

  /// Hay un `animateToPage` propio en curso: sus páginas intermedias no son
  /// una elección del titular.
  bool _animando = false;

  @override
  void didUpdateWidget(AccountCarousel old) {
    super.didUpdateWidget(old);
    // Solo un cambio externo de la selección mueve el carrusel; un rebuild
    // con la misma selección no debe sacarlo de la página de "abrir".
    if (widget.seleccionada != old.seleccionada &&
        widget.seleccionada != _pagina &&
        _controller.hasClients) {
      _pagina = widget.seleccionada;
      _animar(widget.seleccionada);
    }
  }

  Future<void> _animar(int pagina) async {
    _animando = true;
    try {
      await _controller.animateToPage(
        pagina,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } finally {
      _animando = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final abrir = widget.onOpenAccount;
    final paginas = widget.cuentas.length + (abrir == null ? 0 : 1);
    return Column(
      children: [
        SizedBox(
          height: AccountCarousel.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: paginas,
            onPageChanged: (i) {
              setState(() => _pagina = i);
              // La página de "abrir" no es una cuenta: no cambia la selección.
              if (!_animando && i < widget.cuentas.length) widget.onSelected(i);
            },
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CuyCashSpacing.stackXs,
              ),
              child: i < widget.cuentas.length
                  ? BalanceCard(
                      cuenta: widget.cuentas[i],
                      onRename: () => widget.onRename(widget.cuentas[i]),
                    )
                  : switch (abrir) {
                      final VoidCallback f => AddAccountCard(onTap: f),
                      null => const SizedBox.shrink(),
                    },
            ),
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        Semantics(
          label: l10n.homeAccountPage(
            _pagina.clamp(0, widget.cuentas.length - 1) + 1,
            widget.cuentas.length,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < paginas; i++)
                  Container(
                    width: i == _pagina ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _pagina
                          ? CuyCashColors.primary
                          : CuyCashColors.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
