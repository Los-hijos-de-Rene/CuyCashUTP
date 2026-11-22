import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/account/domain/account.dart';
import '../../../feature/qr/application/qr_actions.dart';
import '../../../feature/qr/domain/qr_failure.dart';
import '../../../feature/qr/domain/qr_payload.dart';
import '../../../feature/qr/domain/qr_payment_preview.dart';
import '../../../feature/qr/domain/qr_receipt.dart';
import '../../../feature/transfer/domain/transfer_limits.dart';

enum QrPayStatus { scanning, reading, preview, pin, paying, done, error }

/// Por qué no se acepta el monto que escribió el pagador de un QR libre. Se
/// detecta ANTES de pedir el PIN: no tiene sentido gastar un intento en un
/// pago que el servidor va a rechazar.
sealed class QrAmountError {
  const QrAmountError();
}

/// Vacío, cero o con formato que no es dinero.
final class QrAmountInvalid extends QrAmountError {
  const QrAmountInvalid();
}

/// Supera el máximo por operación.
final class QrAmountAboveMax extends QrAmountError {
  const QrAmountAboveMax(this.maximo);
  final Money maximo;
}

/// Supera lo que aún puede pagar hoy (límite diario).
final class QrAmountAboveDaily extends QrAmountError {
  const QrAmountAboveDaily(this.disponible);
  final Money disponible;
}

/// Estado del pago con QR. Cada paso tiene su constructor para no arrastrar
/// campos que ya no aplican (un PIN no vive en `preview`, por ejemplo).
///
/// [monto] es lo que se va a pagar: el del cobro si es fijo, el que escribió
/// el pagador si es libre. Existe desde `pin`.
class QrPayState {
  const QrPayState._({
    required this.status,
    this.preview,
    this.pin = '',
    this.receipt,
    this.failure,
    this.amountError,
    this.idempotencyKey = '',
    this.monto,
    this.mensaje,
  });

  const QrPayState.scanning() : this._(status: QrPayStatus.scanning);
  const QrPayState.reading() : this._(status: QrPayStatus.reading);
  const QrPayState.preview(
    QrPaymentPreview preview, {
    required String idempotencyKey,
    QrAmountError? amountError,
  }) : this._(
          status: QrPayStatus.preview,
          preview: preview,
          idempotencyKey: idempotencyKey,
          amountError: amountError,
        );
  const QrPayState.pin(
    QrPaymentPreview preview, {
    required String idempotencyKey,
    required String pin,
    required Money monto,
    String? mensaje,
    QrFailure? failure,
  }) : this._(
          status: QrPayStatus.pin,
          preview: preview,
          idempotencyKey: idempotencyKey,
          pin: pin,
          monto: monto,
          mensaje: mensaje,
          failure: failure,
        );
  const QrPayState.paying(
    QrPaymentPreview preview, {
    required String idempotencyKey,
    required String pin,
    required Money monto,
    String? mensaje,
  }) : this._(
          status: QrPayStatus.paying,
          preview: preview,
          idempotencyKey: idempotencyKey,
          pin: pin,
          monto: monto,
          mensaje: mensaje,
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
  final QrAmountError? amountError;
  final String idempotencyKey;
  final Money? monto;
  final String? mensaje;
}

sealed class QrPayEvent {
  const QrPayEvent();
}

final class QrPayloadDetected extends QrPayEvent {
  const QrPayloadDetected(this.payload);
  final String payload;
}

/// El pagador de un QR libre escribió el monto (texto tal cual, p. ej.
/// `"12.50"`) y, si quiso, un mensaje.
final class QrPayAmountSubmitted extends QrPayEvent {
  const QrPayAmountSubmitted({required this.monto, this.mensaje = ''});
  final String monto;
  final String mensaje;
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
    on<QrPayAmountSubmitted>(_onAmount);
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

  void _onAmount(QrPayAmountSubmitted event, Emitter<QrPayState> emit) {
    final preview = state.preview;
    if (state.status != QrPayStatus.preview || preview == null) return;
    if (preview.cobro is! QrCobroLibre) return;

    final monto = Money.parse(event.monto.trim(), preview.moneda);
    final error = _errorDeMonto(monto, preview);
    if (error != null || monto == null) {
      emit(
        QrPayState.preview(
          preview,
          idempotencyKey: state.idempotencyKey,
          amountError: error ?? const QrAmountInvalid(),
        ),
      );
      return;
    }
    final mensaje = event.mensaje.trim();
    emit(
      QrPayState.pin(
        preview,
        idempotencyKey: state.idempotencyKey,
        pin: '',
        monto: monto,
        // El largo lo limita el campo (`QrLimits.mensajeMaximo`).
        mensaje: mensaje.isEmpty ? null : mensaje,
      ),
    );
  }

  static QrAmountError? _errorDeMonto(Money? monto, QrPaymentPreview preview) {
    if (monto == null || monto <= Money.zero(preview.moneda)) {
      return const QrAmountInvalid();
    }
    final maximo = TransferLimits.montoMaximo(preview.moneda);
    if (monto > maximo) return QrAmountAboveMax(maximo);
    if (preview.disponibleHoy case final disponible? when monto > disponible) {
      return QrAmountAboveDaily(disponible);
    }
    return null;
  }

  void _onDigit(QrPayPinDigit event, Emitter<QrPayState> emit) {
    final preview = state.preview;
    final monto = state.monto;
    if (state.status != QrPayStatus.pin ||
        preview == null ||
        monto == null ||
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
          monto: monto,
          mensaje: state.mensaje,
        ),
      );
      return;
    }
    emit(
      QrPayState.paying(
        preview,
        idempotencyKey: state.idempotencyKey,
        pin: pin,
        monto: monto,
        mensaje: state.mensaje,
      ),
    );
    add(const QrPaySubmitted());
  }

  void _onBackspace(QrPayPinBackspace event, Emitter<QrPayState> emit) {
    final preview = state.preview;
    final monto = state.monto;
    if (state.status != QrPayStatus.pin ||
        preview == null ||
        monto == null ||
        state.pin.isEmpty) {
      return;
    }
    emit(
      QrPayState.pin(
        preview,
        idempotencyKey: state.idempotencyKey,
        pin: state.pin.substring(0, state.pin.length - 1),
        monto: monto,
        mensaje: state.mensaje,
      ),
    );
  }

  Future<void> _onSubmitted(
    QrPaySubmitted event,
    Emitter<QrPayState> emit,
  ) async {
    final preview = state.preview;
    if (state.status == QrPayStatus.preview && preview != null) {
      // Solo el cobro fijo pasa directo al PIN: el libre necesita el monto
      // (`QrPayAmountSubmitted`).
      if (preview.cobro case QrCobroFijo(:final monto)) {
        emit(
          QrPayState.pin(
            preview,
            idempotencyKey: state.idempotencyKey,
            pin: '',
            monto: monto,
          ),
        );
      }
      return;
    }
    final monto = state.monto;
    if (state.status != QrPayStatus.paying || preview == null || monto == null) {
      return;
    }
    await _pagar(preview, monto, state.mensaje, state.pin, state.idempotencyKey,
        emit);
  }

  Future<void> _pagar(
    QrPaymentPreview preview,
    Money monto,
    String? mensaje,
    String pin,
    String idempotencyKey,
    Emitter<QrPayState> emit,
  ) async {
    final libre = preview.cobro is QrCobroLibre;
    final result = await _actions.pagar(
      payload: preview.payload,
      cuentaOrigenId: _cuentaOrigen.id,
      pin: pin,
      idempotencyKey: idempotencyKey,
      // En el fijo el monto lo pone el servidor: no se manda.
      monto: libre ? monto : null,
      mensaje: libre ? mensaje : null,
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
              monto: monto,
              mensaje: mensaje,
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
