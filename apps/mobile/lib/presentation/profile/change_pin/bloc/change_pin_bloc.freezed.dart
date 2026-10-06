// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change_pin_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChangePinEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePinEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePinEvent()';
}


}

/// @nodoc
class $ChangePinEventCopyWith<$Res>  {
$ChangePinEventCopyWith(ChangePinEvent _, $Res Function(ChangePinEvent) __);
}


/// Adds pattern-matching-related methods to [ChangePinEvent].
extension ChangePinEventPatterns on ChangePinEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChangePinDigitPressed value)?  digitPressed,TResult Function( ChangePinBackspace value)?  backspace,TResult Function( ChangePinBack value)?  back,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChangePinDigitPressed() when digitPressed != null:
return digitPressed(_that);case ChangePinBackspace() when backspace != null:
return backspace(_that);case ChangePinBack() when back != null:
return back(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChangePinDigitPressed value)  digitPressed,required TResult Function( ChangePinBackspace value)  backspace,required TResult Function( ChangePinBack value)  back,}){
final _that = this;
switch (_that) {
case ChangePinDigitPressed():
return digitPressed(_that);case ChangePinBackspace():
return backspace(_that);case ChangePinBack():
return back(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChangePinDigitPressed value)?  digitPressed,TResult? Function( ChangePinBackspace value)?  backspace,TResult? Function( ChangePinBack value)?  back,}){
final _that = this;
switch (_that) {
case ChangePinDigitPressed() when digitPressed != null:
return digitPressed(_that);case ChangePinBackspace() when backspace != null:
return backspace(_that);case ChangePinBack() when back != null:
return back(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int digit)?  digitPressed,TResult Function()?  backspace,TResult Function()?  back,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChangePinDigitPressed() when digitPressed != null:
return digitPressed(_that.digit);case ChangePinBackspace() when backspace != null:
return backspace();case ChangePinBack() when back != null:
return back();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int digit)  digitPressed,required TResult Function()  backspace,required TResult Function()  back,}) {final _that = this;
switch (_that) {
case ChangePinDigitPressed():
return digitPressed(_that.digit);case ChangePinBackspace():
return backspace();case ChangePinBack():
return back();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int digit)?  digitPressed,TResult? Function()?  backspace,TResult? Function()?  back,}) {final _that = this;
switch (_that) {
case ChangePinDigitPressed() when digitPressed != null:
return digitPressed(_that.digit);case ChangePinBackspace() when backspace != null:
return backspace();case ChangePinBack() when back != null:
return back();case _:
  return null;

}
}

}

/// @nodoc


class ChangePinDigitPressed implements ChangePinEvent {
  const ChangePinDigitPressed(this.digit);
  

 final  int digit;

/// Create a copy of ChangePinEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangePinDigitPressedCopyWith<ChangePinDigitPressed> get copyWith => _$ChangePinDigitPressedCopyWithImpl<ChangePinDigitPressed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePinDigitPressed&&(identical(other.digit, digit) || other.digit == digit));
}


@override
int get hashCode => Object.hash(runtimeType,digit);

@override
String toString() {
  return 'ChangePinEvent.digitPressed(digit: $digit)';
}


}

/// @nodoc
abstract mixin class $ChangePinDigitPressedCopyWith<$Res> implements $ChangePinEventCopyWith<$Res> {
  factory $ChangePinDigitPressedCopyWith(ChangePinDigitPressed value, $Res Function(ChangePinDigitPressed) _then) = _$ChangePinDigitPressedCopyWithImpl;
@useResult
$Res call({
 int digit
});




}
/// @nodoc
class _$ChangePinDigitPressedCopyWithImpl<$Res>
    implements $ChangePinDigitPressedCopyWith<$Res> {
  _$ChangePinDigitPressedCopyWithImpl(this._self, this._then);

  final ChangePinDigitPressed _self;
  final $Res Function(ChangePinDigitPressed) _then;

/// Create a copy of ChangePinEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? digit = null,}) {
  return _then(ChangePinDigitPressed(
null == digit ? _self.digit : digit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ChangePinBackspace implements ChangePinEvent {
  const ChangePinBackspace();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePinBackspace);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePinEvent.backspace()';
}


}




/// @nodoc


class ChangePinBack implements ChangePinEvent {
  const ChangePinBack();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePinBack);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePinEvent.back()';
}


}




/// @nodoc
mixin _$ChangePinState {

 ChangePinStep get step;/// Dígitos del paso activo: lo único que pintan las casillas.
 String get pin; String get currentPin; String get newPin; ChangePinStatus get status; ChangePinError? get error; int? get attemptsLeft; DateTime? get lockedUntil; int get revokedSessions;
/// Create a copy of ChangePinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangePinStateCopyWith<ChangePinState> get copyWith => _$ChangePinStateCopyWithImpl<ChangePinState>(this as ChangePinState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePinState&&(identical(other.step, step) || other.step == step)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.currentPin, currentPin) || other.currentPin == currentPin)&&(identical(other.newPin, newPin) || other.newPin == newPin)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.revokedSessions, revokedSessions) || other.revokedSessions == revokedSessions));
}


@override
int get hashCode => Object.hash(runtimeType,step,pin,currentPin,newPin,status,error,attemptsLeft,lockedUntil,revokedSessions);

@override
String toString() {
  return 'ChangePinState(step: $step, pin: $pin, currentPin: $currentPin, newPin: $newPin, status: $status, error: $error, attemptsLeft: $attemptsLeft, lockedUntil: $lockedUntil, revokedSessions: $revokedSessions)';
}


}

/// @nodoc
abstract mixin class $ChangePinStateCopyWith<$Res>  {
  factory $ChangePinStateCopyWith(ChangePinState value, $Res Function(ChangePinState) _then) = _$ChangePinStateCopyWithImpl;
@useResult
$Res call({
 ChangePinStep step, String pin, String currentPin, String newPin, ChangePinStatus status, ChangePinError? error, int? attemptsLeft, DateTime? lockedUntil, int revokedSessions
});




}
/// @nodoc
class _$ChangePinStateCopyWithImpl<$Res>
    implements $ChangePinStateCopyWith<$Res> {
  _$ChangePinStateCopyWithImpl(this._self, this._then);

  final ChangePinState _self;
  final $Res Function(ChangePinState) _then;

/// Create a copy of ChangePinState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? pin = null,Object? currentPin = null,Object? newPin = null,Object? status = null,Object? error = freezed,Object? attemptsLeft = freezed,Object? lockedUntil = freezed,Object? revokedSessions = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ChangePinStep,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,currentPin: null == currentPin ? _self.currentPin : currentPin // ignore: cast_nullable_to_non_nullable
as String,newPin: null == newPin ? _self.newPin : newPin // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChangePinStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ChangePinError?,attemptsLeft: freezed == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int?,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedSessions: null == revokedSessions ? _self.revokedSessions : revokedSessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangePinState].
extension ChangePinStatePatterns on ChangePinState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangePinState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangePinState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangePinState value)  $default,){
final _that = this;
switch (_that) {
case _ChangePinState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangePinState value)?  $default,){
final _that = this;
switch (_that) {
case _ChangePinState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChangePinStep step,  String pin,  String currentPin,  String newPin,  ChangePinStatus status,  ChangePinError? error,  int? attemptsLeft,  DateTime? lockedUntil,  int revokedSessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangePinState() when $default != null:
return $default(_that.step,_that.pin,_that.currentPin,_that.newPin,_that.status,_that.error,_that.attemptsLeft,_that.lockedUntil,_that.revokedSessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChangePinStep step,  String pin,  String currentPin,  String newPin,  ChangePinStatus status,  ChangePinError? error,  int? attemptsLeft,  DateTime? lockedUntil,  int revokedSessions)  $default,) {final _that = this;
switch (_that) {
case _ChangePinState():
return $default(_that.step,_that.pin,_that.currentPin,_that.newPin,_that.status,_that.error,_that.attemptsLeft,_that.lockedUntil,_that.revokedSessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChangePinStep step,  String pin,  String currentPin,  String newPin,  ChangePinStatus status,  ChangePinError? error,  int? attemptsLeft,  DateTime? lockedUntil,  int revokedSessions)?  $default,) {final _that = this;
switch (_that) {
case _ChangePinState() when $default != null:
return $default(_that.step,_that.pin,_that.currentPin,_that.newPin,_that.status,_that.error,_that.attemptsLeft,_that.lockedUntil,_that.revokedSessions);case _:
  return null;

}
}

}

/// @nodoc


class _ChangePinState implements ChangePinState {
  const _ChangePinState({this.step = ChangePinStep.actual, this.pin = '', this.currentPin = '', this.newPin = '', this.status = ChangePinStatus.idle, this.error, this.attemptsLeft, this.lockedUntil, this.revokedSessions = 0});
  

@override@JsonKey() final  ChangePinStep step;
/// Dígitos del paso activo: lo único que pintan las casillas.
@override@JsonKey() final  String pin;
@override@JsonKey() final  String currentPin;
@override@JsonKey() final  String newPin;
@override@JsonKey() final  ChangePinStatus status;
@override final  ChangePinError? error;
@override final  int? attemptsLeft;
@override final  DateTime? lockedUntil;
@override@JsonKey() final  int revokedSessions;

/// Create a copy of ChangePinState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangePinStateCopyWith<_ChangePinState> get copyWith => __$ChangePinStateCopyWithImpl<_ChangePinState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangePinState&&(identical(other.step, step) || other.step == step)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.currentPin, currentPin) || other.currentPin == currentPin)&&(identical(other.newPin, newPin) || other.newPin == newPin)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.revokedSessions, revokedSessions) || other.revokedSessions == revokedSessions));
}


@override
int get hashCode => Object.hash(runtimeType,step,pin,currentPin,newPin,status,error,attemptsLeft,lockedUntil,revokedSessions);

@override
String toString() {
  return 'ChangePinState(step: $step, pin: $pin, currentPin: $currentPin, newPin: $newPin, status: $status, error: $error, attemptsLeft: $attemptsLeft, lockedUntil: $lockedUntil, revokedSessions: $revokedSessions)';
}


}

/// @nodoc
abstract mixin class _$ChangePinStateCopyWith<$Res> implements $ChangePinStateCopyWith<$Res> {
  factory _$ChangePinStateCopyWith(_ChangePinState value, $Res Function(_ChangePinState) _then) = __$ChangePinStateCopyWithImpl;
@override @useResult
$Res call({
 ChangePinStep step, String pin, String currentPin, String newPin, ChangePinStatus status, ChangePinError? error, int? attemptsLeft, DateTime? lockedUntil, int revokedSessions
});




}
/// @nodoc
class __$ChangePinStateCopyWithImpl<$Res>
    implements _$ChangePinStateCopyWith<$Res> {
  __$ChangePinStateCopyWithImpl(this._self, this._then);

  final _ChangePinState _self;
  final $Res Function(_ChangePinState) _then;

/// Create a copy of ChangePinState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? pin = null,Object? currentPin = null,Object? newPin = null,Object? status = null,Object? error = freezed,Object? attemptsLeft = freezed,Object? lockedUntil = freezed,Object? revokedSessions = null,}) {
  return _then(_ChangePinState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ChangePinStep,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,currentPin: null == currentPin ? _self.currentPin : currentPin // ignore: cast_nullable_to_non_nullable
as String,newPin: null == newPin ? _self.newPin : newPin // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChangePinStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ChangePinError?,attemptsLeft: freezed == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int?,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedSessions: null == revokedSessions ? _self.revokedSessions : revokedSessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
