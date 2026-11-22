import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/account/domain/account.dart';
import '../../../feature/qr/application/qr_actions.dart';
import '../../../feature/qr/domain/qr_failure.dart';
import '../../../feature/qr/domain/qr_static.dart';

sealed class MyQrState {
  const MyQrState();
}

final class MyQrLoading extends MyQrState {
  const MyQrLoading();
}

/// El QR vigente. [regenerando] mientras se pide uno nuevo (el actual se
/// sigue mostrando); [regenerado] justo después de cambiarlo, para avisarlo.
final class MyQrReady extends MyQrState {
  const MyQrReady(
    this.qr, {
    this.regenerando = false,
    this.regenerado = false,
    this.failure,
  });

  final QrStatic qr;
  final bool regenerando;
  final bool regenerado;

  /// Falló el cambio de QR: el actual sigue valiendo.
  final QrFailure? failure;
}

final class MyQrError extends MyQrState {
  const MyQrError(this.failure);
  final QrFailure failure;
}

sealed class MyQrEvent {
  const MyQrEvent();
}

/// Carga (o crea, la primera vez) el "Mi QR" de la cuenta.
final class MyQrRequested extends MyQrEvent {
  const MyQrRequested();
}

/// Revoca el QR actual y emite otro.
final class MyQrRegenerateRequested extends MyQrEvent {
  const MyQrRegenerateRequested();
}

/// "Mi QR" de una cuenta: el QR permanente con el que el titular cobra y el
/// pagador elige el monto.
class MyQrBloc extends Bloc<MyQrEvent, MyQrState> {
  MyQrBloc({required QrActions actions, required Account cuenta})
      : _actions = actions,
        _cuenta = cuenta,
        super(const MyQrLoading()) {
    on<MyQrRequested>(_onRequested);
    on<MyQrRegenerateRequested>(_onRegenerate);
  }

  final QrActions _actions;
  final Account _cuenta;

  Future<void> _onRequested(
    MyQrRequested event,
    Emitter<MyQrState> emit,
  ) async {
    emit(const MyQrLoading());
    final result = await _actions.miQr(_cuenta);
    result.match(
      (failure) => emit(MyQrError(_businessFailure(failure))),
      (qr) => emit(MyQrReady(qr)),
    );
  }

  Future<void> _onRegenerate(
    MyQrRegenerateRequested event,
    Emitter<MyQrState> emit,
  ) async {
    final actual = state;
    if (actual is! MyQrReady || actual.regenerando) return;
    emit(MyQrReady(actual.qr, regenerando: true));
    final result = await _actions.regenerarMiQr(_cuenta);
    result.match(
      (failure) =>
          emit(MyQrReady(actual.qr, failure: _businessFailure(failure))),
      (qr) => emit(MyQrReady(qr, regenerado: true)),
    );
  }

  static QrFailure _businessFailure(GlobalFailure<QrFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: final f) => f,
        _ => const QrFailure.unexpected(),
      };
}
