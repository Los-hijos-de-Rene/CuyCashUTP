// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'movements_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MovementsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MovementsEvent()';
}


}

/// @nodoc
class $MovementsEventCopyWith<$Res>  {
$MovementsEventCopyWith(MovementsEvent _, $Res Function(MovementsEvent) __);
}


/// Adds pattern-matching-related methods to [MovementsEvent].
extension MovementsEventPatterns on MovementsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MovementsStarted value)?  started,TResult Function( MovementsRefreshed value)?  refreshed,TResult Function( MovementsMoreRequested value)?  moreRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MovementsStarted() when started != null:
return started(_that);case MovementsRefreshed() when refreshed != null:
return refreshed(_that);case MovementsMoreRequested() when moreRequested != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MovementsStarted value)  started,required TResult Function( MovementsRefreshed value)  refreshed,required TResult Function( MovementsMoreRequested value)  moreRequested,}){
final _that = this;
switch (_that) {
case MovementsStarted():
return started(_that);case MovementsRefreshed():
return refreshed(_that);case MovementsMoreRequested():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MovementsStarted value)?  started,TResult? Function( MovementsRefreshed value)?  refreshed,TResult? Function( MovementsMoreRequested value)?  moreRequested,}){
final _that = this;
switch (_that) {
case MovementsStarted() when started != null:
return started(_that);case MovementsRefreshed() when refreshed != null:
return refreshed(_that);case MovementsMoreRequested() when moreRequested != null:
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
case MovementsStarted() when started != null:
return started();case MovementsRefreshed() when refreshed != null:
return refreshed();case MovementsMoreRequested() when moreRequested != null:
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
case MovementsStarted():
return started();case MovementsRefreshed():
return refreshed();case MovementsMoreRequested():
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
case MovementsStarted() when started != null:
return started();case MovementsRefreshed() when refreshed != null:
return refreshed();case MovementsMoreRequested() when moreRequested != null:
return moreRequested();case _:
  return null;

}
}

}

/// @nodoc


class MovementsStarted implements MovementsEvent {
  const MovementsStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementsStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MovementsEvent.started()';
}


}




/// @nodoc


class MovementsRefreshed implements MovementsEvent {
  const MovementsRefreshed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementsRefreshed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MovementsEvent.refreshed()';
}


}




/// @nodoc


class MovementsMoreRequested implements MovementsEvent {
  const MovementsMoreRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementsMoreRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MovementsEvent.moreRequested()';
}


}




/// @nodoc
mixin _$MovementsState {

 MovementsStatus get status; List<Movement> get movimientos;/// Cursor opaco de la siguiente página; `null` = no hay más.
 String? get nextCursor; bool get loadingMore;/// La última página pedida por scroll falló. El cursor se conserva: el
/// siguiente scroll reintenta la misma.
 bool get loadMoreFailed; bool get refreshing;/// El último refresco falló y lo que se ve son datos anteriores.
 bool get refreshFailed;/// Solo con `status == error`.
 AccountFailure? get failure;
/// Create a copy of MovementsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementsStateCopyWith<MovementsState> get copyWith => _$MovementsStateCopyWithImpl<MovementsState>(this as MovementsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.movimientos, movimientos)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.loadMoreFailed, loadMoreFailed) || other.loadMoreFailed == loadMoreFailed)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.refreshFailed, refreshFailed) || other.refreshFailed == refreshFailed)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(movimientos),nextCursor,loadingMore,loadMoreFailed,refreshing,refreshFailed,failure);

@override
String toString() {
  return 'MovementsState(status: $status, movimientos: $movimientos, nextCursor: $nextCursor, loadingMore: $loadingMore, loadMoreFailed: $loadMoreFailed, refreshing: $refreshing, refreshFailed: $refreshFailed, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $MovementsStateCopyWith<$Res>  {
  factory $MovementsStateCopyWith(MovementsState value, $Res Function(MovementsState) _then) = _$MovementsStateCopyWithImpl;
@useResult
$Res call({
 MovementsStatus status, List<Movement> movimientos, String? nextCursor, bool loadingMore, bool loadMoreFailed, bool refreshing, bool refreshFailed, AccountFailure? failure
});




}
/// @nodoc
class _$MovementsStateCopyWithImpl<$Res>
    implements $MovementsStateCopyWith<$Res> {
  _$MovementsStateCopyWithImpl(this._self, this._then);

  final MovementsState _self;
  final $Res Function(MovementsState) _then;

/// Create a copy of MovementsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? movimientos = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? loadMoreFailed = null,Object? refreshing = null,Object? refreshFailed = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MovementsStatus,movimientos: null == movimientos ? _self.movimientos : movimientos // ignore: cast_nullable_to_non_nullable
as List<Movement>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshFailed: null == refreshFailed ? _self.refreshFailed : refreshFailed // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementsState].
extension MovementsStatePatterns on MovementsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementsState value)  $default,){
final _that = this;
switch (_that) {
case _MovementsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementsState value)?  $default,){
final _that = this;
switch (_that) {
case _MovementsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MovementsStatus status,  List<Movement> movimientos,  String? nextCursor,  bool loadingMore,  bool loadMoreFailed,  bool refreshing,  bool refreshFailed,  AccountFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementsState() when $default != null:
return $default(_that.status,_that.movimientos,_that.nextCursor,_that.loadingMore,_that.loadMoreFailed,_that.refreshing,_that.refreshFailed,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MovementsStatus status,  List<Movement> movimientos,  String? nextCursor,  bool loadingMore,  bool loadMoreFailed,  bool refreshing,  bool refreshFailed,  AccountFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _MovementsState():
return $default(_that.status,_that.movimientos,_that.nextCursor,_that.loadingMore,_that.loadMoreFailed,_that.refreshing,_that.refreshFailed,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MovementsStatus status,  List<Movement> movimientos,  String? nextCursor,  bool loadingMore,  bool loadMoreFailed,  bool refreshing,  bool refreshFailed,  AccountFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _MovementsState() when $default != null:
return $default(_that.status,_that.movimientos,_that.nextCursor,_that.loadingMore,_that.loadMoreFailed,_that.refreshing,_that.refreshFailed,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _MovementsState implements MovementsState {
  const _MovementsState({this.status = MovementsStatus.loading, final  List<Movement> movimientos = const <Movement>[], this.nextCursor, this.loadingMore = false, this.loadMoreFailed = false, this.refreshing = false, this.refreshFailed = false, this.failure}): _movimientos = movimientos;
  

@override@JsonKey() final  MovementsStatus status;
 final  List<Movement> _movimientos;
@override@JsonKey() List<Movement> get movimientos {
  if (_movimientos is EqualUnmodifiableListView) return _movimientos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_movimientos);
}

/// Cursor opaco de la siguiente página; `null` = no hay más.
@override final  String? nextCursor;
@override@JsonKey() final  bool loadingMore;
/// La última página pedida por scroll falló. El cursor se conserva: el
/// siguiente scroll reintenta la misma.
@override@JsonKey() final  bool loadMoreFailed;
@override@JsonKey() final  bool refreshing;
/// El último refresco falló y lo que se ve son datos anteriores.
@override@JsonKey() final  bool refreshFailed;
/// Solo con `status == error`.
@override final  AccountFailure? failure;

/// Create a copy of MovementsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementsStateCopyWith<_MovementsState> get copyWith => __$MovementsStateCopyWithImpl<_MovementsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._movimientos, _movimientos)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.loadMoreFailed, loadMoreFailed) || other.loadMoreFailed == loadMoreFailed)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.refreshFailed, refreshFailed) || other.refreshFailed == refreshFailed)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_movimientos),nextCursor,loadingMore,loadMoreFailed,refreshing,refreshFailed,failure);

@override
String toString() {
  return 'MovementsState(status: $status, movimientos: $movimientos, nextCursor: $nextCursor, loadingMore: $loadingMore, loadMoreFailed: $loadMoreFailed, refreshing: $refreshing, refreshFailed: $refreshFailed, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$MovementsStateCopyWith<$Res> implements $MovementsStateCopyWith<$Res> {
  factory _$MovementsStateCopyWith(_MovementsState value, $Res Function(_MovementsState) _then) = __$MovementsStateCopyWithImpl;
@override @useResult
$Res call({
 MovementsStatus status, List<Movement> movimientos, String? nextCursor, bool loadingMore, bool loadMoreFailed, bool refreshing, bool refreshFailed, AccountFailure? failure
});




}
/// @nodoc
class __$MovementsStateCopyWithImpl<$Res>
    implements _$MovementsStateCopyWith<$Res> {
  __$MovementsStateCopyWithImpl(this._self, this._then);

  final _MovementsState _self;
  final $Res Function(_MovementsState) _then;

/// Create a copy of MovementsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? movimientos = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? loadMoreFailed = null,Object? refreshing = null,Object? refreshFailed = null,Object? failure = freezed,}) {
  return _then(_MovementsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MovementsStatus,movimientos: null == movimientos ? _self._movimientos : movimientos // ignore: cast_nullable_to_non_nullable
as List<Movement>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreFailed: null == loadMoreFailed ? _self.loadMoreFailed : loadMoreFailed // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshFailed: null == refreshFailed ? _self.refreshFailed : refreshFailed // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}


}

// dart format on
