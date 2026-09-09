// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthLoginSubmitted value)?  loginSubmitted,TResult Function( AuthDeviceVerified value)?  deviceVerified,TResult Function( AuthSignedOut value)?  signedOut,TResult Function( _AuthSessionChanged value)?  sessionChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthDeviceVerified() when deviceVerified != null:
return deviceVerified(_that);case AuthSignedOut() when signedOut != null:
return signedOut(_that);case _AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthLoginSubmitted value)  loginSubmitted,required TResult Function( AuthDeviceVerified value)  deviceVerified,required TResult Function( AuthSignedOut value)  signedOut,required TResult Function( _AuthSessionChanged value)  sessionChanged,}){
final _that = this;
switch (_that) {
case AuthLoginSubmitted():
return loginSubmitted(_that);case AuthDeviceVerified():
return deviceVerified(_that);case AuthSignedOut():
return signedOut(_that);case _AuthSessionChanged():
return sessionChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthLoginSubmitted value)?  loginSubmitted,TResult? Function( AuthDeviceVerified value)?  deviceVerified,TResult? Function( AuthSignedOut value)?  signedOut,TResult? Function( _AuthSessionChanged value)?  sessionChanged,}){
final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthDeviceVerified() when deviceVerified != null:
return deviceVerified(_that);case AuthSignedOut() when signedOut != null:
return signedOut(_that);case _AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String identifier,  String pin)?  loginSubmitted,TResult Function( AuthSession session,  String otpTicket)?  deviceVerified,TResult Function()?  signedOut,TResult Function( AuthSession? session)?  sessionChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.identifier,_that.pin);case AuthDeviceVerified() when deviceVerified != null:
return deviceVerified(_that.session,_that.otpTicket);case AuthSignedOut() when signedOut != null:
return signedOut();case _AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String identifier,  String pin)  loginSubmitted,required TResult Function( AuthSession session,  String otpTicket)  deviceVerified,required TResult Function()  signedOut,required TResult Function( AuthSession? session)  sessionChanged,}) {final _that = this;
switch (_that) {
case AuthLoginSubmitted():
return loginSubmitted(_that.identifier,_that.pin);case AuthDeviceVerified():
return deviceVerified(_that.session,_that.otpTicket);case AuthSignedOut():
return signedOut();case _AuthSessionChanged():
return sessionChanged(_that.session);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String identifier,  String pin)?  loginSubmitted,TResult? Function( AuthSession session,  String otpTicket)?  deviceVerified,TResult? Function()?  signedOut,TResult? Function( AuthSession? session)?  sessionChanged,}) {final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.identifier,_that.pin);case AuthDeviceVerified() when deviceVerified != null:
return deviceVerified(_that.session,_that.otpTicket);case AuthSignedOut() when signedOut != null:
return signedOut();case _AuthSessionChanged() when sessionChanged != null:
return sessionChanged(_that.session);case _:
  return null;

}
}

}

/// @nodoc


class AuthLoginSubmitted implements AuthEvent {
  const AuthLoginSubmitted({required this.identifier, required this.pin});
  

 final  String identifier;
 final  String pin;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthLoginSubmittedCopyWith<AuthLoginSubmitted> get copyWith => _$AuthLoginSubmittedCopyWithImpl<AuthLoginSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoginSubmitted&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,identifier,pin);

@override
String toString() {
  return 'AuthEvent.loginSubmitted(identifier: $identifier, pin: $pin)';
}


}

/// @nodoc
abstract mixin class $AuthLoginSubmittedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthLoginSubmittedCopyWith(AuthLoginSubmitted value, $Res Function(AuthLoginSubmitted) _then) = _$AuthLoginSubmittedCopyWithImpl;
@useResult
$Res call({
 String identifier, String pin
});




}
/// @nodoc
class _$AuthLoginSubmittedCopyWithImpl<$Res>
    implements $AuthLoginSubmittedCopyWith<$Res> {
  _$AuthLoginSubmittedCopyWithImpl(this._self, this._then);

  final AuthLoginSubmitted _self;
  final $Res Function(AuthLoginSubmitted) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? identifier = null,Object? pin = null,}) {
  return _then(AuthLoginSubmitted(
identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthDeviceVerified implements AuthEvent {
  const AuthDeviceVerified(this.session, this.otpTicket);
  

 final  AuthSession session;
 final  String otpTicket;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthDeviceVerifiedCopyWith<AuthDeviceVerified> get copyWith => _$AuthDeviceVerifiedCopyWithImpl<AuthDeviceVerified>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthDeviceVerified&&(identical(other.session, session) || other.session == session)&&(identical(other.otpTicket, otpTicket) || other.otpTicket == otpTicket));
}


@override
int get hashCode => Object.hash(runtimeType,session,otpTicket);

@override
String toString() {
  return 'AuthEvent.deviceVerified(session: $session, otpTicket: $otpTicket)';
}


}

/// @nodoc
abstract mixin class $AuthDeviceVerifiedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthDeviceVerifiedCopyWith(AuthDeviceVerified value, $Res Function(AuthDeviceVerified) _then) = _$AuthDeviceVerifiedCopyWithImpl;
@useResult
$Res call({
 AuthSession session, String otpTicket
});




}
/// @nodoc
class _$AuthDeviceVerifiedCopyWithImpl<$Res>
    implements $AuthDeviceVerifiedCopyWith<$Res> {
  _$AuthDeviceVerifiedCopyWithImpl(this._self, this._then);

  final AuthDeviceVerified _self;
  final $Res Function(AuthDeviceVerified) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,Object? otpTicket = null,}) {
  return _then(AuthDeviceVerified(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as AuthSession,null == otpTicket ? _self.otpTicket : otpTicket // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthSignedOut implements AuthEvent {
  const AuthSignedOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSignedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signedOut()';
}


}




/// @nodoc


class _AuthSessionChanged implements AuthEvent {
  const _AuthSessionChanged(this.session);
  

 final  AuthSession? session;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionChangedCopyWith<_AuthSessionChanged> get copyWith => __$AuthSessionChangedCopyWithImpl<_AuthSessionChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSessionChanged&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'AuthEvent.sessionChanged(session: $session)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionChangedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$AuthSessionChangedCopyWith(_AuthSessionChanged value, $Res Function(_AuthSessionChanged) _then) = __$AuthSessionChangedCopyWithImpl;
@useResult
$Res call({
 AuthSession? session
});




}
/// @nodoc
class __$AuthSessionChangedCopyWithImpl<$Res>
    implements _$AuthSessionChangedCopyWith<$Res> {
  __$AuthSessionChangedCopyWithImpl(this._self, this._then);

  final _AuthSessionChanged _self;
  final $Res Function(_AuthSessionChanged) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = freezed,}) {
  return _then(_AuthSessionChanged(
freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as AuthSession?,
  ));
}


}

/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthUnauthenticated value)?  unauthenticated,TResult Function( AuthAuthenticated value)?  authenticated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthUnauthenticated value)  unauthenticated,required TResult Function( AuthAuthenticated value)  authenticated,}){
final _that = this;
switch (_that) {
case AuthUnauthenticated():
return unauthenticated(_that);case AuthAuthenticated():
return authenticated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthUnauthenticated value)?  unauthenticated,TResult? Function( AuthAuthenticated value)?  authenticated,}){
final _that = this;
switch (_that) {
case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( FormStatus status,  int attemptsLeft,  AuthError? error,  AuthSession? pendingDeviceSession,  DateTime? lockedUntil,  Duration? nextLockout)?  unauthenticated,TResult Function( AuthSession session)?  authenticated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that.status,_that.attemptsLeft,_that.error,_that.pendingDeviceSession,_that.lockedUntil,_that.nextLockout);case AuthAuthenticated() when authenticated != null:
return authenticated(_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( FormStatus status,  int attemptsLeft,  AuthError? error,  AuthSession? pendingDeviceSession,  DateTime? lockedUntil,  Duration? nextLockout)  unauthenticated,required TResult Function( AuthSession session)  authenticated,}) {final _that = this;
switch (_that) {
case AuthUnauthenticated():
return unauthenticated(_that.status,_that.attemptsLeft,_that.error,_that.pendingDeviceSession,_that.lockedUntil,_that.nextLockout);case AuthAuthenticated():
return authenticated(_that.session);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( FormStatus status,  int attemptsLeft,  AuthError? error,  AuthSession? pendingDeviceSession,  DateTime? lockedUntil,  Duration? nextLockout)?  unauthenticated,TResult? Function( AuthSession session)?  authenticated,}) {final _that = this;
switch (_that) {
case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that.status,_that.attemptsLeft,_that.error,_that.pendingDeviceSession,_that.lockedUntil,_that.nextLockout);case AuthAuthenticated() when authenticated != null:
return authenticated(_that.session);case _:
  return null;

}
}

}

/// @nodoc


class AuthUnauthenticated implements AuthState {
  const AuthUnauthenticated({this.status = FormStatus.idle, this.attemptsLeft = LockoutPolicy.maxAttempts, this.error, this.pendingDeviceSession, this.lockedUntil, this.nextLockout});
  

@JsonKey() final  FormStatus status;
@JsonKey() final  int attemptsLeft;
 final  AuthError? error;
 final  AuthSession? pendingDeviceSession;
 final  DateTime? lockedUntil;
/// Cuánto durará el bloqueo si se agotan los intentos (escala por nivel).
 final  Duration? nextLockout;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUnauthenticatedCopyWith<AuthUnauthenticated> get copyWith => _$AuthUnauthenticatedCopyWithImpl<AuthUnauthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUnauthenticated&&(identical(other.status, status) || other.status == status)&&(identical(other.attemptsLeft, attemptsLeft) || other.attemptsLeft == attemptsLeft)&&(identical(other.error, error) || other.error == error)&&(identical(other.pendingDeviceSession, pendingDeviceSession) || other.pendingDeviceSession == pendingDeviceSession)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil)&&(identical(other.nextLockout, nextLockout) || other.nextLockout == nextLockout));
}


@override
int get hashCode => Object.hash(runtimeType,status,attemptsLeft,error,pendingDeviceSession,lockedUntil,nextLockout);

@override
String toString() {
  return 'AuthState.unauthenticated(status: $status, attemptsLeft: $attemptsLeft, error: $error, pendingDeviceSession: $pendingDeviceSession, lockedUntil: $lockedUntil, nextLockout: $nextLockout)';
}


}

/// @nodoc
abstract mixin class $AuthUnauthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthUnauthenticatedCopyWith(AuthUnauthenticated value, $Res Function(AuthUnauthenticated) _then) = _$AuthUnauthenticatedCopyWithImpl;
@useResult
$Res call({
 FormStatus status, int attemptsLeft, AuthError? error, AuthSession? pendingDeviceSession, DateTime? lockedUntil, Duration? nextLockout
});




}
/// @nodoc
class _$AuthUnauthenticatedCopyWithImpl<$Res>
    implements $AuthUnauthenticatedCopyWith<$Res> {
  _$AuthUnauthenticatedCopyWithImpl(this._self, this._then);

  final AuthUnauthenticated _self;
  final $Res Function(AuthUnauthenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,Object? attemptsLeft = null,Object? error = freezed,Object? pendingDeviceSession = freezed,Object? lockedUntil = freezed,Object? nextLockout = freezed,}) {
  return _then(AuthUnauthenticated(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FormStatus,attemptsLeft: null == attemptsLeft ? _self.attemptsLeft : attemptsLeft // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AuthError?,pendingDeviceSession: freezed == pendingDeviceSession ? _self.pendingDeviceSession : pendingDeviceSession // ignore: cast_nullable_to_non_nullable
as AuthSession?,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,nextLockout: freezed == nextLockout ? _self.nextLockout : nextLockout // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class AuthAuthenticated implements AuthState {
  const AuthAuthenticated(this.session);
  

 final  AuthSession session;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthAuthenticatedCopyWith<AuthAuthenticated> get copyWith => _$AuthAuthenticatedCopyWithImpl<AuthAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthAuthenticated&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'AuthState.authenticated(session: $session)';
}


}

/// @nodoc
abstract mixin class $AuthAuthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthAuthenticatedCopyWith(AuthAuthenticated value, $Res Function(AuthAuthenticated) _then) = _$AuthAuthenticatedCopyWithImpl;
@useResult
$Res call({
 AuthSession session
});




}
/// @nodoc
class _$AuthAuthenticatedCopyWithImpl<$Res>
    implements $AuthAuthenticatedCopyWith<$Res> {
  _$AuthAuthenticatedCopyWithImpl(this._self, this._then);

  final AuthAuthenticated _self;
  final $Res Function(AuthAuthenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(AuthAuthenticated(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as AuthSession,
  ));
}


}

// dart format on
