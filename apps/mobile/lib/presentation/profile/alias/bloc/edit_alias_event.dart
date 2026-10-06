part of 'edit_alias_bloc.dart';

@freezed
sealed class EditAliasEvent with _$EditAliasEvent {
  const factory EditAliasEvent.changed(String input) = EditAliasChanged;
  const factory EditAliasEvent.submitted() = EditAliasSubmitted;
}
