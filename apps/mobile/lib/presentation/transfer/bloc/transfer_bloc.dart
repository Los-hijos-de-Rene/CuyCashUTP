import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/domain/account.dart';
import '../../../feature/transfer/application/pending_transfer_actions.dart';
import '../../../feature/transfer/application/transfer_actions.dart';
import '../../../feature/transfer/domain/recipient.dart';
import '../../../feature/transfer/domain/transfer_failure.dart';
import '../../../feature/transfer/domain/transfer_limits.dart';
import '../../../feature/transfer/domain/transfer_receipt.dart';

part 'transfer_bloc.freezed.dart';
part 'transfer_event.dart';
part 'transfer_state.dart';

/// Flujo de envío: destinatario, monto, confirmación con PIN y constancia.
/// Consume `TransferActions` por constructor.
///
/// Dos garantías que protegen el dinero del usuario:
///
/// 1. **La clave de idempotencia nace al ABRIR la confirmación**
///    ([TransferConfirmationOpened]), no al pulsar "Confirmar". Si naciera al
///    pulsar, un doble toque produciría dos claves y el servidor vería dos
///    envíos distintos. Una vez fijada, [TransferSubmitted] solo la LEE: un
///    reintento tras un fallo de red (el envío pudo haberse ejecutado) repite
///    la misma clave y el servidor devuelve la operación original.
///    Solo cambia si cambia la intención (otro destinatario, monto o motivo).
/// 2. **Un envío en curso no admite otro**: [TransferSubmitted] sale sin
///    emitir ni llamar al repositorio mientras el estado es `submitting`.
///    El primer evento pasa a `submitting` de forma síncrona, antes de su
///    primer `await`, así que el segundo ya lo ve.
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc(
    this._actions, {
    required PendingTransferActions pending,
    required String userId,
    String Function()? newKey,
  }) : _pending = pending,
       _userId = userId,
       _newKey = newKey ?? IdempotencyKey.generate,
       super(const TransferState()) {
    on<TransferStarted>(
      (event, emit) => emit(TransferState(cuenta: event.cuenta)),
    );
    on<TransferRecipientRequested>(_onRecipientRequested);
    on<TransferRecipientCleared>(_onRecipientCleared);
    on<TransferAmountEntered>(_onAmountEntered);
    on<TransferConfirmationOpened>(_onConfirmationOpened);
    on<TransferSubmitted>(_onSubmitted);
  }

  final TransferActions _actions;
  final PendingTransferActions _pending;
  final String _userId;
  final String Function() _newKey;

  /// La intención ya no admite cambios: hay un envío en vuelo, ya terminó, o
  /// falló sin que se sepa si el dinero se movió. En ese último caso el
  /// usuario no puede inventar una intención nueva (otro monto u otro
  /// destinatario, con otra clave) mientras la anterior sigue en el aire: solo
  /// reintentar con la MISMA clave o abandonar el flujo.
  bool get _intentSealed =>
      state.status == TransferStatus.submitting ||
      state.status == TransferStatus.done ||
      state.outcomeUnknown;

  /// Cada búsqueda lleva un número: si el DNI se editó mientras volaba, su
  /// respuesta ya no es de este destinatario y se descarta.
  int _search = 0;

  Future<void> _onRecipientRequested(
    TransferRecipientRequested event,
    Emitter<TransferState> emit,
  ) async {
    if (_intentSealed) return;
    final search = ++_search;
    emit(
      state.copyWith(
        status: TransferStatus.resolving,
        destinatario: null,
        failure: null,
        idempotencyKey: '',
      ),
    );
    final result = await _actions.resolverDestinatario(event.dni);
    if (search != _search) return;
    emit(
      result.match(
        (failure) => state.copyWith(
          status: TransferStatus.idle,
          failure: _flatten(failure),
        ),
        (recipient) => state.copyWith(
          status: TransferStatus.ready,
          destinatario: recipient,
        ),
      ),
    );
  }

  void _onRecipientCleared(
    TransferRecipientCleared event,
    Emitter<TransferState> emit,
  ) {
    if (_intentSealed) return;
    _search++;
    emit(
      state.copyWith(
        status: TransferStatus.idle,
        destinatario: null,
        failure: null,
        idempotencyKey: '',
      ),
    );
  }

  void _onAmountEntered(
    TransferAmountEntered event,
    Emitter<TransferState> emit,
  ) {
    if (_intentSealed) return;
    // El motivo se limita en la UI Y aquí: el cliente HTTP no lo recorta y el
    // backend responde 422 (error que el usuario no podría entender).
    final motivo = TransferLimits.normalizarMotivo(event.motivo);
    final cambio = event.monto != state.monto || motivo != state.motivo;
    emit(
      state.copyWith(
        monto: event.monto,
        motivo: motivo,
        failure: null,
        // Otra intención, otra clave: la anterior quedó ligada a otros datos
        // y reutilizarla daría 409.
        idempotencyKey: cambio ? '' : state.idempotencyKey,
      ),
    );
  }

  /// Huella de la intención actual, o `null` si aún no está completa.
  String? get _huella {
    final cuenta = state.cuenta;
    final destinatario = state.destinatario;
    final monto = state.monto;
    if (cuenta == null || destinatario == null || monto == null) return null;
    return PendingTransferActions.huella(
      cuentaId: cuenta.id,
      destinatarioDni: destinatario.dni,
      monto: monto,
      motivo: state.motivo,
    );
  }

  Future<void> _onConfirmationOpened(
    TransferConfirmationOpened event,
    Emitter<TransferState> emit,
  ) async {
    // Volver a abrir la confirmación con la misma intención CONSERVA la clave.
    if (state.idempotencyKey.isNotEmpty) return;
    // ¿Salió ya un envío IGUAL que no llegó a resolverse (flujo cerrado, app
    // reiniciada, sesión vencida)? Entonces la clave es ESA, y la intención
    // nace sellada: el resultado de aquel envío sigue desconocido.
    final huella = _huella;
    final pendiente = huella == null
        ? null
        : await _pending.recover(_userId, huella);
    if (state.idempotencyKey.isNotEmpty) return;
    emit(
      pendiente == null
          ? state.copyWith(idempotencyKey: _newKey())
          : state.copyWith(idempotencyKey: pendiente, outcomeUnknown: true),
    );
  }

  Future<void> _onSubmitted(
    TransferSubmitted event,
    Emitter<TransferState> emit,
  ) async {
    if (state.status == TransferStatus.submitting ||
        state.status == TransferStatus.done) {
      return;
    }
    final cuenta = state.cuenta;
    final destinatario = state.destinatario;
    final monto = state.monto;
    final key = state.idempotencyKey;
    if (cuenta == null ||
        destinatario == null ||
        monto == null ||
        key.isEmpty) {
      return;
    }

    // Síncrono, antes del primer await: el siguiente evento ya ve `submitting`.
    emit(state.copyWith(status: TransferStatus.submitting, failure: null));
    // La clave se anota ANTES de que el envío salga: si la app muere o la
    // sesión vence a mitad, al reentrar con la misma intención se recupera.
    final huella = _huella;
    if (huella != null) await _pending.remember(_userId, huella, key);
    final result = await _actions.enviar(
      cuentaOrigenId: cuenta.id,
      destinatarioDni: destinatario.dni,
      monto: monto,
      motivo: state.motivo,
      pin: event.pin,
      idempotencyKey: key,
    );
    // Confirmado, o el servidor dijo que NO movió nada: la entrada ya no hace
    // falta. Con resultado desconocido (o sellado) se conserva.
    if (huella != null) {
      final definitivo = result.match(
        (f) =>
            _flatten(f) is IdempotencyKeyReused ||
            (!_flatten(f).outcomeUnknown && !state.outcomeUnknown),
        (_) => true,
      );
      if (definitivo) await _pending.forget(_userId, huella);
    }
    emit(
      result.match(
        // Vuelve a `ready` con monto, destinatario y clave intactos: tras un
        // PIN errado no hay que escribir nada más, y tras un fallo de red el
        // reintento lleva la misma clave.
        (failure) => state.copyWith(
          status: TransferStatus.ready,
          failure: _flatten(failure),
          outcomeUnknown:
              state.outcomeUnknown || _flatten(failure).outcomeUnknown,
        ),
        (receipt) =>
            state.copyWith(status: TransferStatus.done, constancia: receipt),
      ),
    );
  }

  /// Aplana el `GlobalFailure` a lo que la pantalla sabe decir.
  TransferFailure _flatten(GlobalFailure<TransferFailure> failure) =>
      switch (failure) {
        ServerFailure(:final failure) => failure,
        NoConnection() || Timeout() => const TransferFailure.network(),
        PermissionDenied() ||
        NotFound() ||
        StorageFailure() ||
        Unexpected() => const TransferFailure.unexpected(),
      };
}
