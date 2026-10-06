import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/account/application/account_actions.dart';
import '../../../feature/account/domain/account.dart';
import '../../../feature/account/domain/account_failure.dart';
import '../../../feature/account/domain/account_limits.dart';
import '../../../feature/account/domain/account_type.dart';
import '../../../feature/transfer/application/pending_transfer_actions.dart';

part 'open_account_bloc.freezed.dart';
part 'open_account_event.dart';
part 'open_account_state.dart';

/// Abrir otra cuenta: tipo + moneda + nombre, y el PIN que la autoriza.
/// Comparte con el envío y la recarga el riesgo de duplicar (aquí, abrir dos
/// cuentas), y las mismas defensas:
///
/// 1. La clave de idempotencia nace al ABRIR ([OpenAccountOpened]);
///    [OpenAccountSubmitted] solo la lee. Cambia únicamente si cambia la
///    intención (tipo, moneda o nombre).
/// 2. Una apertura en curso no admite otra: [OpenAccountSubmitted] pasa a
///    `submitting` de forma síncrona, antes de su primer `await`.
/// 3. Con resultado desconocido la intención queda SELLADA.
/// 4. La clave se anota en `PendingTransferActions` justo antes de enviar y se
///    recupera al reintentar la misma intención aunque se cierre la app.
class OpenAccountBloc extends Bloc<OpenAccountEvent, OpenAccountState> {
  OpenAccountBloc(
    this._actions, {
    required PendingTransferActions pending,
    required String userId,
    required List<Account> cuentas,
    String Function()? newKey,
  }) : _pending = pending,
       _userId = userId,
       _newKey = newKey ?? IdempotencyKey.generate,
       super(
         OpenAccountState(
           tieneSueldo: cuentas.any((c) => c.tipo == AccountType.sueldo),
         ),
       ) {
    on<OpenAccountOpened>(_onOpened);
    on<OpenAccountTipoChanged>(_onTipo);
    on<OpenAccountMonedaChanged>(_onMoneda);
    on<OpenAccountNombreChanged>(_onNombre);
    on<OpenAccountSubmitted>(_onSubmitted);
  }

  final AccountActions _actions;
  final PendingTransferActions _pending;
  final String _userId;
  final String Function() _newKey;

  bool get _sealed =>
      state.status != OpenAccountStatus.editing || state.outcomeUnknown;

  void _onOpened(OpenAccountOpened e, Emitter<OpenAccountState> emit) {
    if (state.idempotencyKey.isNotEmpty) return;
    emit(state.copyWith(idempotencyKey: _newKey()));
  }

  void _cambiar(Emitter<OpenAccountState> emit, OpenAccountState nuevo) {
    final cambio =
        (nuevo.tipo, nuevo.moneda, nuevo.nombre.trim()) !=
        (state.tipo, state.moneda, state.nombre.trim());
    emit(
      nuevo.copyWith(
        failure: null,
        idempotencyKey: cambio ? _newKey() : state.idempotencyKey,
      ),
    );
  }

  void _onTipo(OpenAccountTipoChanged e, Emitter<OpenAccountState> emit) {
    if (_sealed) return;
    _cambiar(
      emit,
      state.copyWith(
        tipo: e.tipo,
        // La sueldo solo existe en soles: elegirla fija la moneda.
        moneda: e.tipo == AccountType.sueldo ? Currency.pen : state.moneda,
      ),
    );
  }

  void _onMoneda(OpenAccountMonedaChanged e, Emitter<OpenAccountState> emit) {
    if (_sealed || state.monedaFija) return;
    _cambiar(emit, state.copyWith(moneda: e.moneda));
  }

  void _onNombre(OpenAccountNombreChanged e, Emitter<OpenAccountState> emit) {
    if (_sealed) return;
    _cambiar(emit, state.copyWith(nombre: e.nombre));
  }

  Future<void> _onSubmitted(
    OpenAccountSubmitted e,
    Emitter<OpenAccountState> emit,
  ) async {
    if (state.status != OpenAccountStatus.editing ||
        state.idempotencyKey.isEmpty) {
      return;
    }
    // Síncrono, antes del primer await: el segundo toque ya ve `submitting`.
    emit(state.copyWith(status: OpenAccountStatus.submitting, failure: null));
    final nombre = AccountLimits.normalizarNombre(state.nombre);
    final huella = PendingTransferActions.huellaApertura(
      tipo: state.tipo,
      moneda: state.moneda,
      nombre: nombre,
    );
    final pendiente = await _pending.recover(_userId, huella);
    if (pendiente != null && pendiente != state.idempotencyKey) {
      emit(state.copyWith(idempotencyKey: pendiente, outcomeUnknown: true));
    }
    final key = state.idempotencyKey;
    if (!await _pending.remember(_userId, huella, key)) {
      emit(state.copyWith(keyUnsaved: true));
    }
    final result = await _actions.abrir(
      tipo: state.tipo,
      moneda: state.moneda,
      nombre: nombre,
      pin: e.pin,
      idempotencyKey: key,
    );
    final definitivo = result.match((f) {
      final plano = _plano(f);
      return plano is AccountKeyReused ||
          (!plano.outcomeUnknown && !state.outcomeUnknown);
    }, (_) => true);
    if (definitivo) await _pending.forget(_userId, huella);
    emit(
      result.match(
        (f) {
          final plano = _plano(f);
          return state.copyWith(
            status: OpenAccountStatus.editing,
            failure: plano,
            outcomeUnknown: state.outcomeUnknown || plano.outcomeUnknown,
          );
        },
        (cuenta) =>
            state.copyWith(status: OpenAccountStatus.done, cuenta: cuenta),
      ),
    );
  }

  AccountFailure _plano(GlobalFailure<AccountFailure> f) => switch (f) {
    ServerFailure(:final failure) => failure,
    NoConnection() || Timeout() => const AccountFailure.network(),
    _ => const AccountFailure.unexpected(),
  };
}
