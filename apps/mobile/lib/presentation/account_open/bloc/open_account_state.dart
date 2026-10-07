part of 'open_account_bloc.dart';

/// `editing`: el usuario elige (también vuelve aquí tras un fallo, con todo
/// intacto). `submitting`: la apertura va en vuelo. `done`: hay cuenta.
enum OpenAccountStatus { editing, submitting, done }

@freezed
abstract class OpenAccountState with _$OpenAccountState {
  const OpenAccountState._();

  const factory OpenAccountState({
    @Default(OpenAccountStatus.editing) OpenAccountStatus status,
    @Default(AccountType.ahorro) AccountType tipo,
    @Default(Currency.pen) Currency moneda,
    @Default('') String nombre,

    /// Identifica la INTENCIÓN (tipo + moneda + nombre). Nace al abrir,
    /// cambia solo si cambia la intención y jamás entre reintentos.
    @Default('') String idempotencyKey,
    AccountFailure? failure,

    /// Falló sin saberse si se abrió: la intención queda sellada.
    @Default(false) bool outcomeUnknown,
    @Default(false) bool keyUnsaved,

    /// ¿Hay ya una sueldo entre las cuentas del titular?
    @Default(false) bool tieneSueldo,
    Account? cuenta,
  }) = _OpenAccountState;

  bool get sueldoDisponible => !tieneSueldo;
  bool get monedaFija => tipo == AccountType.sueldo;
}
