// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent()';
}


}

/// @nodoc
class $AccountEventCopyWith<$Res>  {
$AccountEventCopyWith(AccountEvent _, $Res Function(AccountEvent) __);
}


/// Adds pattern-matching-related methods to [AccountEvent].
extension AccountEventPatterns on AccountEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AccountStarted value)?  started,TResult Function( AccountRefreshed value)?  refreshed,TResult Function( AccountMoreRequested value)?  moreRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started(_that);case AccountRefreshed() when refreshed != null:
return refreshed(_that);case AccountMoreRequested() when moreRequested != null:
return moreRequested(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AccountStarted value)  started,required TResult Function( AccountRefreshed value)  refreshed,required TResult Function( AccountMoreRequested value)  moreRequested,}){
final _that = this;
switch (_that) {
case AccountStarted():
return started(_that);case AccountRefreshed():
return refreshed(_that);case AccountMoreRequested():
return moreRequested(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AccountStarted value)?  started,TResult? Function( AccountRefreshed value)?  refreshed,TResult? Function( AccountMoreRequested value)?  moreRequested,}){
final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started(_that);case AccountRefreshed() when refreshed != null:
return refreshed(_that);case AccountMoreRequested() when moreRequested != null:
return moreRequested(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  refreshed,TResult Function()?  moreRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started();case AccountRefreshed() when refreshed != null:
return refreshed();case AccountMoreRequested() when moreRequested != null:
return moreRequested();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  refreshed,required TResult Function()  moreRequested,}) {final _that = this;
switch (_that) {
case AccountStarted():
return started();case AccountRefreshed():
return refreshed();case AccountMoreRequested():
return moreRequested();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  refreshed,TResult? Function()?  moreRequested,}) {final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started();case AccountRefreshed() when refreshed != null:
return refreshed();case AccountMoreRequested() when moreRequested != null:
return moreRequested();case _:
  return null;

}
}

}

/// @nodoc


class AccountStarted implements AccountEvent {
  const AccountStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent.started()';
}


}




/// @nodoc


class AccountRefreshed implements AccountEvent {
  const AccountRefreshed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountRefreshed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent.refreshed()';
}


}




/// @nodoc


class AccountMoreRequested implements AccountEvent {
  const AccountMoreRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountMoreRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent.moreRequested()';
}


}




/// @nodoc
mixin _$AccountState {

 AccountStatus get status; Account? get cuenta; List<Movement> get movimientos;/// Cursor opaco de la siguiente página; `null` = no hay más.
 String? get nextCursor; bool get loadingMore; bool get refreshing;/// Solo con `status == error`.
 AccountFailure? get failure;
/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountStateCopyWith<AccountState> get copyWith => _$AccountStateCopyWithImpl<AccountState>(this as AccountState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountState&&(identical(other.status, status) || other.status == status)&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta)&&const DeepCollectionEquality().equals(other.movimientos, movimientos)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,cuenta,const DeepCollectionEquality().hash(movimientos),nextCursor,loadingMore,refreshing,failure);

@override
String toString() {
  return 'AccountState(status: $status, cuenta: $cuenta, movimientos: $movimientos, nextCursor: $nextCursor, loadingMore: $loadingMore, refreshing: $refreshing, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AccountStateCopyWith<$Res>  {
  factory $AccountStateCopyWith(AccountState value, $Res Function(AccountState) _then) = _$AccountStateCopyWithImpl;
@useResult
$Res call({
 AccountStatus status, Account? cuenta, List<Movement> movimientos, String? nextCursor, bool loadingMore, bool refreshing, AccountFailure? failure
});




}
/// @nodoc
class _$AccountStateCopyWithImpl<$Res>
    implements $AccountStateCopyWith<$Res> {
  _$AccountStateCopyWithImpl(this._self, this._then);

  final AccountState _self;
  final $Res Function(AccountState) _then;

/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? cuenta = freezed,Object? movimientos = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? refreshing = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountStatus,cuenta: freezed == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account?,movimientos: null == movimientos ? _self.movimientos : movimientos // ignore: cast_nullable_to_non_nullable
as List<Movement>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountState].
extension AccountStatePatterns on AccountState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountState value)  $default,){
final _that = this;
switch (_that) {
case _AccountState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountState value)?  $default,){
final _that = this;
switch (_that) {
case _AccountState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccountStatus status,  Account? cuenta,  List<Movement> movimientos,  String? nextCursor,  bool loadingMore,  bool refreshing,  AccountFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountState() when $default != null:
return $default(_that.status,_that.cuenta,_that.movimientos,_that.nextCursor,_that.loadingMore,_that.refreshing,_that.failure);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccountStatus status,  Account? cuenta,  List<Movement> movimientos,  String? nextCursor,  bool loadingMore,  bool refreshing,  AccountFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _AccountState():
return $default(_that.status,_that.cuenta,_that.movimientos,_that.nextCursor,_that.loadingMore,_that.refreshing,_that.failure);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccountStatus status,  Account? cuenta,  List<Movement> movimientos,  String? nextCursor,  bool loadingMore,  bool refreshing,  AccountFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _AccountState() when $default != null:
return $default(_that.status,_that.cuenta,_that.movimientos,_that.nextCursor,_that.loadingMore,_that.refreshing,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _AccountState implements AccountState {
  const _AccountState({this.status = AccountStatus.loading, this.cuenta, final  List<Movement> movimientos = const <Movement>[], this.nextCursor, this.loadingMore = false, this.refreshing = false, this.failure}): _movimientos = movimientos;
  

@override@JsonKey() final  AccountStatus status;
@override final  Account? cuenta;
 final  List<Movement> _movimientos;
@override@JsonKey() List<Movement> get movimientos {
  if (_movimientos is EqualUnmodifiableListView) return _movimientos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_movimientos);
}

/// Cursor opaco de la siguiente página; `null` = no hay más.
@override final  String? nextCursor;
@override@JsonKey() final  bool loadingMore;
@override@JsonKey() final  bool refreshing;
/// Solo con `status == error`.
@override final  AccountFailure? failure;

/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountStateCopyWith<_AccountState> get copyWith => __$AccountStateCopyWithImpl<_AccountState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountState&&(identical(other.status, status) || other.status == status)&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta)&&const DeepCollectionEquality().equals(other._movimientos, _movimientos)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,cuenta,const DeepCollectionEquality().hash(_movimientos),nextCursor,loadingMore,refreshing,failure);

@override
String toString() {
  return 'AccountState(status: $status, cuenta: $cuenta, movimientos: $movimientos, nextCursor: $nextCursor, loadingMore: $loadingMore, refreshing: $refreshing, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$AccountStateCopyWith<$Res> implements $AccountStateCopyWith<$Res> {
  factory _$AccountStateCopyWith(_AccountState value, $Res Function(_AccountState) _then) = __$AccountStateCopyWithImpl;
@override @useResult
$Res call({
 AccountStatus status, Account? cuenta, List<Movement> movimientos, String? nextCursor, bool loadingMore, bool refreshing, AccountFailure? failure
});




}
/// @nodoc
class __$AccountStateCopyWithImpl<$Res>
    implements _$AccountStateCopyWith<$Res> {
  __$AccountStateCopyWithImpl(this._self, this._then);

  final _AccountState _self;
  final $Res Function(_AccountState) _then;

/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? cuenta = freezed,Object? movimientos = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? refreshing = null,Object? failure = freezed,}) {
  return _then(_AccountState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountStatus,cuenta: freezed == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account?,movimientos: null == movimientos ? _self._movimientos : movimientos // ignore: cast_nullable_to_non_nullable
as List<Movement>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}


}

// dart format on
