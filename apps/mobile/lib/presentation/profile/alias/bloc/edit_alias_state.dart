part of 'edit_alias_bloc.dart';

enum EditAliasStatus { editing, saving, saved }

enum AliasError { invalid, network, generic }

@freezed
abstract class EditAliasState with _$EditAliasState {
  const factory EditAliasState({
    required String initial,
    @Default('') String input,
    @Default(EditAliasStatus.editing) EditAliasStatus status,
    AliasError? error,
  }) = _EditAliasState;

  const EditAliasState._();

  String get normalized => AliasRules.normalize(input);

  /// El formato se avisa en vivo solo cuando hay algo escrito.
  bool get showsFormatError =>
      input.trim().isNotEmpty && !AliasRules.isValid(normalized);

  bool get canSave =>
      status == EditAliasStatus.editing &&
      AliasRules.isValid(normalized) &&
      normalized != initial;
}
