part of 'quick_access_bloc.dart';

enum QuickAccessStatus { idle, verifying }

@freezed
abstract class QuickAccessState with _$QuickAccessState {
  const factory QuickAccessState({
    required RememberedUser user,
    @Default('') String pin,
    @Default(QuickAccessStatus.idle) QuickAccessStatus status,
    @Default(LockoutPolicy.maxAttempts) int attemptsLeft,
    @Default(false) bool lastWrong,
    DateTime? lockedUntil,
  }) = _QuickAccessState;
}
