import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/domain/account.dart';
import '../../../feature/beneficiary/application/beneficiary_actions.dart';
import '../../../feature/transfer/application/pending_transfer_actions.dart';
import '../../../feature/transfer/application/transfer_actions.dart';
import '../../../feature/transfer/domain/recipient.dart';
import '../../../feature/transfer/domain/recipient_directory.dart';
import '../../../feature/transfer/domain/transfer_failure.dart';
import '../../../feature/transfer/domain/transfer_limits.dart';
import '../../../feature/transfer/domain/transfer_receipt.dart';
import '../flatten_transfer_failure.dart';

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
///    Solo cambia si cambia la intención (otra cuenta destino, monto o motivo).
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
    BeneficiaryActions? beneficiaries,
  }) : _pending = pending,
       _beneficiaries = beneficiaries,
       _userId = userId,
       _newKey = newKey ?? IdempotencyKey.generate,
       super(const TransferState()) {
    on<TransferStarted>(
      (event, emit) => emit(TransferState(cuenta: event.cuenta)),
    );
    on<TransferRecipientRequested>(_onRecipientRequested);
    on<TransferRecipientCleared>(_onRecipientCleared);
    on<TransferRecipientSelected>(_onRecipientSelected);
    on<TransferAmountEntered>(_onAmountEntered);
    on<TransferConfirmationOpened>(_onConfirmationOpened);
    on<TransferSubmitted>(_onSubmitted);
    on<TransferSaveFrequentToggled>(_onSaveFrequentToggled);
    on<TransferFrequentNicknameChanged>(_onFrequentNicknameChanged);
  }

  final TransferActions _actions;

  /// `null` = este flujo no guarda frecuentes.
  final BeneficiaryActions? _beneficiaries;

  /// ¿Este flujo sabe guardar frecuentes? La pantalla de monto solo ofrece el
  /// interruptor si es así: uno que no hace nada mentiría.
  bool get puedeGuardarFrecuentes => _beneficiaries != null;
  final PendingTransferActions _pending;
  final String _userId;
  final String Function() _newKey;

  /// La intención ya no admite cambios: hay un envío en vuelo, ya terminó, o
  /// falló sin que se sepa si el dinero se movió. En ese último caso el
  /// usuario no puede inventar una intención nueva (otro monto u otro
  /// destinatario, con otra clave) mientras la anterior sigue en el aire: solo
  /// reintentar con la MISMA clave o abandonar el flujo.
  bool get intentSealed =>
      state.status == TransferStatus.submitting ||
      state.status == TransferStatus.done ||
      state.outcomeUnknown;

  /// Cada búsqueda lleva un número: si el DNI o alias se editó mientras volaba, su
  /// respuesta ya no es de este destinatario y se descarta.
  int _search = 0;

  Future<void> _onRecipientRequested(
    TransferRecipientRequested event,
    Emitter<TransferState> emit,
  ) async {
    if (intentSealed) return;
    final search = ++_search;
    emit(
      state.copyWith(
        status: TransferStatus.resolving,
        directorio: null,
        destinatario: null,
        failure: null,
        idempotencyKey: '',
      ),
    );
    final result = await _actions.resolverDestinatario(event.consulta);
    if (search != _search) return;
    emit(
      result.match(
        (failure) => state.copyWith(
          status: TransferStatus.idle,
          failure: _flatten(failure),
        ),
        (directorio) =>
            state.copyWith(status: TransferStatus.ready, directorio: directorio),
      ),
    );
  }

  void _onRecipientCleared(
    TransferRecipientCleared event,
    Emitter<TransferState> emit,
  ) {
    if (intentSealed) return;
    _search++;
    emit(
      state.copyWith(
        status: TransferStatus.idle,
        directorio: null,
        destinatario: null,
        failure: null,
        idempotencyKey: '',
      ),
    );
  }

  void _onRecipientSelected(
    TransferRecipientSelected event,
    Emitter<TransferState> emit,
  ) {
    if (intentSealed) return;
    final elegido = event.destinatario;
    final origen = state.cuenta;
    if (origen != null && elegido.cuenta.cuentaId == origen.id) {
      emit(state.copyWith(failure: const TransferFailure.sameAccount()));
      return;
    }
    if (origen != null && elegido.cuenta.moneda != origen.moneda) {
      emit(state.copyWith(failure: const TransferFailure.currencyMismatch()));
      return;
    }
    final cambio =
        state.destinatario?.cuenta.cuentaId != elegido.cuenta.cuentaId;
    emit(
      state.copyWith(
        status: TransferStatus.ready,
        destinatario: elegido,
        failure: null,
        // Otra cuenta, otra intención: la clave anterior quedó ligada a otro
        // destino y reutilizarla daría 409 (o, peor, un reintento hacia la
        // cuenta equivocada si el servidor no comparara el destino).
        idempotencyKey: cambio ? '' : state.idempotencyKey,
      ),
    );
  }

  void _onAmountEntered(
    TransferAmountEntered event,
    Emitter<TransferState> emit,
  ) {
    if (intentSealed) return;
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
      cuentaDestinoId: destinatario.cuenta.cuentaId,
      monto: monto,
      motivo: state.motivo,
    );
  }

  void _onSaveFrequentToggled(
    TransferSaveFrequentToggled event,
    Emitter<TransferState> emit,
  ) {
    if (intentSealed) return;
    emit(state.copyWith(guardarFrecuente: event.value));
  }

  void _onFrequentNicknameChanged(
    TransferFrequentNicknameChanged event,
    Emitter<TransferState> emit,
  ) {
    if (intentSealed) return;
    emit(state.copyWith(apodoFrecuente: event.value));
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
    // Sin coincidencia exacta, ¿hay otro envío sin resolver? (p. ej. el mismo
    // pago con otro motivo tras matar la app): no se sella, pero se avisa.
    final otro = pendiente == null && await _pending.hasPending(_userId);
    if (state.idempotencyKey.isNotEmpty) return;
    // La intención pudo cambiar durante los `await` (otra cuenta, otro monto):
    // la clave hallada sería de la intención anterior. La próxima apertura de
    // la confirmación lo rehace.
    if (_huella != huella) return;
    emit(
      pendiente == null
          ? state.copyWith(idempotencyKey: _newKey(), pendingElsewhere: otro)
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
    // Si no se pudo anotar, el envío sigue (tumbarlo por un fallo de disco
    // sería peor), pero queda marcado para que la pantalla no prometa lo que
    // no puede cumplir.
    final guardada =
        huella == null || await _pending.remember(_userId, huella, key);
    if (!guardada) emit(state.copyWith(keyUnsaved: true));
    final result = await _actions.enviar(
      cuentaOrigenId: cuenta.id,
      cuentaDestinoId: destinatario.cuenta.cuentaId,
      monto: monto,
      motivo: state.motivo,
      pin: event.pin,
      idempotencyKey: key,
    );
    // Confirmado, o el servidor dijo que NO movió nada: la entrada ya no hace
    // falta. Con resultado desconocido (o sellado) se conserva.
    if (huella != null) {
      final definitivo = result.match((f) {
        final plano = _flatten(f);
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
    if (result.isRight()) await _saveFrequent(emit);
  }

  /// Guarda al destinatario DESPUÉS de un envío exitoso, nunca antes: el
  /// destinatario de una operación que falló no es un frecuente. Si no se
  /// puede guardar el envío sigue siendo válido; solo se avisa en la
  /// constancia. Guardar gasta presupuesto de consultas y puede dar 429.
  Future<void> _saveFrequent(Emitter<TransferState> emit) async {
    final beneficiaries = _beneficiaries;
    final destinatario = state.destinatario;
    if (!state.guardarFrecuente ||
        beneficiaries == null ||
        destinatario == null) {
      return;
    }
    // Sin apodo propio, el enmascarado: es lo único que la app sabe.
    final apodo = state.apodoFrecuente.trim();
    final saved = await beneficiaries.guardar(
      cuentaDestinoId: destinatario.cuenta.cuentaId,
      apodo: apodo.isEmpty ? destinatario.nombreEnmascarado : apodo,
    );
    if (saved.isLeft()) emit(state.copyWith(frecuenteNoGuardado: true));
  }

  TransferFailure _flatten(GlobalFailure<TransferFailure> failure) =>
      flattenTransferFailure(failure);
}
