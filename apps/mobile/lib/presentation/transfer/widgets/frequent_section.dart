import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/beneficiary/application/beneficiary_actions.dart';
import '../../../feature/beneficiary/domain/beneficiary.dart';
import '../bloc/beneficiaries_bloc.dart';
import 'frequent_row.dart';

/// Carga los frecuentes y pinta su fila. Si no cargan (o no hay), no se ve:
/// la fila es una ayuda, no un requisito.
class FrequentSection extends StatelessWidget {
  const FrequentSection({
    required this.actions,
    required this.onSelected,
    super.key,
  });

  final BeneficiaryActions actions;
  final ValueChanged<Beneficiary> onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BeneficiariesBloc(actions)..add(const BeneficiariesEvent.opened()),
      child: BlocBuilder<BeneficiariesBloc, BeneficiariesState>(
        builder: (context, state) => switch (state.status) {
          BeneficiariesStatus.ready => FrequentRow(
            beneficiarios: state.items,
            onSelected: onSelected,
          ),
          BeneficiariesStatus.loading ||
          BeneficiariesStatus.error => const SizedBox.shrink(),
        },
      ),
    );
  }
}
