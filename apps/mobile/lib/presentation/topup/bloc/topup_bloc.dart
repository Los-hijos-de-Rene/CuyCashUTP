import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/transfer/application/pending_transfer_actions.dart';
import '../../../feature/transfer/application/transfer_actions.dart';
import '../../../feature/transfer/domain/transfer_failure.dart';
import '../../../feature/transfer/domain/transfer_limits.dart';
import '../../../feature/transfer/domain/transfer_receipt.dart';
import '../../transfer/flatten_transfer_failure.dart';

part 'topup_bloc.freezed.dart';
part 'topup_event.dart';
part 'topup_state.dart';

/// Depósito simulado contra la caja del sistema: solo el monto, sin PIN.
/// Comparte con el envío el riesgo de doble cobro, y las mismas defensas:
///
/// 1. La clave de idempotencia nace al ABRIR ([TopUpOpened]); [TopUpSubmitted]
///    solo la lee. Cambia únicamente si cambia el monto.
/// 2. Una recarga en curso no admite otra: [TopUpSubmitted] pasa a
///    `submitting` de forma síncrona, antes de su primer `await`.
/// 3. Con resultado desconocido la intención queda SELLADA.
/// 4. La clave se anota en `PendingTransferActions` justo antes de enviar y se
///    recupera al reintentar el mismo monto aunque el flujo o la app se
///    hayan cerrado. La recuperación ocurre al ENVIAR (no al abrir) porque
///    solo entonces el monto es definitivo.
///
/// Una recarga no puede fallar por fondos ni tiene destinatario.
class TopUpBloc extends Bloc<TopUpEvent, TopUpState> {
  TopUpBloc(
    this._actions, {
    required PendingTransferActions pending,
    required String userId,
    String Function()? newKey,
  }) : _pending = pending,
       _userId = userId,
       _newKey = newKey ?? IdempotencyKey.generate,
       super(const TopUpState()) {
    on<TopUpOpened>(_onOpened);
    on<TopUpAmountChanged>(_onAmountChanged);
    on<TopUpSubmitted>(_onSubmitted);
  }

  final TransferActions _actions;
  final PendingTransferActions _pending;
  final String _userId;
  final String Function() _newKey;

  bool get _intentSealed =>
      state.status == TopUpStatus.submitting ||
      state.status == TopUpStatus.done ||
      state.outcomeUnknown;

  Future<void> _onOpened(TopUpOpened event, Emitter<TopUpState> emit) async {
    // Reabrir con la misma cuenta conserva la clave.
    if (state.idempotencyKey.isNotEmpty && state.cuentaId == event.cuentaId) {
      return;
    }
    emit(TopUpState(cuentaId: event.cuentaId, idempotencyKey: _newKey()));
    // ¿Hay otra operación sin resolver? Se avisa; no se sella porque aún no
    // hay monto con el que compararla.
    if (await _pending.hasPending(_userId) && !_intentSealed) {
      emit(state.copyWith(pendingElsewhere: true));
    }
  }

  void _onAmountChanged(TopUpAmountChanged event, Emitter<TopUpState> emit) {
    if (_intentSealed) return;
    final cambio = event.monto != state.monto;
    emit(
      state.copyWith(
        monto: event.monto,
        failure: null,
        // Otra intención, otra clave: la anterior quedó ligada a otro monto.
        idempotencyKey: cambio ? _newKey() : state.idempotencyKey,
      ),
    );
  }

  Future<void> _onSubmitted(
    TopUpSubmitted event,
    Emitter<TopUpState> emit,
  ) async {
    if (state.status == TopUpStatus.submitting ||
        state.status == TopUpStatus.done) {
      return;
    }
    final monto = state.monto;
    if (monto == null || state.idempotencyKey.isEmpty) return;
    if (monto < TransferLimits.montoMinimo(monto.currency) ||
        monto > TransferLimits.montoMaximo(monto.currency)) {
      emit(state.copyWith(failure: const TransferFailure.amountOutOfRange()));
      return;
    }

    // Síncrono, antes del primer await: el siguiente evento ya ve `submitting`.
    emit(state.copyWith(status: TopUpStatus.submitting, failure: null));
    final cuentaId = state.cuentaId;
    final huella = PendingTransferActions.huellaRecarga(
      cuentaId: cuentaId,
      monto: monto,
    );

    // ¿Salió ya una recarga IGUAL que no llegó a resolverse? Entonces la clave
    // es ESA y el resultado de aquel intento sigue desconocido.
    final pendiente = await _pending.recover(_userId, huella);
    if (pendiente != null && pendiente != state.idempotencyKey) {
      emit(state.copyWith(idempotencyKey: pendiente, outcomeUnknown: true));
    }
    final key = state.idempotencyKey;

    final guardada = await _pending.remember(_userId, huella, key);
    if (!guardada) {
      emit(state.copyWith(keyUnsaved: true));
    } else if (state.keyUnsaved) {
      emit(state.copyWith(keyUnsaved: false));
    }

    final result = await _actions.recargar(
      cuentaId: cuentaId,
      monto: monto,
      idempotencyKey: key,
    );

    // Confirmada, o el servidor dijo que NO movió nada: la entrada ya no hace
    // falta. Con resultado desconocido (o sellado) se conserva.
    final definitivo = result.match((f) {
      final plano = flattenTransferFailure(f);
    // El 401 NO olvida la clave. `TransferUnauthenticated` no deja el
    // resultado desconocido cuando viene de `current_user` (corre antes del
    // handler), pero `authenticated_dio` cuenta con el 401 SIN `code` legible
    // de un gateway, y ese puede llegar DESPUÉS de que la petición tocara la
    // app: olvidar la clave haría que el reintento con la misma intención
    // naciera con una clave nueva y COBRARA DOS VECES. Conservarla no cuesta
    // nada: solo la recupera la misma intención, y el 401 ya cierra la sesión.
      if (plano is TransferUnauthenticated) return false;
      return plano is IdempotencyKeyReused ||
          (!plano.outcomeUnknown && !state.outcomeUnknown);
    }, (_) => true);
    if (definitivo) await _pending.forget(_userId, huella);

    emit(
      result.match(
        (failure) {
          final plano = flattenTransferFailure(failure);
          return state.copyWith(
            status: TopUpStatus.editing,
            failure: plano,
            outcomeUnknown: state.outcomeUnknown || plano.outcomeUnknown,
          );
        },
        (receipt) =>
            state.copyWith(status: TopUpStatus.done, constancia: receipt),
      ),
    );
  }
}
