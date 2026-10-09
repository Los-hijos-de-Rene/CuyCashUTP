import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/account/domain/account.dart';
import '../../../l10n/app_localizations.dart';
import 'balance_card.dart';
import 'open_account_card.dart';

/// Las cuentas del titular, una por página. Tocar una abre sus movimientos.
/// Con [onOpenNew] (hay cupo), la última página es "Abrir otra cuenta": esa
/// página no es una cuenta, así que detenerse en ella no cambia la
/// seleccionada.
///
/// La página visible la manda [seleccionada] (el bloc): si cambia desde
/// fuera (cuenta recién abierta), el carrusel salta a ella.
class AccountCarousel extends StatefulWidget {
  const AccountCarousel({
    required this.cuentas,
    required this.seleccionada,
    required this.onSelected,
    required this.onRename,
    required this.onOpen,
    this.onOpenNew,
    super.key,
  });

  final List<Account> cuentas;
  final int seleccionada;
  final ValueChanged<int> onSelected;
  final ValueChanged<Account> onRename;

  /// Tocar la tarjeta de una cuenta.
  final ValueChanged<Account> onOpen;

  /// `null` = sin tarjeta "Abrir otra cuenta" (no queda cupo).
  final VoidCallback? onOpenNew;

  /// Alto fijo: un `PageView` necesita uno, y todas las tarjetas miden igual.
  static const height = 176.0;

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  late final PageController _controller = PageController(
    initialPage: widget.seleccionada,
    // La siguiente tarjeta asoma un poco: es la pista de que hay más.
    viewportFraction: 0.92,
  );
  late int _pagina = widget.seleccionada;

  /// Hay un `animateToPage` propio en curso: sus páginas intermedias no son
  /// una elección del titular.
  bool _animando = false;

  @override
  void didUpdateWidget(AccountCarousel old) {
    super.didUpdateWidget(old);
    // Solo un cambio externo de la selección mueve el carrusel; un rebuild
    // con la misma selección no debe devolverlo a otra página.
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
    final onOpenNew = widget.onOpenNew;
    final paginas = widget.cuentas.length + (onOpenNew == null ? 0 : 1);

    Widget pagina(int i) => i < widget.cuentas.length
        ? BalanceCard(
            cuenta: widget.cuentas[i],
            onRename: () => widget.onRename(widget.cuentas[i]),
            onTap: () => widget.onOpen(widget.cuentas[i]),
          )
        : OpenAccountCard(onTap: onOpenNew ?? () {});

    // Una sola tarjeta: a todo el ancho, no hay nada que deslizar.
    if (paginas == 1) {
      return SizedBox(height: AccountCarousel.height, child: pagina(0));
    }

    // Sin puntos de página: la siguiente tarjeta asoma por el borde y eso ya
    // invita a deslizar. El lector de pantalla sí recibe en qué página está.
    return Semantics(
      label: l10n.homeAccountPage(_pagina.clamp(0, paginas - 1) + 1, paginas),
      child: SizedBox(
        height: AccountCarousel.height,
        child: PageView.builder(
          controller: _controller,
          // Pegadas a la izquierda, alineadas con el resto de Inicio: lo que
          // asoma queda a la derecha.
          padEnds: false,
          itemCount: paginas,
          onPageChanged: (i) {
            setState(() => _pagina = i);
            if (!_animando && i < widget.cuentas.length) widget.onSelected(i);
          },
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(right: CuyCashSpacing.stackSm),
            child: pagina(i),
          ),
        ),
      ),
    );
  }
}
