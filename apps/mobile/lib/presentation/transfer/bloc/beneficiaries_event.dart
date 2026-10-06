part of 'beneficiaries_bloc.dart';

@freezed
sealed class BeneficiariesEvent with _$BeneficiariesEvent {
  /// Se abrió la pantalla de destinatario: cargar la lista.
  const factory BeneficiariesEvent.opened() = BeneficiariesOpened;
}
