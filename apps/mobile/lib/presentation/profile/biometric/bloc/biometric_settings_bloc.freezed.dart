// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'biometric_settings_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BiometricSettingsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BiometricSettingsEvent()';
}


}

/// @nodoc
class $BiometricSettingsEventCopyWith<$Res>  {
$BiometricSettingsEventCopyWith(BiometricSettingsEvent _, $Res Function(BiometricSettingsEvent) __);
}


/// Adds pattern-matching-related methods to [BiometricSettingsEvent].
extension BiometricSettingsEventPatterns on BiometricSettingsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BiometricSettingsStarted value)?  started,TResult Function( BiometricSettingsEnableRequested value)?  enableRequested,TResult Function( BiometricSettingsPinDigit value)?  pinDigit,TResult Function( BiometricSettingsPinBackspace value)?  pinBackspace,TResult Function( BiometricSettingsPinCancelled value)?  pinCancelled,TResult Function( BiometricSettingsDisableRequested value)?  disableRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BiometricSettingsStarted() when started != null:
return started(_that);case BiometricSettingsEnableRequested() when enableRequested != null:
return enableRequested(_that);case BiometricSettingsPinDigit() when pinDigit != null:
return pinDigit(_that);case BiometricSettingsPinBackspace() when pinBackspace != null:
return pinBackspace(_that);case BiometricSettingsPinCancelled() when pinCancelled != null:
return pinCancelled(_that);case BiometricSettingsDisableRequested() when disableRequested != null:
return disableRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BiometricSettingsStarted value)  started,required TResult Function( BiometricSettingsEnableRequested value)  enableRequested,required TResult Function( BiometricSettingsPinDigit value)  pinDigit,required TResult Function( BiometricSettingsPinBackspace value)  pinBackspace,required TResult Function( BiometricSettingsPinCancelled value)  pinCancelled,required TResult Function( BiometricSettingsDisableRequested value)  disableRequested,}){
final _that = this;
switch (_that) {
case BiometricSettingsStarted():
return started(_that);case BiometricSettingsEnableRequested():
return enableRequested(_that);case BiometricSettingsPinDigit():
return pinDigit(_that);case BiometricSettingsPinBackspace():
return pinBackspace(_that);case BiometricSettingsPinCancelled():
return pinCancelled(_that);case BiometricSettingsDisableRequested():
return disableRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BiometricSettingsStarted value)?  started,TResult? Function( BiometricSettingsEnableRequested value)?  enableRequested,TResult? Function( BiometricSettingsPinDigit value)?  pinDigit,TResult? Function( BiometricSettingsPinBackspace value)?  pinBackspace,TResult? Function( BiometricSettingsPinCancelled value)?  pinCancelled,TResult? Function( BiometricSettingsDisableRequested value)?  disableRequested,}){
final _that = this;
switch (_that) {
case BiometricSettingsStarted() when started != null:
return started(_that);case BiometricSettingsEnableRequested() when enableRequested != null:
return enableRequested(_that);case BiometricSettingsPinDigit() when pinDigit != null:
return pinDigit(_that);case BiometricSettingsPinBackspace() when pinBackspace != null:
return pinBackspace(_that);case BiometricSettingsPinCancelled() when pinCancelled != null:
return pinCancelled(_that);case BiometricSettingsDisableRequested() when disableRequested != null:
return disableRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  enableRequested,TResult Function( int digit,  String reason)?  pinDigit,TResult Function()?  pinBackspace,TResult Function()?  pinCancelled,TResult Function()?  disableRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BiometricSettingsStarted() when started != null:
return started();case BiometricSettingsEnableRequested() when enableRequested != null:
return enableRequested();case BiometricSettingsPinDigit() when pinDigit != null:
return pinDigit(_that.digit,_that.reason);case BiometricSettingsPinBackspace() when pinBackspace != null:
return pinBackspace();case BiometricSettingsPinCancelled() when pinCancelled != null:
return pinCancelled();case BiometricSettingsDisableRequested() when disableRequested != null:
return disableRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  enableRequested,required TResult Function( int digit,  String reason)  pinDigit,required TResult Function()  pinBackspace,required TResult Function()  pinCancelled,required TResult Function()  disableRequested,}) {final _that = this;
switch (_that) {
case BiometricSettingsStarted():
return started();case BiometricSettingsEnableRequested():
return enableRequested();case BiometricSettingsPinDigit():
return pinDigit(_that.digit,_that.reason);case BiometricSettingsPinBackspace():
return pinBackspace();case BiometricSettingsPinCancelled():
return pinCancelled();case BiometricSettingsDisableRequested():
return disableRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  enableRequested,TResult? Function( int digit,  String reason)?  pinDigit,TResult? Function()?  pinBackspace,TResult? Function()?  pinCancelled,TResult? Function()?  disableRequested,}) {final _that = this;
switch (_that) {
case BiometricSettingsStarted() when started != null:
return started();case BiometricSettingsEnableRequested() when enableRequested != null:
return enableRequested();case BiometricSettingsPinDigit() when pinDigit != null:
return pinDigit(_that.digit,_that.reason);case BiometricSettingsPinBackspace() when pinBackspace != null:
return pinBackspace();case BiometricSettingsPinCancelled() when pinCancelled != null:
return pinCancelled();case BiometricSettingsDisableRequested() when disableRequested != null:
return disableRequested();case _:
  return null;

}
}

}

/// @nodoc


class BiometricSettingsStarted implements BiometricSettingsEvent {
  const BiometricSettingsStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BiometricSettingsEvent.started()';
}


}




/// @nodoc


class BiometricSettingsEnableRequested implements BiometricSettingsEvent {
  const BiometricSettingsEnableRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsEnableRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BiometricSettingsEvent.enableRequested()';
}


}




/// @nodoc


class BiometricSettingsPinDigit implements BiometricSettingsEvent {
  const BiometricSettingsPinDigit(this.digit, {required this.reason});
  

 final  int digit;
 final  String reason;

/// Create a copy of BiometricSettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiometricSettingsPinDigitCopyWith<BiometricSettingsPinDigit> get copyWith => _$BiometricSettingsPinDigitCopyWithImpl<BiometricSettingsPinDigit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsPinDigit&&(identical(other.digit, digit) || other.digit == digit)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,digit,reason);

@override
String toString() {
  return 'BiometricSettingsEvent.pinDigit(digit: $digit, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BiometricSettingsPinDigitCopyWith<$Res> implements $BiometricSettingsEventCopyWith<$Res> {
  factory $BiometricSettingsPinDigitCopyWith(BiometricSettingsPinDigit value, $Res Function(BiometricSettingsPinDigit) _then) = _$BiometricSettingsPinDigitCopyWithImpl;
@useResult
$Res call({
 int digit, String reason
});




}
/// @nodoc
class _$BiometricSettingsPinDigitCopyWithImpl<$Res>
    implements $BiometricSettingsPinDigitCopyWith<$Res> {
  _$BiometricSettingsPinDigitCopyWithImpl(this._self, this._then);

  final BiometricSettingsPinDigit _self;
  final $Res Function(BiometricSettingsPinDigit) _then;

/// Create a copy of BiometricSettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? digit = null,Object? reason = null,}) {
  return _then(BiometricSettingsPinDigit(
null == digit ? _self.digit : digit // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BiometricSettingsPinBackspace implements BiometricSettingsEvent {
  const BiometricSettingsPinBackspace();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsPinBackspace);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BiometricSettingsEvent.pinBackspace()';
}


}




/// @nodoc


class BiometricSettingsPinCancelled implements BiometricSettingsEvent {
  const BiometricSettingsPinCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsPinCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BiometricSettingsEvent.pinCancelled()';
}


}




/// @nodoc


class BiometricSettingsDisableRequested implements BiometricSettingsEvent {
  const BiometricSettingsDisableRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsDisableRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BiometricSettingsEvent.disableRequested()';
}


}




/// @nodoc
mixin _$BiometricSettingsState {

 BiometricSettingsStatus get status; bool get available; bool get enabled; String get pin; BiometricSettingsError? get error; int? get attemptsLeft; DateTime? get lockedUntil; bool get justEnabled;
/// Create a copy of BiometricSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiometricSettingsStateCopyWith<BiometricSettingsState> get copyWith => _$BiometricSettingsStateCopyWithImpl<BiometricSettingsState>(this as BiometricSettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricSettingsState&&(identical(other.status, status) || other.status == status)&&(identical(other.available, available) || other.available == available)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.error, error) || other.error == error)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.justEnabled, justEnabled) || other.justEnabled == justEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,status,available,enabled,pin,error,attemptsLeft,lockedUntil,justEnabled);

@override
String toString() {
  return 'BiometricSettingsState(status: $status, available: $available, enabled: $enabled, pin: $pin, error: $error, attemptsLeft: $attemptsLeft, lockedUntil: $lockedUntil, justEnabled: $justEnabled)';
}


}

/// @nodoc
abstract mixin class $BiometricSettingsStateCopyWith<$Res>  {
  factory $BiometricSettingsStateCopyWith(BiometricSettingsState value, $Res Function(BiometricSettingsState) _then) = _$BiometricSettingsStateCopyWithImpl;
@useResult
$Res call({
 BiometricSettingsStatus status, bool available, bool enabled, String pin, BiometricSettingsError? error, int? attemptsLeft, DateTime? lockedUntil, bool justEnabled
});




}
/// @nodoc
class _$BiometricSettingsStateCopyWithImpl<$Res>
    implements $BiometricSettingsStateCopyWith<$Res> {
  _$BiometricSettingsStateCopyWithImpl(this._self, this._then);

  final BiometricSettingsState _self;
  final $Res Function(BiometricSettingsState) _then;

/// Create a copy of BiometricSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? available = null,Object? enabled = null,Object? pin = null,Object? error = freezed,Object? attemptsLeft = freezed,Object? lockedUntil = freezed,Object? justEnabled = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BiometricSettingsStatus,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BiometricSettingsError?,attemptsLeft: freezed == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int?,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,justEnabled: null == justEnabled ? _self.justEnabled : justEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BiometricSettingsState].
extension BiometricSettingsStatePatterns on BiometricSettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiometricSettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiometricSettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiometricSettingsState value)  $default,){
final _that = this;
switch (_that) {
case _BiometricSettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiometricSettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _BiometricSettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BiometricSettingsStatus status,  bool available,  bool enabled,  String pin,  BiometricSettingsError? error,  int? attemptsLeft,  DateTime? lockedUntil,  bool justEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiometricSettingsState() when $default != null:
return $default(_that.status,_that.available,_that.enabled,_that.pin,_that.error,_that.attemptsLeft,_that.lockedUntil,_that.justEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BiometricSettingsStatus status,  bool available,  bool enabled,  String pin,  BiometricSettingsError? error,  int? attemptsLeft,  DateTime? lockedUntil,  bool justEnabled)  $default,) {final _that = this;
switch (_that) {
case _BiometricSettingsState():
return $default(_that.status,_that.available,_that.enabled,_that.pin,_that.error,_that.attemptsLeft,_that.lockedUntil,_that.justEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BiometricSettingsStatus status,  bool available,  bool enabled,  String pin,  BiometricSettingsError? error,  int? attemptsLeft,  DateTime? lockedUntil,  bool justEnabled)?  $default,) {final _that = this;
switch (_that) {
case _BiometricSettingsState() when $default != null:
return $default(_that.status,_that.available,_that.enabled,_that.pin,_that.error,_that.attemptsLeft,_that.lockedUntil,_that.justEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _BiometricSettingsState implements BiometricSettingsState {
  const _BiometricSettingsState({this.status = BiometricSettingsStatus.loading, this.available = false, this.enabled = false, this.pin = '', this.error, this.attemptsLeft, this.lockedUntil, this.justEnabled = false});
  

@override@JsonKey() final  BiometricSettingsStatus status;
@override@JsonKey() final  bool available;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String pin;
@override final  BiometricSettingsError? error;
@override final  int? attemptsLeft;
@override final  DateTime? lockedUntil;
@override@JsonKey() final  bool justEnabled;

/// Create a copy of BiometricSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiometricSettingsStateCopyWith<_BiometricSettingsState> get copyWith => __$BiometricSettingsStateCopyWithImpl<_BiometricSettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiometricSettingsState&&(identical(other.status, status) || other.status == status)&&(identical(other.available, available) || other.available == available)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.error, error) || other.error == error)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.justEnabled, justEnabled) || other.justEnabled == justEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,status,available,enabled,pin,error,attemptsLeft,lockedUntil,justEnabled);

@override
String toString() {
  return 'BiometricSettingsState(status: $status, available: $available, enabled: $enabled, pin: $pin, error: $error, attemptsLeft: $attemptsLeft, lockedUntil: $lockedUntil, justEnabled: $justEnabled)';
}


}

/// @nodoc
abstract mixin class _$BiometricSettingsStateCopyWith<$Res> implements $BiometricSettingsStateCopyWith<$Res> {
  factory _$BiometricSettingsStateCopyWith(_BiometricSettingsState value, $Res Function(_BiometricSettingsState) _then) = __$BiometricSettingsStateCopyWithImpl;
@override @useResult
$Res call({
 BiometricSettingsStatus status, bool available, bool enabled, String pin, BiometricSettingsError? error, int? attemptsLeft, DateTime? lockedUntil, bool justEnabled
});




}
/// @nodoc
class __$BiometricSettingsStateCopyWithImpl<$Res>
    implements _$BiometricSettingsStateCopyWith<$Res> {
  __$BiometricSettingsStateCopyWithImpl(this._self, this._then);

  final _BiometricSettingsState _self;
  final $Res Function(_BiometricSettingsState) _then;

/// Create a copy of BiometricSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? available = null,Object? enabled = null,Object? pin = null,Object? error = freezed,Object? attemptsLeft = freezed,Object? lockedUntil = freezed,Object? justEnabled = null,}) {
  return _then(_BiometricSettingsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BiometricSettingsStatus,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BiometricSettingsError?,attemptsLeft: freezed == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int?,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,justEnabled: null == justEnabled ? _self.justEnabled : justEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
