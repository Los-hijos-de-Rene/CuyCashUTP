// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_data_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PersonalDataEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalDataEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PersonalDataEvent()';
}


}

/// @nodoc
class $PersonalDataEventCopyWith<$Res>  {
$PersonalDataEventCopyWith(PersonalDataEvent _, $Res Function(PersonalDataEvent) __);
}


/// Adds pattern-matching-related methods to [PersonalDataEvent].
extension PersonalDataEventPatterns on PersonalDataEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PersonalDataStarted value)?  started,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PersonalDataStarted() when started != null:
return started(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PersonalDataStarted value)  started,}){
final _that = this;
switch (_that) {
case PersonalDataStarted():
return started(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PersonalDataStarted value)?  started,}){
final _that = this;
switch (_that) {
case PersonalDataStarted() when started != null:
return started(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PersonalDataStarted() when started != null:
return started();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,}) {final _that = this;
switch (_that) {
case PersonalDataStarted():
return started();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,}) {final _that = this;
switch (_that) {
case PersonalDataStarted() when started != null:
return started();case _:
  return null;

}
}

}

/// @nodoc


class PersonalDataStarted implements PersonalDataEvent {
  const PersonalDataStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalDataStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PersonalDataEvent.started()';
}


}




/// @nodoc
mixin _$PersonalDataState {

 PersonalDataStatus get status; PersonalData? get datos;
/// Create a copy of PersonalDataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalDataStateCopyWith<PersonalDataState> get copyWith => _$PersonalDataStateCopyWithImpl<PersonalDataState>(this as PersonalDataState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalDataState&&(identical(other.status, status) || other.status == status)&&(identical(other.datos, datos) || other.datos == datos));
}


@override
int get hashCode => Object.hash(runtimeType,status,datos);

@override
String toString() {
  return 'PersonalDataState(status: $status, datos: $datos)';
}


}

/// @nodoc
abstract mixin class $PersonalDataStateCopyWith<$Res>  {
  factory $PersonalDataStateCopyWith(PersonalDataState value, $Res Function(PersonalDataState) _then) = _$PersonalDataStateCopyWithImpl;
@useResult
$Res call({
 PersonalDataStatus status, PersonalData? datos
});




}
/// @nodoc
class _$PersonalDataStateCopyWithImpl<$Res>
    implements $PersonalDataStateCopyWith<$Res> {
  _$PersonalDataStateCopyWithImpl(this._self, this._then);

  final PersonalDataState _self;
  final $Res Function(PersonalDataState) _then;

/// Create a copy of PersonalDataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? datos = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PersonalDataStatus,datos: freezed == datos ? _self.datos : datos // ignore: cast_nullable_to_non_nullable
as PersonalData?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalDataState].
extension PersonalDataStatePatterns on PersonalDataState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalDataState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalDataState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalDataState value)  $default,){
final _that = this;
switch (_that) {
case _PersonalDataState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalDataState value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalDataState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PersonalDataStatus status,  PersonalData? datos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalDataState() when $default != null:
return $default(_that.status,_that.datos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PersonalDataStatus status,  PersonalData? datos)  $default,) {final _that = this;
switch (_that) {
case _PersonalDataState():
return $default(_that.status,_that.datos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PersonalDataStatus status,  PersonalData? datos)?  $default,) {final _that = this;
switch (_that) {
case _PersonalDataState() when $default != null:
return $default(_that.status,_that.datos);case _:
  return null;

}
}

}

/// @nodoc


class _PersonalDataState implements PersonalDataState {
  const _PersonalDataState({this.status = PersonalDataStatus.loading, this.datos});
  

@override@JsonKey() final  PersonalDataStatus status;
@override final  PersonalData? datos;

/// Create a copy of PersonalDataState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalDataStateCopyWith<_PersonalDataState> get copyWith => __$PersonalDataStateCopyWithImpl<_PersonalDataState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalDataState&&(identical(other.status, status) || other.status == status)&&(identical(other.datos, datos) || other.datos == datos));
}


@override
int get hashCode => Object.hash(runtimeType,status,datos);

@override
String toString() {
  return 'PersonalDataState(status: $status, datos: $datos)';
}


}

/// @nodoc
abstract mixin class _$PersonalDataStateCopyWith<$Res> implements $PersonalDataStateCopyWith<$Res> {
  factory _$PersonalDataStateCopyWith(_PersonalDataState value, $Res Function(_PersonalDataState) _then) = __$PersonalDataStateCopyWithImpl;
@override @useResult
$Res call({
 PersonalDataStatus status, PersonalData? datos
});




}
/// @nodoc
class __$PersonalDataStateCopyWithImpl<$Res>
    implements _$PersonalDataStateCopyWith<$Res> {
  __$PersonalDataStateCopyWithImpl(this._self, this._then);

  final _PersonalDataState _self;
  final $Res Function(_PersonalDataState) _then;

/// Create a copy of PersonalDataState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? datos = freezed,}) {
  return _then(_PersonalDataState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PersonalDataStatus,datos: freezed == datos ? _self.datos : datos // ignore: cast_nullable_to_non_nullable
as PersonalData?,
  ));
}


}

// dart format on
