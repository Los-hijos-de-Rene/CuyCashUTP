import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/beneficiary/application/beneficiary_actions.dart';
import '../../../feature/beneficiary/domain/beneficiary.dart';

part 'beneficiaries_bloc.freezed.dart';
part 'beneficiaries_event.dart';
part 'beneficiaries_state.dart';

/// Los frecuentes del titular, para la fila de la pantalla de destinatario.
/// Consume `BeneficiaryActions` por constructor.
///
/// Es una ayuda, no un requisito: si la lista no carga, la fila simplemente no
/// aparece y el usuario sigue pudiendo teclear el DNI. Por eso el fallo no
/// lleva texto.
class BeneficiariesBloc extends Bloc<BeneficiariesEvent, BeneficiariesState> {
  BeneficiariesBloc(this._actions) : super(const BeneficiariesState()) {
    on<BeneficiariesOpened>(_onOpened);
  }

  final BeneficiaryActions _actions;

  Future<void> _onOpened(
    BeneficiariesOpened event,
    Emitter<BeneficiariesState> emit,
  ) async {
    emit(const BeneficiariesState());
    final result = await _actions.listar();
    emit(
      result.match(
        (failure) => const BeneficiariesState(status: BeneficiariesStatus.error),
        (lista) => BeneficiariesState(
          status: BeneficiariesStatus.ready,
          items: lista,
        ),
      ),
    );
  }
}
