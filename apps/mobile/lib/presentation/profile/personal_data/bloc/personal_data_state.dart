part of 'personal_data_bloc.dart';

enum PersonalDataStatus { loading, ready, error }

@freezed
abstract class PersonalDataState with _$PersonalDataState {
  const factory PersonalDataState({
    @Default(PersonalDataStatus.loading) PersonalDataStatus status,
    PersonalData? datos,
  }) = _PersonalDataState;
}
