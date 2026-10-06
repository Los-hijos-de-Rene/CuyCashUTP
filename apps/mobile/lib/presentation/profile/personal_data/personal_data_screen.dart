import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../feature/profile/domain/personal_data.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/profile_data_row.dart';
import 'bloc/personal_data_bloc.dart';

/// Datos personales: solo lectura. Vienen del KYC; corregirlos es un trámite
/// con soporte, no un campo editable.
class PersonalDataScreen extends StatelessWidget {
  const PersonalDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(l10n.personalDataTitle),
        backgroundColor: CuyCashColors.surfaceContainerLow,
      ),
      body: BlocBuilder<PersonalDataBloc, PersonalDataState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
          children: switch ((state.status, state.datos)) {
            (PersonalDataStatus.ready, final PersonalData datos) => _ready(
              l10n,
              datos,
            ),
            (PersonalDataStatus.error, _) => _error(context, l10n),
            _ => _loading(),
          },
        ),
      ),
    );
  }

  List<Widget> _ready(AppLocalizations l10n, PersonalData d) => [
    // Solo se afirma lo que el servidor confirmó. Hoy el backend no
    // registra el resultado del KYC (`kyc_status` queda en `pending`), así
    // que decir "pendiente" sería falso para todos.
    if (d.kycVerified) ...[
      Row(
        children: [
          const Icon(
            Icons.verified_user,
            size: 18,
            color: CuyCashColors.success,
          ),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Text(l10n.personalDataVerified, style: CuyCashTypography.labelMd),
        ],
      ),
      const SizedBox(height: CuyCashSpacing.stackMd),
    ],
    SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, (label, value)) in [
            (l10n.personalDataNames, d.nombres),
            (l10n.personalDataSurnames, d.apellidos),
            (l10n.profileDniLabel, d.dni),
            (l10n.personalDataEmail, d.emailMasked),
            (l10n.personalDataAlias, d.alias),
            (
              l10n.personalDataSince,
              DateFormat('dd/MM/yyyy').format(d.clienteDesde.toLocal()),
            ),
          ].indexed) ...[
            if (i > 0) const Divider(height: 1, color: CuyCashColors.divider),
            ProfileDataRow(label: label, value: value),
          ],
        ],
      ),
    ),
    const SizedBox(height: CuyCashSpacing.stackMd),
    InfoStrip(icon: Icons.info_outline, text: l10n.personalDataReadOnly),
  ];

  List<Widget> _error(BuildContext context, AppLocalizations l10n) => [
    const SizedBox(height: CuyCashSpacing.stackLg),
    Text(
      l10n.personalDataError,
      textAlign: TextAlign.center,
      style: CuyCashTypography.bodyMd,
    ),
    const SizedBox(height: CuyCashSpacing.stackMd),
    SecondaryButton(
      label: l10n.homeRetry,
      onPressed: () => context.read<PersonalDataBloc>().add(
        const PersonalDataEvent.started(),
      ),
    ),
  ];

  List<Widget> _loading() => [
    const SkeletonBox(width: 160),
    const SizedBox(height: CuyCashSpacing.stackMd),
    SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(height: CuyCashSpacing.stackMd),
            const SkeletonBox(width: 220),
          ],
        ],
      ),
    ),
  ];
}
