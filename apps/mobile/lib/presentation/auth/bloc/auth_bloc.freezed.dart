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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthLoginSubmitted value)?  loginSubmitted,TResult Function( AuthRegisterSubmitted value)?  registerSubmitted,TResult Function( AuthSignedOut value)?  signedOut,TResult Function( _AuthSessionChanged value)?  sessionChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthRegisterSubmitted() when registerSubmitted != null:
return registerSubmitted(_that);case AuthSignedOut() when signedOut != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthLoginSubmitted value)  loginSubmitted,required TResult Function( AuthRegisterSubmitted value)  registerSubmitted,required TResult Function( AuthSignedOut value)  signedOut,required TResult Function( _AuthSessionChanged value)  sessionChanged,}){
final _that = this;
switch (_that) {
case AuthLoginSubmitted():
return loginSubmitted(_that);case AuthRegisterSubmitted():
return registerSubmitted(_that);case AuthSignedOut():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthLoginSubmitted value)?  loginSubmitted,TResult? Function( AuthRegisterSubmitted value)?  registerSubmitted,TResult? Function( AuthSignedOut value)?  signedOut,TResult? Function( _AuthSessionChanged value)?  sessionChanged,}){
final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthRegisterSubmitted() when registerSubmitted != null:
return registerSubmitted(_that);case AuthSignedOut() when signedOut != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String identifier,  String pin)?  loginSubmitted,TResult Function( String dni,  String? alias,  String pin)?  registerSubmitted,TResult Function()?  signedOut,TResult Function( AuthSession? session)?  sessionChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.identifier,_that.pin);case AuthRegisterSubmitted() when registerSubmitted != null:
return registerSubmitted(_that.dni,_that.alias,_that.pin);case AuthSignedOut() when signedOut != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String identifier,  String pin)  loginSubmitted,required TResult Function( String dni,  String? alias,  String pin)  registerSubmitted,required TResult Function()  signedOut,required TResult Function( AuthSession? session)  sessionChanged,}) {final _that = this;
switch (_that) {
case AuthLoginSubmitted():
return loginSubmitted(_that.identifier,_that.pin);case AuthRegisterSubmitted():
return registerSubmitted(_that.dni,_that.alias,_that.pin);case AuthSignedOut():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String identifier,  String pin)?  loginSubmitted,TResult? Function( String dni,  String? alias,  String pin)?  registerSubmitted,TResult? Function()?  signedOut,TResult? Function( AuthSession? session)?  sessionChanged,}) {final _that = this;
switch (_that) {
case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.identifier,_that.pin);case AuthRegisterSubmitted() when registerSubmitted != null:
return registerSubmitted(_that.dni,_that.alias,_that.pin);case AuthSignedOut() when signedOut != null:
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


class AuthRegisterSubmitted implements AuthEvent {
  const AuthRegisterSubmitted({required this.dni, this.alias, required this.pin});
  

 final  String dni;
 final  String? alias;
 final  String pin;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthRegisterSubmittedCopyWith<AuthRegisterSubmitted> get copyWith => _$AuthRegisterSubmittedCopyWithImpl<AuthRegisterSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthRegisterSubmitted&&(identical(other.dni, dni) || other.dni == dni)&&(identical(other.alias, alias) || other.alias == alias)&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,dni,alias,pin);

@override
String toString() {
  return 'AuthEvent.registerSubmitted(dni: $dni, alias: $alias, pin: $pin)';
}


}

/// @nodoc
abstract mixin class $AuthRegisterSubmittedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthRegisterSubmittedCopyWith(AuthRegisterSubmitted value, $Res Function(AuthRegisterSubmitted) _then) = _$AuthRegisterSubmittedCopyWithImpl;
@useResult
$Res call({
 String dni, String? alias, String pin
});




}
/// @nodoc
class _$AuthRegisterSubmittedCopyWithImpl<$Res>
    implements $AuthRegisterSubmittedCopyWith<$Res> {
  _$AuthRegisterSubmittedCopyWithImpl(this._self, this._then);

  final AuthRegisterSubmitted _self;
  final $Res Function(AuthRegisterSubmitted) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dni = null,Object? alias = freezed,Object? pin = null,}) {
  return _then(AuthRegisterSubmitted(
dni: null == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as String,alias: freezed == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String?,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( FormStatus status,  AuthError? error)?  unauthenticated,TResult Function( AuthSession session)?  authenticated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that.status,_that.error);case AuthAuthenticated() when authenticated != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( FormStatus status,  AuthError? error)  unauthenticated,required TResult Function( AuthSession session)  authenticated,}) {final _that = this;
switch (_that) {
case AuthUnauthenticated():
return unauthenticated(_that.status,_that.error);case AuthAuthenticated():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( FormStatus status,  AuthError? error)?  unauthenticated,TResult? Function( AuthSession session)?  authenticated,}) {final _that = this;
switch (_that) {
case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that.status,_that.error);case AuthAuthenticated() when authenticated != null:
return authenticated(_that.session);case _:
  return null;

}
}

}

/// @nodoc


class AuthUnauthenticated implements AuthState {
  const AuthUnauthenticated({this.status = FormStatus.idle, this.error});
  

@JsonKey() final  FormStatus status;
 final  AuthError? error;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUnauthenticatedCopyWith<AuthUnauthenticated> get copyWith => _$AuthUnauthenticatedCopyWithImpl<AuthUnauthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUnauthenticated&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,status,error);

@override
String toString() {
  return 'AuthState.unauthenticated(status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class $AuthUnauthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthUnauthenticatedCopyWith(AuthUnauthenticated value, $Res Function(AuthUnauthenticated) _then) = _$AuthUnauthenticatedCopyWithImpl;
@useResult
$Res call({
 FormStatus status, AuthError? error
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
@pragma('vm:prefer-inline') $Res call({Object? status = null,Object? error = freezed,}) {
  return _then(AuthUnauthenticated(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FormStatus,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AuthError?,
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
