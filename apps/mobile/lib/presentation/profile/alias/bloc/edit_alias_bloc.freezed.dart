// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_alias_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditAliasEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditAliasEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditAliasEvent()';
}


}

/// @nodoc
class $EditAliasEventCopyWith<$Res>  {
$EditAliasEventCopyWith(EditAliasEvent _, $Res Function(EditAliasEvent) __);
}


/// Adds pattern-matching-related methods to [EditAliasEvent].
extension EditAliasEventPatterns on EditAliasEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditAliasChanged value)?  changed,TResult Function( EditAliasSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditAliasChanged() when changed != null:
return changed(_that);case EditAliasSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditAliasChanged value)  changed,required TResult Function( EditAliasSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case EditAliasChanged():
return changed(_that);case EditAliasSubmitted():
return submitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditAliasChanged value)?  changed,TResult? Function( EditAliasSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case EditAliasChanged() when changed != null:
return changed(_that);case EditAliasSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String input)?  changed,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditAliasChanged() when changed != null:
return changed(_that.input);case EditAliasSubmitted() when submitted != null:
return submitted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String input)  changed,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case EditAliasChanged():
return changed(_that.input);case EditAliasSubmitted():
return submitted();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String input)?  changed,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case EditAliasChanged() when changed != null:
return changed(_that.input);case EditAliasSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class EditAliasChanged implements EditAliasEvent {
  const EditAliasChanged(this.input);
  

 final  String input;

/// Create a copy of EditAliasEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditAliasChangedCopyWith<EditAliasChanged> get copyWith => _$EditAliasChangedCopyWithImpl<EditAliasChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditAliasChanged&&(identical(other.input, input) || other.input == input));
}


@override
int get hashCode => Object.hash(runtimeType,input);

@override
String toString() {
  return 'EditAliasEvent.changed(input: $input)';
}


}

/// @nodoc
abstract mixin class $EditAliasChangedCopyWith<$Res> implements $EditAliasEventCopyWith<$Res> {
  factory $EditAliasChangedCopyWith(EditAliasChanged value, $Res Function(EditAliasChanged) _then) = _$EditAliasChangedCopyWithImpl;
@useResult
$Res call({
 String input
});




}
/// @nodoc
class _$EditAliasChangedCopyWithImpl<$Res>
    implements $EditAliasChangedCopyWith<$Res> {
  _$EditAliasChangedCopyWithImpl(this._self, this._then);

  final EditAliasChanged _self;
  final $Res Function(EditAliasChanged) _then;

/// Create a copy of EditAliasEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? input = null,}) {
  return _then(EditAliasChanged(
null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class EditAliasSubmitted implements EditAliasEvent {
  const EditAliasSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditAliasSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditAliasEvent.submitted()';
}


}




/// @nodoc
mixin _$EditAliasState {

 String get initial; String get input; EditAliasStatus get status; AliasError? get error;
/// Create a copy of EditAliasState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditAliasStateCopyWith<EditAliasState> get copyWith => _$EditAliasStateCopyWithImpl<EditAliasState>(this as EditAliasState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditAliasState&&(identical(other.initial, initial) || other.initial == initial)&&(identical(other.input, input) || other.input == input)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,initial,input,status,error);

@override
String toString() {
  return 'EditAliasState(initial: $initial, input: $input, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class $EditAliasStateCopyWith<$Res>  {
  factory $EditAliasStateCopyWith(EditAliasState value, $Res Function(EditAliasState) _then) = _$EditAliasStateCopyWithImpl;
@useResult
$Res call({
 String initial, String input, EditAliasStatus status, AliasError? error
});




}
/// @nodoc
class _$EditAliasStateCopyWithImpl<$Res>
    implements $EditAliasStateCopyWith<$Res> {
  _$EditAliasStateCopyWithImpl(this._self, this._then);

  final EditAliasState _self;
  final $Res Function(EditAliasState) _then;

/// Create a copy of EditAliasState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? initial = null,Object? input = null,Object? status = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EditAliasStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AliasError?,
  ));
}

}


/// Adds pattern-matching-related methods to [EditAliasState].
extension EditAliasStatePatterns on EditAliasState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditAliasState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditAliasState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditAliasState value)  $default,){
final _that = this;
switch (_that) {
case _EditAliasState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditAliasState value)?  $default,){
final _that = this;
switch (_that) {
case _EditAliasState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String initial,  String input,  EditAliasStatus status,  AliasError? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditAliasState() when $default != null:
return $default(_that.initial,_that.input,_that.status,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String initial,  String input,  EditAliasStatus status,  AliasError? error)  $default,) {final _that = this;
switch (_that) {
case _EditAliasState():
return $default(_that.initial,_that.input,_that.status,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String initial,  String input,  EditAliasStatus status,  AliasError? error)?  $default,) {final _that = this;
switch (_that) {
case _EditAliasState() when $default != null:
return $default(_that.initial,_that.input,_that.status,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _EditAliasState extends EditAliasState {
  const _EditAliasState({required this.initial, this.input = '', this.status = EditAliasStatus.editing, this.error}): super._();
  

@override final  String initial;
@override@JsonKey() final  String input;
@override@JsonKey() final  EditAliasStatus status;
@override final  AliasError? error;

/// Create a copy of EditAliasState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditAliasStateCopyWith<_EditAliasState> get copyWith => __$EditAliasStateCopyWithImpl<_EditAliasState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditAliasState&&(identical(other.initial, initial) || other.initial == initial)&&(identical(other.input, input) || other.input == input)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,initial,input,status,error);

@override
String toString() {
  return 'EditAliasState(initial: $initial, input: $input, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class _$EditAliasStateCopyWith<$Res> implements $EditAliasStateCopyWith<$Res> {
  factory _$EditAliasStateCopyWith(_EditAliasState value, $Res Function(_EditAliasState) _then) = __$EditAliasStateCopyWithImpl;
@override @useResult
$Res call({
 String initial, String input, EditAliasStatus status, AliasError? error
});




}
/// @nodoc
class __$EditAliasStateCopyWithImpl<$Res>
    implements _$EditAliasStateCopyWith<$Res> {
  __$EditAliasStateCopyWithImpl(this._self, this._then);

  final _EditAliasState _self;
  final $Res Function(_EditAliasState) _then;

/// Create a copy of EditAliasState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? initial = null,Object? input = null,Object? status = null,Object? error = freezed,}) {
  return _then(_EditAliasState(
initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as String,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EditAliasStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AliasError?,
  ));
}


}

// dart format on
