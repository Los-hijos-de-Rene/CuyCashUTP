// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reset_pin_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResetPinEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPinEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ResetPinEvent()';
}


}

/// @nodoc
class $ResetPinEventCopyWith<$Res>  {
$ResetPinEventCopyWith(ResetPinEvent _, $Res Function(ResetPinEvent) __);
}


/// Adds pattern-matching-related methods to [ResetPinEvent].
extension ResetPinEventPatterns on ResetPinEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ResetPinDigitPressed value)?  digitPressed,TResult Function( ResetPinBackspace value)?  backspace,TResult Function( ResetPinBackToFirstStep value)?  backToFirstStep,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ResetPinDigitPressed() when digitPressed != null:
return digitPressed(_that);case ResetPinBackspace() when backspace != null:
return backspace(_that);case ResetPinBackToFirstStep() when backToFirstStep != null:
return backToFirstStep(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ResetPinDigitPressed value)  digitPressed,required TResult Function( ResetPinBackspace value)  backspace,required TResult Function( ResetPinBackToFirstStep value)  backToFirstStep,}){
final _that = this;
switch (_that) {
case ResetPinDigitPressed():
return digitPressed(_that);case ResetPinBackspace():
return backspace(_that);case ResetPinBackToFirstStep():
return backToFirstStep(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ResetPinDigitPressed value)?  digitPressed,TResult? Function( ResetPinBackspace value)?  backspace,TResult? Function( ResetPinBackToFirstStep value)?  backToFirstStep,}){
final _that = this;
switch (_that) {
case ResetPinDigitPressed() when digitPressed != null:
return digitPressed(_that);case ResetPinBackspace() when backspace != null:
return backspace(_that);case ResetPinBackToFirstStep() when backToFirstStep != null:
return backToFirstStep(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int digit)?  digitPressed,TResult Function()?  backspace,TResult Function()?  backToFirstStep,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ResetPinDigitPressed() when digitPressed != null:
return digitPressed(_that.digit);case ResetPinBackspace() when backspace != null:
return backspace();case ResetPinBackToFirstStep() when backToFirstStep != null:
return backToFirstStep();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int digit)  digitPressed,required TResult Function()  backspace,required TResult Function()  backToFirstStep,}) {final _that = this;
switch (_that) {
case ResetPinDigitPressed():
return digitPressed(_that.digit);case ResetPinBackspace():
return backspace();case ResetPinBackToFirstStep():
return backToFirstStep();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int digit)?  digitPressed,TResult? Function()?  backspace,TResult? Function()?  backToFirstStep,}) {final _that = this;
switch (_that) {
case ResetPinDigitPressed() when digitPressed != null:
return digitPressed(_that.digit);case ResetPinBackspace() when backspace != null:
return backspace();case ResetPinBackToFirstStep() when backToFirstStep != null:
return backToFirstStep();case _:
  return null;

}
}

}

/// @nodoc


class ResetPinDigitPressed implements ResetPinEvent {
  const ResetPinDigitPressed(this.digit);
  

 final  int digit;

/// Create a copy of ResetPinEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPinDigitPressedCopyWith<ResetPinDigitPressed> get copyWith => _$ResetPinDigitPressedCopyWithImpl<ResetPinDigitPressed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPinDigitPressed&&(identical(other.digit, digit) || other.digit == digit));
}


@override
int get hashCode => Object.hash(runtimeType,digit);

@override
String toString() {
  return 'ResetPinEvent.digitPressed(digit: $digit)';
}


}

/// @nodoc
abstract mixin class $ResetPinDigitPressedCopyWith<$Res> implements $ResetPinEventCopyWith<$Res> {
  factory $ResetPinDigitPressedCopyWith(ResetPinDigitPressed value, $Res Function(ResetPinDigitPressed) _then) = _$ResetPinDigitPressedCopyWithImpl;
@useResult
$Res call({
 int digit
});




}
/// @nodoc
class _$ResetPinDigitPressedCopyWithImpl<$Res>
    implements $ResetPinDigitPressedCopyWith<$Res> {
  _$ResetPinDigitPressedCopyWithImpl(this._self, this._then);

  final ResetPinDigitPressed _self;
  final $Res Function(ResetPinDigitPressed) _then;

/// Create a copy of ResetPinEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? digit = null,}) {
  return _then(ResetPinDigitPressed(
null == digit ? _self.digit : digit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ResetPinBackspace implements ResetPinEvent {
  const ResetPinBackspace();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPinBackspace);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ResetPinEvent.backspace()';
}


}




/// @nodoc


class ResetPinBackToFirstStep implements ResetPinEvent {
  const ResetPinBackToFirstStep();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPinBackToFirstStep);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ResetPinEvent.backToFirstStep()';
}


}




/// @nodoc
mixin _$ResetPinState {

 ResetPinStep get step;/// Dígitos del paso ACTIVO. Es lo único que pintan las casillas.
 String get pin;/// PIN elegido en el paso 1, a la espera de confirmación.
 String get chosenPin; ResetPinStatus get status; bool get done; ResetPinError? get error;
/// Create a copy of ResetPinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPinStateCopyWith<ResetPinState> get copyWith => _$ResetPinStateCopyWithImpl<ResetPinState>(this as ResetPinState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPinState&&(identical(other.step, step) || other.step == step)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.chosenPin, chosenPin) || other.chosenPin == chosenPin)&&(identical(other.status, status) || other.status == status)&&(identical(other.done, done) || other.done == done)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,step,pin,chosenPin,status,done,error);

@override
String toString() {
  return 'ResetPinState(step: $step, pin: $pin, chosenPin: $chosenPin, status: $status, done: $done, error: $error)';
}


}

/// @nodoc
abstract mixin class $ResetPinStateCopyWith<$Res>  {
  factory $ResetPinStateCopyWith(ResetPinState value, $Res Function(ResetPinState) _then) = _$ResetPinStateCopyWithImpl;
@useResult
$Res call({
 ResetPinStep step, String pin, String chosenPin, ResetPinStatus status, bool done, ResetPinError? error
});




}
/// @nodoc
class _$ResetPinStateCopyWithImpl<$Res>
    implements $ResetPinStateCopyWith<$Res> {
  _$ResetPinStateCopyWithImpl(this._self, this._then);

  final ResetPinState _self;
  final $Res Function(ResetPinState) _then;

/// Create a copy of ResetPinState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? pin = null,Object? chosenPin = null,Object? status = null,Object? done = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ResetPinStep,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,chosenPin: null == chosenPin ? _self.chosenPin : chosenPin // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ResetPinStatus,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ResetPinError?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResetPinState].
extension ResetPinStatePatterns on ResetPinState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResetPinState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResetPinState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResetPinState value)  $default,){
final _that = this;
switch (_that) {
case _ResetPinState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResetPinState value)?  $default,){
final _that = this;
switch (_that) {
case _ResetPinState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ResetPinStep step,  String pin,  String chosenPin,  ResetPinStatus status,  bool done,  ResetPinError? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResetPinState() when $default != null:
return $default(_that.step,_that.pin,_that.chosenPin,_that.status,_that.done,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ResetPinStep step,  String pin,  String chosenPin,  ResetPinStatus status,  bool done,  ResetPinError? error)  $default,) {final _that = this;
switch (_that) {
case _ResetPinState():
return $default(_that.step,_that.pin,_that.chosenPin,_that.status,_that.done,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ResetPinStep step,  String pin,  String chosenPin,  ResetPinStatus status,  bool done,  ResetPinError? error)?  $default,) {final _that = this;
switch (_that) {
case _ResetPinState() when $default != null:
return $default(_that.step,_that.pin,_that.chosenPin,_that.status,_that.done,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ResetPinState extends ResetPinState {
  const _ResetPinState({this.step = ResetPinStep.crear, this.pin = '', this.chosenPin = '', this.status = ResetPinStatus.idle, this.done = false, this.error}): super._();
  

@override@JsonKey() final  ResetPinStep step;
/// Dígitos del paso ACTIVO. Es lo único que pintan las casillas.
@override@JsonKey() final  String pin;
/// PIN elegido en el paso 1, a la espera de confirmación.
@override@JsonKey() final  String chosenPin;
@override@JsonKey() final  ResetPinStatus status;
@override@JsonKey() final  bool done;
@override final  ResetPinError? error;

/// Create a copy of ResetPinState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResetPinStateCopyWith<_ResetPinState> get copyWith => __$ResetPinStateCopyWithImpl<_ResetPinState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResetPinState&&(identical(other.step, step) || other.step == step)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.chosenPin, chosenPin) || other.chosenPin == chosenPin)&&(identical(other.status, status) || other.status == status)&&(identical(other.done, done) || other.done == done)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,step,pin,chosenPin,status,done,error);

@override
String toString() {
  return 'ResetPinState(step: $step, pin: $pin, chosenPin: $chosenPin, status: $status, done: $done, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ResetPinStateCopyWith<$Res> implements $ResetPinStateCopyWith<$Res> {
  factory _$ResetPinStateCopyWith(_ResetPinState value, $Res Function(_ResetPinState) _then) = __$ResetPinStateCopyWithImpl;
@override @useResult
$Res call({
 ResetPinStep step, String pin, String chosenPin, ResetPinStatus status, bool done, ResetPinError? error
});




}
/// @nodoc
class __$ResetPinStateCopyWithImpl<$Res>
    implements _$ResetPinStateCopyWith<$Res> {
  __$ResetPinStateCopyWithImpl(this._self, this._then);

  final _ResetPinState _self;
  final $Res Function(_ResetPinState) _then;

/// Create a copy of ResetPinState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? pin = null,Object? chosenPin = null,Object? status = null,Object? done = null,Object? error = freezed,}) {
  return _then(_ResetPinState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ResetPinStep,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,chosenPin: null == chosenPin ? _self.chosenPin : chosenPin // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ResetPinStatus,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ResetPinError?,
  ));
}


}

// dart format on
