import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/account/domain/account.dart';
import '../../feature/beneficiary/domain/beneficiary.dart';
import '../../feature/transfer/domain/recipient.dart';
import '../../feature/transfer/domain/recipient_account.dart';
import '../../feature/transfer/domain/recipient_directory.dart';
import '../../feature/transfer/domain/recipient_query.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_label.dart';
import '../app/app_routes.dart';
import 'bloc/transfer_bloc.dart';
import 'transfer_error_text.dart';
import 'widgets/recipient_account_card.dart';
import 'widgets/recipient_skeleton.dart';

/// Paso 1 del envío: a qué cuenta. Se busca por DNI (al completar los 8
/// dígitos) o por alias (con "Buscar" o la tecla del teclado: no se busca
/// letra a letra porque cada consulta gasta del cupo). Se listan sus cuentas;
/// tocar una pasa al monto. Un frecuente con cuenta pasa directo.
class RecipientScreen extends StatefulWidget {
  const RecipientScreen({required this.cuenta, this.frecuentes, super.key});

  /// Cuenta de origen: la que el inicio ya muestra.
  final Account cuenta;

  /// Fila de "Frecuentes". Recibe qué hacer al tocar uno: ir directo al monto
  /// si trae cuenta, o rellenar el DNI y buscar. Sin ella no hay fila.
  final Widget Function(ValueChanged<Beneficiary> onSelected)? frecuentes;

  @override
  State<RecipientScreen> createState() => _RecipientScreenState();
}

class _RecipientScreenState extends State<RecipientScreen> {
  static const _dniLength = 8;

  /// `@` + 20 del alias más largo.
  static const _maxLength = 21;
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

  void _onChanged(String texto) {
    // Redibuja "Buscar", que depende de si lo escrito ya es un alias válido.
    setState(() {});
    final bloc = context.read<TransferBloc>();
    if (RecipientQuery.looksLikeDni(texto) &&
        texto.trim().length == _dniLength) {
      bloc.add(TransferEvent.recipientRequested(texto));
    } else if (bloc.state.status != TransferStatus.idle ||
        bloc.state.failure != null) {
      bloc.add(const TransferEvent.recipientCleared());
    }
  }

  /// "Buscar" o la tecla del teclado. Un DNI completo ya se buscó solo.
  void _onSearch() {
    final texto = _controller.text;
    if (RecipientQuery.parse(texto) is AliasQuery) {
      context.read<TransferBloc>().add(TransferEvent.recipientRequested(texto));
    }
  }

  /// Un frecuente que ya trae su cuenta pasa directo al monto, sin consultar
  /// (no gasta presupuesto). Sin cuenta (dejó de recibir), es teclear su DNI.
  void _onFrequentSelected(Beneficiary b) {
    final bloc = context.read<TransferBloc>();
    // Con el envío sellado el bloc ignora los cambios: no tocar el campo ni
    // navegar a un monto que seguiría mostrando el destinatario anterior.
    if (bloc.intentSealed) return;
    final origen = bloc.state.cuenta;
    switch (b.cuenta) {
      case final RecipientAccount c
          when origen != null && c.moneda != origen.moneda:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).transferFrequentOtherCurrency(c.moneda.symbol),
              ),
            ),
          );
      case final RecipientAccount c when c.cuentaId == origen?.id:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).transferFrequentIsOrigin,
              ),
            ),
          );
      case final RecipientAccount c:
        // Al volver del monto no deben quedar el DNI ni las tarjetas de una
        // búsqueda anterior: se limpia ANTES de elegir (limpiar borra el
        // destinatario).
        _controller.clear();
        context.read<TransferBloc>().add(
          const TransferEvent.recipientCleared(),
        );
        _elegir(
          Recipient(
            nombreEnmascarado: b.nombreEnmascarado ?? b.apodo,
            cuenta: c,
          ),
        );
      case null:
        _controller.value = TextEditingValue(
          text: b.dni,
          selection: TextSelection.collapsed(offset: b.dni.length),
        );
        _onChanged(b.dni);
    }
  }

  void _elegir(Recipient r) {
    final bloc = context.read<TransferBloc>();
    if (bloc.intentSealed) return;
    // El bloc rechaza la misma cuenta y otra moneda, pero procesa el evento
    // de forma asíncrona: se repite la guarda aquí para no ir al monto sin
    // destinatario.
    final origen = bloc.state.cuenta;
    if (origen == null ||
        r.cuenta.cuentaId == origen.id ||
        r.cuenta.moneda != origen.moneda) {
      return;
    }
    bloc.add(TransferEvent.recipientSelected(r));
    context.push(AppRoutes.enviarMonto);
  }

  List<Widget> _cuentas(
    BuildContext context,
    TransferState state,
    RecipientDirectory d,
  ) {
    final l10n = AppLocalizations.of(context);
    final origen = state.cuenta;
    final propio = d.cuentas.any((c) => c.cuentaId == origen?.id);
    final visibles = [
      for (final c in d.cuentas)
        if (c.cuentaId != origen?.id) c,
    ];
    final elegibles = visibles.where((c) => c.moneda == origen?.moneda);
    final simbolo = origen?.moneda.symbol ?? '';
    return [
      Text(d.nombreEnmascarado, style: CuyCashTypography.titleMd),
      Text(
        d.alias,
        style: CuyCashTypography.bodyMd.copyWith(
          color: CuyCashColors.secondaryText,
        ),
      ),
      const SizedBox(height: CuyCashSpacing.stackXs),
      Text(
        l10n.transferRecipientChooseAccount,
        style: CuyCashTypography.bodyMd.copyWith(
          color: CuyCashColors.secondaryText,
        ),
      ),
      const SizedBox(height: CuyCashSpacing.stackSm),
      if (elegibles.isEmpty)
        InfoStrip(
          icon: Icons.info_outline,
          text: propio
              ? l10n.transferRecipientNoOwnEligible(simbolo)
              : l10n.transferRecipientNoEligible(simbolo),
        ),
      for (final c in visibles) ...[
        RecipientAccountCard(
          cuenta: c,
          titulo:
              c.nombre ??
              l10n.transferRecipientAccountLine(
                accountTypeShort(l10n, c.tipo),
                c.moneda.symbol,
                c.numeroMasked,
              ),
          onTap: c.moneda == origen?.moneda
              ? () => _elegir(
                  Recipient(nombreEnmascarado: d.nombreEnmascarado, cuenta: c),
                )
              : null,
          motivoDeshabilitada: c.moneda == origen?.moneda
              ? null
              : l10n.transferRecipientOnlyReceives(c.moneda.symbol),
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final frecuentes = widget.frecuentes;
    return Scaffold(
      appBar: AppBar(
        // Es la primera página del navegador del ShellRoute del envío: para
        // ese navegador no hay nada detrás y el AppBar no pondría la flecha.
        // `context.pop()` de go_router sí cierra el flujo entero.
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(l10n.transferRecipientTitle),
      ),
      body: SafeArea(
        child: BlocBuilder<TransferBloc, TransferState>(
          builder: (context, state) {
            final failure = state.failure;
            final directorio = state.directorio;
            return SingleChildScrollView(
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
                    hint: l10n.transferRecipientHint,
                    controller: _controller,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    maxLength: _maxLength,
                    autofocus: true,
                    prefixIcon: Icons.person_search_outlined,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _onSearch(),
                    errorText: failure == null
                        ? null
                        : transferResolveErrorText(l10n, failure),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackMd),
                  if (RecipientQuery.parse(_controller.text) is AliasQuery &&
                      directorio == null &&
                      state.status != TransferStatus.resolving) ...[
                    SecondaryButton(
                      label: l10n.transferSearchAction,
                      onPressed: _onSearch,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackMd),
                  ],
                  if (state.status == TransferStatus.resolving)
                    RecipientSkeleton(semanticsLabel: l10n.transferSearching),
                  if (directorio != null)
                    ..._cuentas(context, state, directorio),
                  if (frecuentes != null) ...[
                    const SizedBox(height: CuyCashSpacing.stackMd),
                    frecuentes(_onFrequentSelected),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
