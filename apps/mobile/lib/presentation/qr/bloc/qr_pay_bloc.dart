import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/account/domain/account.dart';
import '../../../feature/qr/application/qr_actions.dart';
import '../../../feature/qr/domain/qr_failure.dart';
import '../../../feature/qr/domain/qr_payload.dart';
import '../../../feature/qr/domain/qr_payment_preview.dart';
import '../../../feature/qr/domain/qr_receipt.dart';

enum QrPayStatus { scanning, reading, preview, pin, paying, done, error }

/// Estado del pago con QR. Cada paso tiene su constructor para no arrastrar
/// campos que ya no aplican (un PIN no vive en `preview`, por ejemplo).
class QrPayState {
  const QrPayState._({
    required this.status,
    this.preview,
    this.pin = '',
    this.receipt,
    this.failure,
    this.idempotencyKey = '',
  });

  const QrPayState.scanning() : this._(status: QrPayStatus.scanning);
  const QrPayState.reading() : this._(status: QrPayStatus.reading);
  const QrPayState.preview(
    QrPaymentPreview preview, {
    required String idempotencyKey,
  }) : this._(
          status: QrPayStatus.preview,
          preview: preview,
          idempotencyKey: idempotencyKey,
        );
  const QrPayState.pin(
    QrPaymentPreview preview, {
    required String idempotencyKey,
    required String pin,
    QrFailure? failure,
  }) : this._(
          status: QrPayStatus.pin,
          preview: preview,
          idempotencyKey: idempotencyKey,
          pin: pin,
          failure: failure,
        );
  const QrPayState.paying(
    QrPaymentPreview preview, {
    required String idempotencyKey,
    required String pin,
  }) : this._(
          status: QrPayStatus.paying,
          preview: preview,
          idempotencyKey: idempotencyKey,
          pin: pin,
        );
  const QrPayState.done(
    QrReceipt receipt,
    QrPaymentPreview preview,
  ) : this._(status: QrPayStatus.done, receipt: receipt, preview: preview);
  const QrPayState.error(QrFailure failure)
      : this._(status: QrPayStatus.error, failure: failure);

  final QrPayStatus status;
  final QrPaymentPreview? preview;
  final String pin;
  final QrReceipt? receipt;
  final QrFailure? failure;
  final String idempotencyKey;
}

sealed class QrPayEvent {
  const QrPayEvent();
}

final class QrPayloadDetected extends QrPayEvent {
  const QrPayloadDetected(this.payload);
  final String payload;
}

final class QrPayPinDigit extends QrPayEvent {
  const QrPayPinDigit(this.digit);
  final int digit;
}

final class QrPayPinBackspace extends QrPayEvent {
  const QrPayPinBackspace();
}

final class QrPaySubmitted extends QrPayEvent {
  const QrPaySubmitted();
}

final class QrPayReset extends QrPayEvent {
  const QrPayReset();
}

/// Lee el QR y, tras confirmar con PIN, paga. La clave de idempotencia se fija
/// al leer el QR: reintentar un pago fallido no cobra dos veces.
class QrPayBloc extends Bloc<QrPayEvent, QrPayState> {
  QrPayBloc({
    required QrActions actions,
    required Account cuentaOrigen,
    required String userId,
    DateTime Function()? clock,
  })  : _actions = actions,
        _cuentaOrigen = cuentaOrigen,
        _userId = userId,
        _now = clock ?? DateTime.now,
        super(const QrPayState.scanning()) {
    on<QrPayloadDetected>(_onPayload);
    on<QrPayPinDigit>(_onDigit);
    on<QrPayPinBackspace>(_onBackspace);
    on<QrPaySubmitted>(_onSubmitted);
    on<QrPayReset>((event, emit) => emit(const QrPayState.scanning()));
  }

  final QrActions _actions;
  final Account _cuentaOrigen;
  final String _userId;
  final DateTime Function() _now;

  Future<void> _onPayload(
    QrPayloadDetected event,
    Emitter<QrPayState> emit,
  ) async {
    if (state.status == QrPayStatus.reading ||
        state.status == QrPayStatus.paying) {
      return;
    }
    emit(const QrPayState.reading());
    final result = await _actions.leer(extraerCodigoQr(event.payload));
    result.match(
      (failure) => emit(QrPayState.error(_businessFailure(failure))),
      (preview) => emit(
        QrPayState.preview(
          preview,
          idempotencyKey: 'qr-$_userId-${_now().microsecondsSinceEpoch}',
        ),
      ),
    );
  }

  void _onDigit(QrPayPinDigit event, Emitter<QrPayState> emit) {
    final preview = state.preview;
    if (state.status != QrPayStatus.pin ||
        preview == null ||
        state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    if (pin.length < 6) {
      emit(
        QrPayState.pin(
          preview,
          idempotencyKey: state.idempotencyKey,
          pin: pin,
        ),
      );
      return;
    }
    emit(
      QrPayState.paying(
        preview,
        idempotencyKey: state.idempotencyKey,
        pin: pin,
      ),
    );
    add(const QrPaySubmitted());
  }

  void _onBackspace(QrPayPinBackspace event, Emitter<QrPayState> emit) {
    final preview = state.preview;
    if (state.status != QrPayStatus.pin || preview == null || state.pin.isEmpty) {
      return;
    }
    emit(
      QrPayState.pin(
        preview,
        idempotencyKey: state.idempotencyKey,
        pin: state.pin.substring(0, state.pin.length - 1),
      ),
    );
  }

  void _onSubmitted(QrPaySubmitted event, Emitter<QrPayState> emit) {
    final preview = state.preview;
    if (state.status == QrPayStatus.preview && preview != null) {
      emit(
        QrPayState.pin(
          preview,
          idempotencyKey: state.idempotencyKey,
          pin: '',
        ),
      );
      return;
    }
    if (state.status != QrPayStatus.paying || preview == null) return;
    _pagar(preview, state.pin, state.idempotencyKey, emit);
  }

  Future<void> _pagar(
    QrPaymentPreview preview,
    String pin,
    String idempotencyKey,
    Emitter<QrPayState> emit,
  ) async {
    final result = await _actions.pagar(
      payload: preview.payload,
      cuentaOrigenId: _cuentaOrigen.id,
      pin: pin,
      idempotencyKey: idempotencyKey,
    );
    result.match(
      (failure) {
        final f = _businessFailure(failure);
        if (f case QrWrongPin()) {
          emit(
            QrPayState.pin(
              preview,
              idempotencyKey: idempotencyKey,
              pin: '',
              failure: f,
            ),
          );
        } else {
          emit(QrPayState.error(f));
        }
      },
      (receipt) => emit(QrPayState.done(receipt, preview)),
    );
  }

  static QrFailure _businessFailure(GlobalFailure<QrFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: final f) => f,
        _ => const QrFailure.unexpected(),
      };
}
