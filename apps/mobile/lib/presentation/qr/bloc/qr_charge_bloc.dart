import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/qr/application/qr_actions.dart';
import '../../../feature/qr/domain/qr_charge.dart';
import '../../../feature/qr/domain/qr_failure.dart';
import 'package:core_kernel/core_kernel.dart';

enum QrChargeStatus { idle, generating, ready, error }

/// Estado del cobro: formulario, generando, QR listo o error.
class QrChargeState {
  const QrChargeState._({
    required this.status,
    this.charge,
    this.failure,
  });

  const QrChargeState.idle() : this._(status: QrChargeStatus.idle);
  const QrChargeState.generating()
      : this._(status: QrChargeStatus.generating);
  const QrChargeState.ready(QrCharge charge)
      : this._(status: QrChargeStatus.ready, charge: charge);
  const QrChargeState.error(QrFailure failure)
      : this._(status: QrChargeStatus.error, failure: failure);

  final QrChargeStatus status;
  final QrCharge? charge;
  final QrFailure? failure;
}

sealed class QrChargeEvent {
  const QrChargeEvent();
}

final class QrChargeRequested extends QrChargeEvent {
  const QrChargeRequested({
    required this.cuentaId,
    required this.monto,
    required this.concepto,
    required this.idempotencyKey,
  });

  final String cuentaId;
  final Money monto;
  final String concepto;
  final String idempotencyKey;
}

final class QrChargeReset extends QrChargeEvent {
  const QrChargeReset();
}

/// Genera el cobro firmado. No mueve dinero: solo publica el QR.
class QrChargeBloc extends Bloc<QrChargeEvent, QrChargeState> {
  QrChargeBloc(this._actions) : super(const QrChargeState.idle()) {
    on<QrChargeRequested>(_onRequested);
    on<QrChargeReset>((event, emit) => emit(const QrChargeState.idle()));
  }

  final QrActions _actions;

  Future<void> _onRequested(
    QrChargeRequested event,
    Emitter<QrChargeState> emit,
  ) async {
    emit(const QrChargeState.generating());
    final result = await _actions.emitir(
      cuentaId: event.cuentaId,
      monto: event.monto,
      concepto: event.concepto,
      idempotencyKey: event.idempotencyKey,
    );
    result.match(
      (failure) => emit(QrChargeState.error(_businessFailure(failure))),
      (charge) => emit(QrChargeState.ready(charge)),
    );
  }

  static QrFailure _businessFailure(GlobalFailure<QrFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: final f) => f,
        _ => const QrFailure.unexpected(),
      };
}
