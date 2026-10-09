// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quick_access_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuickAccessEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAccessEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QuickAccessEvent()';
}


}

/// @nodoc
class $QuickAccessEventCopyWith<$Res>  {
$QuickAccessEventCopyWith(QuickAccessEvent _, $Res Function(QuickAccessEvent) __);
}


/// Adds pattern-matching-related methods to [QuickAccessEvent].
extension QuickAccessEventPatterns on QuickAccessEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( QuickAccessDigitPressed value)?  digitPressed,TResult Function( QuickAccessBackspace value)?  backspace,TResult Function( QuickAccessStarted value)?  started,TResult Function( QuickAccessBiometric value)?  biometric,required TResult orElse(),}){
final _that = this;
switch (_that) {
case QuickAccessDigitPressed() when digitPressed != null:
return digitPressed(_that);case QuickAccessBackspace() when backspace != null:
return backspace(_that);case QuickAccessStarted() when started != null:
return started(_that);case QuickAccessBiometric() when biometric != null:
return biometric(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( QuickAccessDigitPressed value)  digitPressed,required TResult Function( QuickAccessBackspace value)  backspace,required TResult Function( QuickAccessStarted value)  started,required TResult Function( QuickAccessBiometric value)  biometric,}){
final _that = this;
switch (_that) {
case QuickAccessDigitPressed():
return digitPressed(_that);case QuickAccessBackspace():
return backspace(_that);case QuickAccessStarted():
return started(_that);case QuickAccessBiometric():
return biometric(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( QuickAccessDigitPressed value)?  digitPressed,TResult? Function( QuickAccessBackspace value)?  backspace,TResult? Function( QuickAccessStarted value)?  started,TResult? Function( QuickAccessBiometric value)?  biometric,}){
final _that = this;
switch (_that) {
case QuickAccessDigitPressed() when digitPressed != null:
return digitPressed(_that);case QuickAccessBackspace() when backspace != null:
return backspace(_that);case QuickAccessStarted() when started != null:
return started(_that);case QuickAccessBiometric() when biometric != null:
return biometric(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int digit)?  digitPressed,TResult Function()?  backspace,TResult Function()?  started,TResult Function( String reason)?  biometric,required TResult orElse(),}) {final _that = this;
switch (_that) {
case QuickAccessDigitPressed() when digitPressed != null:
return digitPressed(_that.digit);case QuickAccessBackspace() when backspace != null:
return backspace();case QuickAccessStarted() when started != null:
return started();case QuickAccessBiometric() when biometric != null:
return biometric(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int digit)  digitPressed,required TResult Function()  backspace,required TResult Function()  started,required TResult Function( String reason)  biometric,}) {final _that = this;
switch (_that) {
case QuickAccessDigitPressed():
return digitPressed(_that.digit);case QuickAccessBackspace():
return backspace();case QuickAccessStarted():
return started();case QuickAccessBiometric():
return biometric(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int digit)?  digitPressed,TResult? Function()?  backspace,TResult? Function()?  started,TResult? Function( String reason)?  biometric,}) {final _that = this;
switch (_that) {
case QuickAccessDigitPressed() when digitPressed != null:
return digitPressed(_that.digit);case QuickAccessBackspace() when backspace != null:
return backspace();case QuickAccessStarted() when started != null:
return started();case QuickAccessBiometric() when biometric != null:
return biometric(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class QuickAccessDigitPressed implements QuickAccessEvent {
  const QuickAccessDigitPressed(this.digit);
  

 final  int digit;

/// Create a copy of QuickAccessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickAccessDigitPressedCopyWith<QuickAccessDigitPressed> get copyWith => _$QuickAccessDigitPressedCopyWithImpl<QuickAccessDigitPressed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAccessDigitPressed&&(identical(other.digit, digit) || other.digit == digit));
}


@override
int get hashCode => Object.hash(runtimeType,digit);

@override
String toString() {
  return 'QuickAccessEvent.digitPressed(digit: $digit)';
}


}

/// @nodoc
abstract mixin class $QuickAccessDigitPressedCopyWith<$Res> implements $QuickAccessEventCopyWith<$Res> {
  factory $QuickAccessDigitPressedCopyWith(QuickAccessDigitPressed value, $Res Function(QuickAccessDigitPressed) _then) = _$QuickAccessDigitPressedCopyWithImpl;
@useResult
$Res call({
 int digit
});




}
/// @nodoc
class _$QuickAccessDigitPressedCopyWithImpl<$Res>
    implements $QuickAccessDigitPressedCopyWith<$Res> {
  _$QuickAccessDigitPressedCopyWithImpl(this._self, this._then);

  final QuickAccessDigitPressed _self;
  final $Res Function(QuickAccessDigitPressed) _then;

/// Create a copy of QuickAccessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? digit = null,}) {
  return _then(QuickAccessDigitPressed(
null == digit ? _self.digit : digit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class QuickAccessBackspace implements QuickAccessEvent {
  const QuickAccessBackspace();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAccessBackspace);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QuickAccessEvent.backspace()';
}


}




/// @nodoc


class QuickAccessStarted implements QuickAccessEvent {
  const QuickAccessStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAccessStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QuickAccessEvent.started()';
}


}




/// @nodoc


class QuickAccessBiometric implements QuickAccessEvent {
  const QuickAccessBiometric({required this.reason});
  

 final  String reason;

/// Create a copy of QuickAccessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickAccessBiometricCopyWith<QuickAccessBiometric> get copyWith => _$QuickAccessBiometricCopyWithImpl<QuickAccessBiometric>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAccessBiometric&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'QuickAccessEvent.biometric(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $QuickAccessBiometricCopyWith<$Res> implements $QuickAccessEventCopyWith<$Res> {
  factory $QuickAccessBiometricCopyWith(QuickAccessBiometric value, $Res Function(QuickAccessBiometric) _then) = _$QuickAccessBiometricCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$QuickAccessBiometricCopyWithImpl<$Res>
    implements $QuickAccessBiometricCopyWith<$Res> {
  _$QuickAccessBiometricCopyWithImpl(this._self, this._then);

  final QuickAccessBiometric _self;
  final $Res Function(QuickAccessBiometric) _then;

/// Create a copy of QuickAccessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(QuickAccessBiometric(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$QuickAccessState {

 RememberedUser get user; String get pin; QuickAccessStatus get status; int get attemptsLeft; bool get lastWrong;/// Hay credencial guardada y el sistema puede pedir la huella.
 bool get biometricAvailable;/// El servidor rechazó la credencial: se borró y hay que entrar con PIN.
 bool get biometricRevoked;/// La huella se leyó pero no se pudo abrir sesión (servidor o red): se
/// avisa y se puede reintentar o usar el PIN.
 bool get biometricFailed;/// El PIN no se pudo comprobar (sin red, servidor caído): no cuenta como
/// intento fallido. Se avisa para reintentar.
 bool get unavailable;/// PIN correcto, pero este teléfono dejó de ser de confianza (lo
/// desvincularon): la pantalla lleva al login, que corre el OTP.
 bool get needsDeviceVerification; DateTime? get lockedUntil;/// Cuánto durará el bloqueo si se agotan los intentos (escala por nivel).
 Duration? get nextLockout;
/// Create a copy of QuickAccessState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickAccessStateCopyWith<QuickAccessState> get copyWith => _$QuickAccessStateCopyWithImpl<QuickAccessState>(this as QuickAccessState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAccessState&&(identical(other.user, user) || other.user == user)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.status, status) || other.status == status)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.lastWrong, lastWrong) || other.lastWrong == lastWrong)&&(identical(other.biometricAvailable, biometricAvailable) || other.biometricAvailable == biometricAvailable)&&(identical(other.biometricRevoked, biometricRevoked) || other.biometricRevoked == biometricRevoked)&&(identical(other.biometricFailed, biometricFailed) || other.biometricFailed == biometricFailed)&&(identical(other.unavailable, unavailable) || other.unavailable == unavailable)&&(identical(other.needsDeviceVerification, needsDeviceVerification) || other.needsDeviceVerification == needsDeviceVerification)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.nextLockout, nextLockout) || other.nextLockout == nextLockout));
}


@override
int get hashCode => Object.hash(runtimeType,user,pin,status,attemptsLeft,lastWrong,biometricAvailable,biometricRevoked,biometricFailed,unavailable,needsDeviceVerification,lockedUntil,nextLockout);

@override
String toString() {
  return 'QuickAccessState(user: $user, pin: $pin, status: $status, attemptsLeft: $attemptsLeft, lastWrong: $lastWrong, biometricAvailable: $biometricAvailable, biometricRevoked: $biometricRevoked, biometricFailed: $biometricFailed, unavailable: $unavailable, needsDeviceVerification: $needsDeviceVerification, lockedUntil: $lockedUntil, nextLockout: $nextLockout)';
}


}

/// @nodoc
abstract mixin class $QuickAccessStateCopyWith<$Res>  {
  factory $QuickAccessStateCopyWith(QuickAccessState value, $Res Function(QuickAccessState) _then) = _$QuickAccessStateCopyWithImpl;
@useResult
$Res call({
 RememberedUser user, String pin, QuickAccessStatus status, int attemptsLeft, bool lastWrong, bool biometricAvailable, bool biometricRevoked, bool biometricFailed, bool unavailable, bool needsDeviceVerification, DateTime? lockedUntil, Duration? nextLockout
});




}
/// @nodoc
class _$QuickAccessStateCopyWithImpl<$Res>
    implements $QuickAccessStateCopyWith<$Res> {
  _$QuickAccessStateCopyWithImpl(this._self, this._then);

  final QuickAccessState _self;
  final $Res Function(QuickAccessState) _then;

/// Create a copy of QuickAccessState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? pin = null,Object? status = null,Object? attemptsLeft = null,Object? lastWrong = null,Object? biometricAvailable = null,Object? biometricRevoked = null,Object? biometricFailed = null,Object? unavailable = null,Object? needsDeviceVerification = null,Object? lockedUntil = freezed,Object? nextLockout = freezed,}) {
  return _then(_self.copyWith(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as RememberedUser,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuickAccessStatus,attemptsLeft: null == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int,lastWrong: null == lastWrong ? _self.lastWrong : lastWrong // ignore: cast_nullable_to_non_nullable
as bool,biometricAvailable: null == biometricAvailable ? _self.biometricAvailable : biometricAvailable // ignore: cast_nullable_to_non_nullable
as bool,biometricRevoked: null == biometricRevoked ? _self.biometricRevoked : biometricRevoked // ignore: cast_nullable_to_non_nullable
as bool,biometricFailed: null == biometricFailed ? _self.biometricFailed : biometricFailed // ignore: cast_nullable_to_non_nullable
as bool,unavailable: null == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as bool,needsDeviceVerification: null == needsDeviceVerification ? _self.needsDeviceVerification : needsDeviceVerification // ignore: cast_nullable_to_non_nullable
as bool,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,nextLockout: freezed == nextLockout ? _self.nextLockout : nextLockout // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickAccessState].
extension QuickAccessStatePatterns on QuickAccessState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickAccessState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickAccessState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickAccessState value)  $default,){
final _that = this;
switch (_that) {
case _QuickAccessState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickAccessState value)?  $default,){
final _that = this;
switch (_that) {
case _QuickAccessState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RememberedUser user,  String pin,  QuickAccessStatus status,  int attemptsLeft,  bool lastWrong,  bool biometricAvailable,  bool biometricRevoked,  bool biometricFailed,  bool unavailable,  bool needsDeviceVerification,  DateTime? lockedUntil,  Duration? nextLockout)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickAccessState() when $default != null:
return $default(_that.user,_that.pin,_that.status,_that.attemptsLeft,_that.lastWrong,_that.biometricAvailable,_that.biometricRevoked,_that.biometricFailed,_that.unavailable,_that.needsDeviceVerification,_that.lockedUntil,_that.nextLockout);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RememberedUser user,  String pin,  QuickAccessStatus status,  int attemptsLeft,  bool lastWrong,  bool biometricAvailable,  bool biometricRevoked,  bool biometricFailed,  bool unavailable,  bool needsDeviceVerification,  DateTime? lockedUntil,  Duration? nextLockout)  $default,) {final _that = this;
switch (_that) {
case _QuickAccessState():
return $default(_that.user,_that.pin,_that.status,_that.attemptsLeft,_that.lastWrong,_that.biometricAvailable,_that.biometricRevoked,_that.biometricFailed,_that.unavailable,_that.needsDeviceVerification,_that.lockedUntil,_that.nextLockout);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RememberedUser user,  String pin,  QuickAccessStatus status,  int attemptsLeft,  bool lastWrong,  bool biometricAvailable,  bool biometricRevoked,  bool biometricFailed,  bool unavailable,  bool needsDeviceVerification,  DateTime? lockedUntil,  Duration? nextLockout)?  $default,) {final _that = this;
switch (_that) {
case _QuickAccessState() when $default != null:
return $default(_that.user,_that.pin,_that.status,_that.attemptsLeft,_that.lastWrong,_that.biometricAvailable,_that.biometricRevoked,_that.biometricFailed,_that.unavailable,_that.needsDeviceVerification,_that.lockedUntil,_that.nextLockout);case _:
  return null;

}
}

}

/// @nodoc


class _QuickAccessState implements QuickAccessState {
  const _QuickAccessState({required this.user, this.pin = '', this.status = QuickAccessStatus.idle, this.attemptsLeft = LockoutPolicy.maxAttempts, this.lastWrong = false, this.biometricAvailable = false, this.biometricRevoked = false, this.biometricFailed = false, this.unavailable = false, this.needsDeviceVerification = false, this.lockedUntil, this.nextLockout});
  

@override final  RememberedUser user;
@override@JsonKey() final  String pin;
@override@JsonKey() final  QuickAccessStatus status;
@override@JsonKey() final  int attemptsLeft;
@override@JsonKey() final  bool lastWrong;
/// Hay credencial guardada y el sistema puede pedir la huella.
@override@JsonKey() final  bool biometricAvailable;
/// El servidor rechazó la credencial: se borró y hay que entrar con PIN.
@override@JsonKey() final  bool biometricRevoked;
/// La huella se leyó pero no se pudo abrir sesión (servidor o red): se
/// avisa y se puede reintentar o usar el PIN.
@override@JsonKey() final  bool biometricFailed;
/// El PIN no se pudo comprobar (sin red, servidor caído): no cuenta como
/// intento fallido. Se avisa para reintentar.
@override@JsonKey() final  bool unavailable;
/// PIN correcto, pero este teléfono dejó de ser de confianza (lo
/// desvincularon): la pantalla lleva al login, que corre el OTP.
@override@JsonKey() final  bool needsDeviceVerification;
@override final  DateTime? lockedUntil;
/// Cuánto durará el bloqueo si se agotan los intentos (escala por nivel).
@override final  Duration? nextLockout;

/// Create a copy of QuickAccessState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickAccessStateCopyWith<_QuickAccessState> get copyWith => __$QuickAccessStateCopyWithImpl<_QuickAccessState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickAccessState&&(identical(other.user, user) || other.user == user)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.status, status) || other.status == status)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.lastWrong, lastWrong) || other.lastWrong == lastWrong)&&(identical(other.biometricAvailable, biometricAvailable) || other.biometricAvailable == biometricAvailable)&&(identical(other.biometricRevoked, biometricRevoked) || other.biometricRevoked == biometricRevoked)&&(identical(other.biometricFailed, biometricFailed) || other.biometricFailed == biometricFailed)&&(identical(other.unavailable, unavailable) || other.unavailable == unavailable)&&(identical(other.needsDeviceVerification, needsDeviceVerification) || other.needsDeviceVerification == needsDeviceVerification)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.nextLockout, nextLockout) || other.nextLockout == nextLockout));
}


@override
int get hashCode => Object.hash(runtimeType,user,pin,status,attemptsLeft,lastWrong,biometricAvailable,biometricRevoked,biometricFailed,unavailable,needsDeviceVerification,lockedUntil,nextLockout);

@override
String toString() {
  return 'QuickAccessState(user: $user, pin: $pin, status: $status, attemptsLeft: $attemptsLeft, lastWrong: $lastWrong, biometricAvailable: $biometricAvailable, biometricRevoked: $biometricRevoked, biometricFailed: $biometricFailed, unavailable: $unavailable, needsDeviceVerification: $needsDeviceVerification, lockedUntil: $lockedUntil, nextLockout: $nextLockout)';
}


}

/// @nodoc
abstract mixin class _$QuickAccessStateCopyWith<$Res> implements $QuickAccessStateCopyWith<$Res> {
  factory _$QuickAccessStateCopyWith(_QuickAccessState value, $Res Function(_QuickAccessState) _then) = __$QuickAccessStateCopyWithImpl;
@override @useResult
$Res call({
 RememberedUser user, String pin, QuickAccessStatus status, int attemptsLeft, bool lastWrong, bool biometricAvailable, bool biometricRevoked, bool biometricFailed, bool unavailable, bool needsDeviceVerification, DateTime? lockedUntil, Duration? nextLockout
});




}
/// @nodoc
class __$QuickAccessStateCopyWithImpl<$Res>
    implements _$QuickAccessStateCopyWith<$Res> {
  __$QuickAccessStateCopyWithImpl(this._self, this._then);

  final _QuickAccessState _self;
  final $Res Function(_QuickAccessState) _then;

/// Create a copy of QuickAccessState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? pin = null,Object? status = null,Object? attemptsLeft = null,Object? lastWrong = null,Object? biometricAvailable = null,Object? biometricRevoked = null,Object? biometricFailed = null,Object? unavailable = null,Object? needsDeviceVerification = null,Object? lockedUntil = freezed,Object? nextLockout = freezed,}) {
  return _then(_QuickAccessState(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as RememberedUser,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuickAccessStatus,attemptsLeft: null == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int,lastWrong: null == lastWrong ? _self.lastWrong : lastWrong // ignore: cast_nullable_to_non_nullable
as bool,biometricAvailable: null == biometricAvailable ? _self.biometricAvailable : biometricAvailable // ignore: cast_nullable_to_non_nullable
as bool,biometricRevoked: null == biometricRevoked ? _self.biometricRevoked : biometricRevoked // ignore: cast_nullable_to_non_nullable
as bool,biometricFailed: null == biometricFailed ? _self.biometricFailed : biometricFailed // ignore: cast_nullable_to_non_nullable
as bool,unavailable: null == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as bool,needsDeviceVerification: null == needsDeviceVerification ? _self.needsDeviceVerification : needsDeviceVerification // ignore: cast_nullable_to_non_nullable
as bool,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,nextLockout: freezed == nextLockout ? _self.nextLockout : nextLockout // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
