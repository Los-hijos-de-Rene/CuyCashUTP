part of 'open_account_bloc.dart';

@freezed
sealed class OpenAccountEvent with _$OpenAccountEvent {
  /// Se abrió la pantalla: AQUÍ nace la clave de idempotencia.
  const factory OpenAccountEvent.opened() = OpenAccountOpened;

  /// Se ignora con la intención sellada.
  const factory OpenAccountEvent.tipoChanged(AccountType tipo) =
      OpenAccountTipoChanged;

  const factory OpenAccountEvent.monedaChanged(Currency moneda) =
      OpenAccountMonedaChanged;

  const factory OpenAccountEvent.nombreChanged(String nombre) =
      OpenAccountNombreChanged;

  /// El usuario confirmó con su PIN. Se ignora si ya hay una apertura en curso.
  const factory OpenAccountEvent.submitted({required String pin}) =
      OpenAccountSubmitted;
}
