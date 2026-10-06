part of 'beneficiaries_bloc.dart';

enum BeneficiariesStatus { loading, ready, error }

@freezed
abstract class BeneficiariesState with _$BeneficiariesState {
  const factory BeneficiariesState({
    @Default(BeneficiariesStatus.loading) BeneficiariesStatus status,
    @Default(<Beneficiary>[]) List<Beneficiary> items,
  }) = _BeneficiariesState;
}
