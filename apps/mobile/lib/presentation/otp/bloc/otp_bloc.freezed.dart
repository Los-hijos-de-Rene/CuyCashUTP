// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OtpEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpEvent()';
}


}

/// @nodoc
class $OtpEventCopyWith<$Res>  {
$OtpEventCopyWith(OtpEvent _, $Res Function(OtpEvent) __);
}


/// Adds pattern-matching-related methods to [OtpEvent].
extension OtpEventPatterns on OtpEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OtpStarted value)?  started,TResult Function( OtpCodeChanged value)?  codeChanged,TResult Function( OtpSubmitted value)?  submitted,TResult Function( OtpResendRequested value)?  resendRequested,TResult Function( OtpTicked value)?  ticked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OtpStarted() when started != null:
return started(_that);case OtpCodeChanged() when codeChanged != null:
return codeChanged(_that);case OtpSubmitted() when submitted != null:
return submitted(_that);case OtpResendRequested() when resendRequested != null:
return resendRequested(_that);case OtpTicked() when ticked != null:
return ticked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OtpStarted value)  started,required TResult Function( OtpCodeChanged value)  codeChanged,required TResult Function( OtpSubmitted value)  submitted,required TResult Function( OtpResendRequested value)  resendRequested,required TResult Function( OtpTicked value)  ticked,}){
final _that = this;
switch (_that) {
case OtpStarted():
return started(_that);case OtpCodeChanged():
return codeChanged(_that);case OtpSubmitted():
return submitted(_that);case OtpResendRequested():
return resendRequested(_that);case OtpTicked():
return ticked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OtpStarted value)?  started,TResult? Function( OtpCodeChanged value)?  codeChanged,TResult? Function( OtpSubmitted value)?  submitted,TResult? Function( OtpResendRequested value)?  resendRequested,TResult? Function( OtpTicked value)?  ticked,}){
final _that = this;
switch (_that) {
case OtpStarted() when started != null:
return started(_that);case OtpCodeChanged() when codeChanged != null:
return codeChanged(_that);case OtpSubmitted() when submitted != null:
return submitted(_that);case OtpResendRequested() when resendRequested != null:
return resendRequested(_that);case OtpTicked() when ticked != null:
return ticked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( String code)?  codeChanged,TResult Function()?  submitted,TResult Function()?  resendRequested,TResult Function()?  ticked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OtpStarted() when started != null:
return started();case OtpCodeChanged() when codeChanged != null:
return codeChanged(_that.code);case OtpSubmitted() when submitted != null:
return submitted();case OtpResendRequested() when resendRequested != null:
return resendRequested();case OtpTicked() when ticked != null:
return ticked();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( String code)  codeChanged,required TResult Function()  submitted,required TResult Function()  resendRequested,required TResult Function()  ticked,}) {final _that = this;
switch (_that) {
case OtpStarted():
return started();case OtpCodeChanged():
return codeChanged(_that.code);case OtpSubmitted():
return submitted();case OtpResendRequested():
return resendRequested();case OtpTicked():
return ticked();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( String code)?  codeChanged,TResult? Function()?  submitted,TResult? Function()?  resendRequested,TResult? Function()?  ticked,}) {final _that = this;
switch (_that) {
case OtpStarted() when started != null:
return started();case OtpCodeChanged() when codeChanged != null:
return codeChanged(_that.code);case OtpSubmitted() when submitted != null:
return submitted();case OtpResendRequested() when resendRequested != null:
return resendRequested();case OtpTicked() when ticked != null:
return ticked();case _:
  return null;

}
}

}

/// @nodoc


class OtpStarted implements OtpEvent {
  const OtpStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpEvent.started()';
}


}




/// @nodoc


class OtpCodeChanged implements OtpEvent {
  const OtpCodeChanged(this.code);
  

 final  String code;

/// Create a copy of OtpEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpCodeChangedCopyWith<OtpCodeChanged> get copyWith => _$OtpCodeChangedCopyWithImpl<OtpCodeChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpCodeChanged&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'OtpEvent.codeChanged(code: $code)';
}


}

/// @nodoc
abstract mixin class $OtpCodeChangedCopyWith<$Res> implements $OtpEventCopyWith<$Res> {
  factory $OtpCodeChangedCopyWith(OtpCodeChanged value, $Res Function(OtpCodeChanged) _then) = _$OtpCodeChangedCopyWithImpl;
@useResult
$Res call({
 String code
});




}
/// @nodoc
class _$OtpCodeChangedCopyWithImpl<$Res>
    implements $OtpCodeChangedCopyWith<$Res> {
  _$OtpCodeChangedCopyWithImpl(this._self, this._then);

  final OtpCodeChanged _self;
  final $Res Function(OtpCodeChanged) _then;

/// Create a copy of OtpEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(OtpCodeChanged(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OtpSubmitted implements OtpEvent {
  const OtpSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpEvent.submitted()';
}


}




/// @nodoc


class OtpResendRequested implements OtpEvent {
  const OtpResendRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpResendRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpEvent.resendRequested()';
}


}




/// @nodoc


class OtpTicked implements OtpEvent {
  const OtpTicked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpTicked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OtpEvent.ticked()';
}


}




/// @nodoc
mixin _$OtpState {

 String? get challengeId; String get maskedEmail; String get code; OtpCodeState get codeState; OtpResendState get resendState; int get attemptsLeft; int get resendsLeft; Duration get cooldownRemaining; OtpStatus get status; bool get verified;/// Prueba de haber pasado el código. Sin él, el backend no deja cambiar el
/// PIN ni abrir sesión en un teléfono nuevo.
 String? get otpTicket; bool get cancelled; OtpCancelReason? get cancelledReason; DateTime? get expiresAt; DateTime? get cooldownUntil;
/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpStateCopyWith<OtpState> get copyWith => _$OtpStateCopyWithImpl<OtpState>(this as OtpState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpState&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.maskedEmail, maskedEmail) || other.maskedEmail == maskedEmail)&&(identical(other.code, code) || other.code == code)&&(identical(other.codeState, codeState) || other.codeState == codeState)&&(identical(other.resendState, resendState) || other.resendState == resendState)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.resendsLeft, resendsLeft) || other.resendsLeft == resendsLeft)&&(identical(other.cooldownRemaining, cooldownRemaining) || other.cooldownRemaining == cooldownRemaining)&&(identical(other.status, status) || other.status == status)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.otpTicket, otpTicket) || other.otpTicket == otpTicket)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.cancelledReason, cancelledReason) || other.cancelledReason == cancelledReason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.cooldownUntil, cooldownUntil) || other.cooldownUntil == cooldownUntil));
}


@override
int get hashCode => Object.hash(runtimeType,challengeId,maskedEmail,code,codeState,resendState,attemptsLeft,resendsLeft,cooldownRemaining,status,verified,otpTicket,cancelled,cancelledReason,expiresAt,cooldownUntil);

@override
String toString() {
  return 'OtpState(challengeId: $challengeId, maskedEmail: $maskedEmail, code: $code, codeState: $codeState, resendState: $resendState, attemptsLeft: $attemptsLeft, resendsLeft: $resendsLeft, cooldownRemaining: $cooldownRemaining, status: $status, verified: $verified, otpTicket: $otpTicket, cancelled: $cancelled, cancelledReason: $cancelledReason, expiresAt: $expiresAt, cooldownUntil: $cooldownUntil)';
}


}

/// @nodoc
abstract mixin class $OtpStateCopyWith<$Res>  {
  factory $OtpStateCopyWith(OtpState value, $Res Function(OtpState) _then) = _$OtpStateCopyWithImpl;
@useResult
$Res call({
 String? challengeId, String maskedEmail, String code, OtpCodeState codeState, OtpResendState resendState, int attemptsLeft, int resendsLeft, Duration cooldownRemaining, OtpStatus status, bool verified, String? otpTicket, bool cancelled, OtpCancelReason? cancelledReason, DateTime? expiresAt, DateTime? cooldownUntil
});




}
/// @nodoc
class _$OtpStateCopyWithImpl<$Res>
    implements $OtpStateCopyWith<$Res> {
  _$OtpStateCopyWithImpl(this._self, this._then);

  final OtpState _self;
  final $Res Function(OtpState) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? challengeId = freezed,Object? maskedEmail = null,Object? code = null,Object? codeState = null,Object? resendState = null,Object? attemptsLeft = null,Object? resendsLeft = null,Object? cooldownRemaining = null,Object? status = null,Object? verified = null,Object? otpTicket = freezed,Object? cancelled = null,Object? cancelledReason = freezed,Object? expiresAt = freezed,Object? cooldownUntil = freezed,}) {
  return _then(_self.copyWith(
challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,maskedEmail: null == maskedEmail ? _self.maskedEmail : maskedEmail // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,codeState: null == codeState ? _self.codeState : codeState // ignore: cast_nullable_to_non_nullable
as OtpCodeState,resendState: null == resendState ? _self.resendState : resendState // ignore: cast_nullable_to_non_nullable
as OtpResendState,attemptsLeft: null == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int,resendsLeft: null == resendsLeft ? _self.resendsLeft : resendsLeft // ignore: cast_nullable_to_non_nullable
as int,cooldownRemaining: null == cooldownRemaining ? _self.cooldownRemaining : cooldownRemaining // ignore: cast_nullable_to_non_nullable
as Duration,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OtpStatus,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,otpTicket: freezed == otpTicket ? _self.otpTicket : otpTicket // ignore: cast_nullable_to_non_nullable
as String?,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as OtpCancelReason?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cooldownUntil: freezed == cooldownUntil ? _self.cooldownUntil : cooldownUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpState].
extension OtpStatePatterns on OtpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpState value)  $default,){
final _that = this;
switch (_that) {
case _OtpState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpState value)?  $default,){
final _that = this;
switch (_that) {
case _OtpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? challengeId,  String maskedEmail,  String code,  OtpCodeState codeState,  OtpResendState resendState,  int attemptsLeft,  int resendsLeft,  Duration cooldownRemaining,  OtpStatus status,  bool verified,  String? otpTicket,  bool cancelled,  OtpCancelReason? cancelledReason,  DateTime? expiresAt,  DateTime? cooldownUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpState() when $default != null:
return $default(_that.challengeId,_that.maskedEmail,_that.code,_that.codeState,_that.resendState,_that.attemptsLeft,_that.resendsLeft,_that.cooldownRemaining,_that.status,_that.verified,_that.otpTicket,_that.cancelled,_that.cancelledReason,_that.expiresAt,_that.cooldownUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? challengeId,  String maskedEmail,  String code,  OtpCodeState codeState,  OtpResendState resendState,  int attemptsLeft,  int resendsLeft,  Duration cooldownRemaining,  OtpStatus status,  bool verified,  String? otpTicket,  bool cancelled,  OtpCancelReason? cancelledReason,  DateTime? expiresAt,  DateTime? cooldownUntil)  $default,) {final _that = this;
switch (_that) {
case _OtpState():
return $default(_that.challengeId,_that.maskedEmail,_that.code,_that.codeState,_that.resendState,_that.attemptsLeft,_that.resendsLeft,_that.cooldownRemaining,_that.status,_that.verified,_that.otpTicket,_that.cancelled,_that.cancelledReason,_that.expiresAt,_that.cooldownUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? challengeId,  String maskedEmail,  String code,  OtpCodeState codeState,  OtpResendState resendState,  int attemptsLeft,  int resendsLeft,  Duration cooldownRemaining,  OtpStatus status,  bool verified,  String? otpTicket,  bool cancelled,  OtpCancelReason? cancelledReason,  DateTime? expiresAt,  DateTime? cooldownUntil)?  $default,) {final _that = this;
switch (_that) {
case _OtpState() when $default != null:
return $default(_that.challengeId,_that.maskedEmail,_that.code,_that.codeState,_that.resendState,_that.attemptsLeft,_that.resendsLeft,_that.cooldownRemaining,_that.status,_that.verified,_that.otpTicket,_that.cancelled,_that.cancelledReason,_that.expiresAt,_that.cooldownUntil);case _:
  return null;

}
}

}

/// @nodoc


class _OtpState extends OtpState {
  const _OtpState({this.challengeId, this.maskedEmail = '', this.code = '', this.codeState = OtpCodeState.empty, this.resendState = OtpResendState.cooling, this.attemptsLeft = OtpPolicy.maxAttempts, this.resendsLeft = OtpPolicy.maxResends, this.cooldownRemaining = Duration.zero, this.status = OtpStatus.loading, this.verified = false, this.otpTicket, this.cancelled = false, this.cancelledReason, this.expiresAt, this.cooldownUntil}): super._();
  

@override final  String? challengeId;
@override@JsonKey() final  String maskedEmail;
@override@JsonKey() final  String code;
@override@JsonKey() final  OtpCodeState codeState;
@override@JsonKey() final  OtpResendState resendState;
@override@JsonKey() final  int attemptsLeft;
@override@JsonKey() final  int resendsLeft;
@override@JsonKey() final  Duration cooldownRemaining;
@override@JsonKey() final  OtpStatus status;
@override@JsonKey() final  bool verified;
/// Prueba de haber pasado el código. Sin él, el backend no deja cambiar el
/// PIN ni abrir sesión en un teléfono nuevo.
@override final  String? otpTicket;
@override@JsonKey() final  bool cancelled;
@override final  OtpCancelReason? cancelledReason;
@override final  DateTime? expiresAt;
@override final  DateTime? cooldownUntil;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpStateCopyWith<_OtpState> get copyWith => __$OtpStateCopyWithImpl<_OtpState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpState&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.maskedEmail, maskedEmail) || other.maskedEmail == maskedEmail)&&(identical(other.code, code) || other.code == code)&&(identical(other.codeState, codeState) || other.codeState == codeState)&&(identical(other.resendState, resendState) || other.resendState == resendState)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.resendsLeft, resendsLeft) || other.resendsLeft == resendsLeft)&&(identical(other.cooldownRemaining, cooldownRemaining) || other.cooldownRemaining == cooldownRemaining)&&(identical(other.status, status) || other.status == status)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.otpTicket, otpTicket) || other.otpTicket == otpTicket)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.cancelledReason, cancelledReason) || other.cancelledReason == cancelledReason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.cooldownUntil, cooldownUntil) || other.cooldownUntil == cooldownUntil));
}


@override
int get hashCode => Object.hash(runtimeType,challengeId,maskedEmail,code,codeState,resendState,attemptsLeft,resendsLeft,cooldownRemaining,status,verified,otpTicket,cancelled,cancelledReason,expiresAt,cooldownUntil);

@override
String toString() {
  return 'OtpState(challengeId: $challengeId, maskedEmail: $maskedEmail, code: $code, codeState: $codeState, resendState: $resendState, attemptsLeft: $attemptsLeft, resendsLeft: $resendsLeft, cooldownRemaining: $cooldownRemaining, status: $status, verified: $verified, otpTicket: $otpTicket, cancelled: $cancelled, cancelledReason: $cancelledReason, expiresAt: $expiresAt, cooldownUntil: $cooldownUntil)';
}


}

/// @nodoc
abstract mixin class _$OtpStateCopyWith<$Res> implements $OtpStateCopyWith<$Res> {
  factory _$OtpStateCopyWith(_OtpState value, $Res Function(_OtpState) _then) = __$OtpStateCopyWithImpl;
@override @useResult
$Res call({
 String? challengeId, String maskedEmail, String code, OtpCodeState codeState, OtpResendState resendState, int attemptsLeft, int resendsLeft, Duration cooldownRemaining, OtpStatus status, bool verified, String? otpTicket, bool cancelled, OtpCancelReason? cancelledReason, DateTime? expiresAt, DateTime? cooldownUntil
});




}
/// @nodoc
class __$OtpStateCopyWithImpl<$Res>
    implements _$OtpStateCopyWith<$Res> {
  __$OtpStateCopyWithImpl(this._self, this._then);

  final _OtpState _self;
  final $Res Function(_OtpState) _then;

/// Create a copy of OtpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? challengeId = freezed,Object? maskedEmail = null,Object? code = null,Object? codeState = null,Object? resendState = null,Object? attemptsLeft = null,Object? resendsLeft = null,Object? cooldownRemaining = null,Object? status = null,Object? verified = null,Object? otpTicket = freezed,Object? cancelled = null,Object? cancelledReason = freezed,Object? expiresAt = freezed,Object? cooldownUntil = freezed,}) {
  return _then(_OtpState(
challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,maskedEmail: null == maskedEmail ? _self.maskedEmail : maskedEmail // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,codeState: null == codeState ? _self.codeState : codeState // ignore: cast_nullable_to_non_nullable
as OtpCodeState,resendState: null == resendState ? _self.resendState : resendState // ignore: cast_nullable_to_non_nullable
as OtpResendState,attemptsLeft: null == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int,resendsLeft: null == resendsLeft ? _self.resendsLeft : resendsLeft // ignore: cast_nullable_to_non_nullable
as int,cooldownRemaining: null == cooldownRemaining ? _self.cooldownRemaining : cooldownRemaining // ignore: cast_nullable_to_non_nullable
as Duration,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OtpStatus,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,otpTicket: freezed == otpTicket ? _self.otpTicket : otpTicket // ignore: cast_nullable_to_non_nullable
as String?,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as OtpCancelReason?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cooldownUntil: freezed == cooldownUntil ? _self.cooldownUntil : cooldownUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
