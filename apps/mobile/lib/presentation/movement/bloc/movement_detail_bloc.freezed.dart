// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'movement_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MovementDetailEvent {

 String get transactionId;
/// Create a copy of MovementDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementDetailEventCopyWith<MovementDetailEvent> get copyWith => _$MovementDetailEventCopyWithImpl<MovementDetailEvent>(this as MovementDetailEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementDetailEvent&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId));
}


@override
int get hashCode => Object.hash(runtimeType,transactionId);

@override
String toString() {
  return 'MovementDetailEvent(transactionId: $transactionId)';
}


}

/// @nodoc
abstract mixin class $MovementDetailEventCopyWith<$Res>  {
  factory $MovementDetailEventCopyWith(MovementDetailEvent value, $Res Function(MovementDetailEvent) _then) = _$MovementDetailEventCopyWithImpl;
@useResult
$Res call({
 String transactionId
});




}
/// @nodoc
class _$MovementDetailEventCopyWithImpl<$Res>
    implements $MovementDetailEventCopyWith<$Res> {
  _$MovementDetailEventCopyWithImpl(this._self, this._then);

  final MovementDetailEvent _self;
  final $Res Function(MovementDetailEvent) _then;

/// Create a copy of MovementDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transactionId = null,}) {
  return _then(_self.copyWith(
transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementDetailEvent].
extension MovementDetailEventPatterns on MovementDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MovementDetailOpened value)?  opened,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MovementDetailOpened() when opened != null:
return opened(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MovementDetailOpened value)  opened,}){
final _that = this;
switch (_that) {
case MovementDetailOpened():
return opened(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MovementDetailOpened value)?  opened,}){
final _that = this;
switch (_that) {
case MovementDetailOpened() when opened != null:
return opened(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String transactionId)?  opened,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MovementDetailOpened() when opened != null:
return opened(_that.transactionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String transactionId)  opened,}) {final _that = this;
switch (_that) {
case MovementDetailOpened():
return opened(_that.transactionId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String transactionId)?  opened,}) {final _that = this;
switch (_that) {
case MovementDetailOpened() when opened != null:
return opened(_that.transactionId);case _:
  return null;

}
}

}

/// @nodoc


class MovementDetailOpened implements MovementDetailEvent {
  const MovementDetailOpened(this.transactionId);
  

@override final  String transactionId;

/// Create a copy of MovementDetailEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementDetailOpenedCopyWith<MovementDetailOpened> get copyWith => _$MovementDetailOpenedCopyWithImpl<MovementDetailOpened>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementDetailOpened&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId));
}


@override
int get hashCode => Object.hash(runtimeType,transactionId);

@override
String toString() {
  return 'MovementDetailEvent.opened(transactionId: $transactionId)';
}


}

/// @nodoc
abstract mixin class $MovementDetailOpenedCopyWith<$Res> implements $MovementDetailEventCopyWith<$Res> {
  factory $MovementDetailOpenedCopyWith(MovementDetailOpened value, $Res Function(MovementDetailOpened) _then) = _$MovementDetailOpenedCopyWithImpl;
@override @useResult
$Res call({
 String transactionId
});




}
/// @nodoc
class _$MovementDetailOpenedCopyWithImpl<$Res>
    implements $MovementDetailOpenedCopyWith<$Res> {
  _$MovementDetailOpenedCopyWithImpl(this._self, this._then);

  final MovementDetailOpened _self;
  final $Res Function(MovementDetailOpened) _then;

/// Create a copy of MovementDetailEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transactionId = null,}) {
  return _then(MovementDetailOpened(
null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MovementDetailState {

 MovementDetailStatus get status;/// Solo con `status == ready`.
 MovementDetail? get detalle;/// Solo con `status == error`.
 AccountFailure? get failure;
/// Create a copy of MovementDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementDetailStateCopyWith<MovementDetailState> get copyWith => _$MovementDetailStateCopyWithImpl<MovementDetailState>(this as MovementDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementDetailState&&(identical(other.status, status) || other.status == status)&&(identical(other.detalle, detalle) || other.detalle == detalle)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,detalle,failure);

@override
String toString() {
  return 'MovementDetailState(status: $status, detalle: $detalle, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $MovementDetailStateCopyWith<$Res>  {
  factory $MovementDetailStateCopyWith(MovementDetailState value, $Res Function(MovementDetailState) _then) = _$MovementDetailStateCopyWithImpl;
@useResult
$Res call({
 MovementDetailStatus status, MovementDetail? detalle, AccountFailure? failure
});




}
/// @nodoc
class _$MovementDetailStateCopyWithImpl<$Res>
    implements $MovementDetailStateCopyWith<$Res> {
  _$MovementDetailStateCopyWithImpl(this._self, this._then);

  final MovementDetailState _self;
  final $Res Function(MovementDetailState) _then;

/// Create a copy of MovementDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? detalle = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MovementDetailStatus,detalle: freezed == detalle ? _self.detalle : detalle // ignore: cast_nullable_to_non_nullable
as MovementDetail?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementDetailState].
extension MovementDetailStatePatterns on MovementDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementDetailState value)  $default,){
final _that = this;
switch (_that) {
case _MovementDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _MovementDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MovementDetailStatus status,  MovementDetail? detalle,  AccountFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementDetailState() when $default != null:
return $default(_that.status,_that.detalle,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MovementDetailStatus status,  MovementDetail? detalle,  AccountFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _MovementDetailState():
return $default(_that.status,_that.detalle,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MovementDetailStatus status,  MovementDetail? detalle,  AccountFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _MovementDetailState() when $default != null:
return $default(_that.status,_that.detalle,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _MovementDetailState implements MovementDetailState {
  const _MovementDetailState({this.status = MovementDetailStatus.loading, this.detalle, this.failure});
  

@override@JsonKey() final  MovementDetailStatus status;
/// Solo con `status == ready`.
@override final  MovementDetail? detalle;
/// Solo con `status == error`.
@override final  AccountFailure? failure;

/// Create a copy of MovementDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementDetailStateCopyWith<_MovementDetailState> get copyWith => __$MovementDetailStateCopyWithImpl<_MovementDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementDetailState&&(identical(other.status, status) || other.status == status)&&(identical(other.detalle, detalle) || other.detalle == detalle)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,detalle,failure);

@override
String toString() {
  return 'MovementDetailState(status: $status, detalle: $detalle, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$MovementDetailStateCopyWith<$Res> implements $MovementDetailStateCopyWith<$Res> {
  factory _$MovementDetailStateCopyWith(_MovementDetailState value, $Res Function(_MovementDetailState) _then) = __$MovementDetailStateCopyWithImpl;
@override @useResult
$Res call({
 MovementDetailStatus status, MovementDetail? detalle, AccountFailure? failure
});




}
/// @nodoc
class __$MovementDetailStateCopyWithImpl<$Res>
    implements _$MovementDetailStateCopyWith<$Res> {
  __$MovementDetailStateCopyWithImpl(this._self, this._then);

  final _MovementDetailState _self;
  final $Res Function(_MovementDetailState) _then;

/// Create a copy of MovementDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? detalle = freezed,Object? failure = freezed,}) {
  return _then(_MovementDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MovementDetailStatus,detalle: freezed == detalle ? _self.detalle : detalle // ignore: cast_nullable_to_non_nullable
as MovementDetail?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}


}

// dart format on
