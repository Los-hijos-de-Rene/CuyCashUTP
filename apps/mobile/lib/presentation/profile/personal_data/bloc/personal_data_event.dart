part of 'personal_data_bloc.dart';

@freezed
sealed class PersonalDataEvent with _$PersonalDataEvent {
  const factory PersonalDataEvent.started() = PersonalDataStarted;
}
