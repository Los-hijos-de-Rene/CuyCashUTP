// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'register_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RegisterEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent()';
}


}

/// @nodoc
class $RegisterEventCopyWith<$Res>  {
$RegisterEventCopyWith(RegisterEvent _, $Res Function(RegisterEvent) __);
}


/// Adds pattern-matching-related methods to [RegisterEvent].
extension RegisterEventPatterns on RegisterEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RegisterFieldChanged value)?  fieldChanged,TResult Function( RegisterCaptured value)?  captured,TResult Function( RegisterCaptureFailed value)?  captureFailed,TResult Function( RegisterFaceScanStarted value)?  faceScanStarted,TResult Function( RegisterFaceScanCompleted value)?  faceScanCompleted,TResult Function( RegisterPinChanged value)?  pinChanged,TResult Function( RegisterBiometricToggled value)?  biometricToggled,TResult Function( RegisterStepAdvanced value)?  stepAdvanced,TResult Function( RegisterStepBack value)?  stepBack,TResult Function( RegisterSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that);case RegisterCaptured() when captured != null:
return captured(_that);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted(_that);case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted(_that);case RegisterPinChanged() when pinChanged != null:
return pinChanged(_that);case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that);case RegisterStepBack() when stepBack != null:
return stepBack(_that);case RegisterSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RegisterFieldChanged value)  fieldChanged,required TResult Function( RegisterCaptured value)  captured,required TResult Function( RegisterCaptureFailed value)  captureFailed,required TResult Function( RegisterFaceScanStarted value)  faceScanStarted,required TResult Function( RegisterFaceScanCompleted value)  faceScanCompleted,required TResult Function( RegisterPinChanged value)  pinChanged,required TResult Function( RegisterBiometricToggled value)  biometricToggled,required TResult Function( RegisterStepAdvanced value)  stepAdvanced,required TResult Function( RegisterStepBack value)  stepBack,required TResult Function( RegisterSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case RegisterFieldChanged():
return fieldChanged(_that);case RegisterCaptured():
return captured(_that);case RegisterCaptureFailed():
return captureFailed(_that);case RegisterFaceScanStarted():
return faceScanStarted(_that);case RegisterFaceScanCompleted():
return faceScanCompleted(_that);case RegisterPinChanged():
return pinChanged(_that);case RegisterBiometricToggled():
return biometricToggled(_that);case RegisterStepAdvanced():
return stepAdvanced(_that);case RegisterStepBack():
return stepBack(_that);case RegisterSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RegisterFieldChanged value)?  fieldChanged,TResult? Function( RegisterCaptured value)?  captured,TResult? Function( RegisterCaptureFailed value)?  captureFailed,TResult? Function( RegisterFaceScanStarted value)?  faceScanStarted,TResult? Function( RegisterFaceScanCompleted value)?  faceScanCompleted,TResult? Function( RegisterPinChanged value)?  pinChanged,TResult? Function( RegisterBiometricToggled value)?  biometricToggled,TResult? Function( RegisterStepAdvanced value)?  stepAdvanced,TResult? Function( RegisterStepBack value)?  stepBack,TResult? Function( RegisterSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that);case RegisterCaptured() when captured != null:
return captured(_that);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted(_that);case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted(_that);case RegisterPinChanged() when pinChanged != null:
return pinChanged(_that);case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that);case RegisterStepBack() when stepBack != null:
return stepBack(_that);case RegisterSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( RegisterField field,  String value)?  fieldChanged,TResult Function( DocSide side)?  captured,TResult Function( DocSide side)?  captureFailed,TResult Function()?  faceScanStarted,TResult Function()?  faceScanCompleted,TResult Function( String pin)?  pinChanged,TResult Function( bool value)?  biometricToggled,TResult Function()?  stepAdvanced,TResult Function()?  stepBack,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that.field,_that.value);case RegisterCaptured() when captured != null:
return captured(_that.side);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that.side);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted();case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted();case RegisterPinChanged() when pinChanged != null:
return pinChanged(_that.pin);case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that.value);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced();case RegisterStepBack() when stepBack != null:
return stepBack();case RegisterSubmitted() when submitted != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( RegisterField field,  String value)  fieldChanged,required TResult Function( DocSide side)  captured,required TResult Function( DocSide side)  captureFailed,required TResult Function()  faceScanStarted,required TResult Function()  faceScanCompleted,required TResult Function( String pin)  pinChanged,required TResult Function( bool value)  biometricToggled,required TResult Function()  stepAdvanced,required TResult Function()  stepBack,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case RegisterFieldChanged():
return fieldChanged(_that.field,_that.value);case RegisterCaptured():
return captured(_that.side);case RegisterCaptureFailed():
return captureFailed(_that.side);case RegisterFaceScanStarted():
return faceScanStarted();case RegisterFaceScanCompleted():
return faceScanCompleted();case RegisterPinChanged():
return pinChanged(_that.pin);case RegisterBiometricToggled():
return biometricToggled(_that.value);case RegisterStepAdvanced():
return stepAdvanced();case RegisterStepBack():
return stepBack();case RegisterSubmitted():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( RegisterField field,  String value)?  fieldChanged,TResult? Function( DocSide side)?  captured,TResult? Function( DocSide side)?  captureFailed,TResult? Function()?  faceScanStarted,TResult? Function()?  faceScanCompleted,TResult? Function( String pin)?  pinChanged,TResult? Function( bool value)?  biometricToggled,TResult? Function()?  stepAdvanced,TResult? Function()?  stepBack,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that.field,_that.value);case RegisterCaptured() when captured != null:
return captured(_that.side);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that.side);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted();case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted();case RegisterPinChanged() when pinChanged != null:
return pinChanged(_that.pin);case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that.value);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced();case RegisterStepBack() when stepBack != null:
return stepBack();case RegisterSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class RegisterFieldChanged implements RegisterEvent {
  const RegisterFieldChanged(this.field, this.value);
  

 final  RegisterField field;
 final  String value;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterFieldChangedCopyWith<RegisterFieldChanged> get copyWith => _$RegisterFieldChangedCopyWithImpl<RegisterFieldChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterFieldChanged&&(identical(other.field, field) || other.field == field)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,field,value);

@override
String toString() {
  return 'RegisterEvent.fieldChanged(field: $field, value: $value)';
}


}

/// @nodoc
abstract mixin class $RegisterFieldChangedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterFieldChangedCopyWith(RegisterFieldChanged value, $Res Function(RegisterFieldChanged) _then) = _$RegisterFieldChangedCopyWithImpl;
@useResult
$Res call({
 RegisterField field, String value
});




}
/// @nodoc
class _$RegisterFieldChangedCopyWithImpl<$Res>
    implements $RegisterFieldChangedCopyWith<$Res> {
  _$RegisterFieldChangedCopyWithImpl(this._self, this._then);

  final RegisterFieldChanged _self;
  final $Res Function(RegisterFieldChanged) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,Object? value = null,}) {
  return _then(RegisterFieldChanged(
null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as RegisterField,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RegisterCaptured implements RegisterEvent {
  const RegisterCaptured(this.side);
  

 final  DocSide side;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterCapturedCopyWith<RegisterCaptured> get copyWith => _$RegisterCapturedCopyWithImpl<RegisterCaptured>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterCaptured&&(identical(other.side, side) || other.side == side));
}


@override
int get hashCode => Object.hash(runtimeType,side);

@override
String toString() {
  return 'RegisterEvent.captured(side: $side)';
}


}

/// @nodoc
abstract mixin class $RegisterCapturedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterCapturedCopyWith(RegisterCaptured value, $Res Function(RegisterCaptured) _then) = _$RegisterCapturedCopyWithImpl;
@useResult
$Res call({
 DocSide side
});




}
/// @nodoc
class _$RegisterCapturedCopyWithImpl<$Res>
    implements $RegisterCapturedCopyWith<$Res> {
  _$RegisterCapturedCopyWithImpl(this._self, this._then);

  final RegisterCaptured _self;
  final $Res Function(RegisterCaptured) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? side = null,}) {
  return _then(RegisterCaptured(
null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as DocSide,
  ));
}


}

/// @nodoc


class RegisterCaptureFailed implements RegisterEvent {
  const RegisterCaptureFailed(this.side);
  

 final  DocSide side;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterCaptureFailedCopyWith<RegisterCaptureFailed> get copyWith => _$RegisterCaptureFailedCopyWithImpl<RegisterCaptureFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterCaptureFailed&&(identical(other.side, side) || other.side == side));
}


@override
int get hashCode => Object.hash(runtimeType,side);

@override
String toString() {
  return 'RegisterEvent.captureFailed(side: $side)';
}


}

/// @nodoc
abstract mixin class $RegisterCaptureFailedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterCaptureFailedCopyWith(RegisterCaptureFailed value, $Res Function(RegisterCaptureFailed) _then) = _$RegisterCaptureFailedCopyWithImpl;
@useResult
$Res call({
 DocSide side
});




}
/// @nodoc
class _$RegisterCaptureFailedCopyWithImpl<$Res>
    implements $RegisterCaptureFailedCopyWith<$Res> {
  _$RegisterCaptureFailedCopyWithImpl(this._self, this._then);

  final RegisterCaptureFailed _self;
  final $Res Function(RegisterCaptureFailed) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? side = null,}) {
  return _then(RegisterCaptureFailed(
null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as DocSide,
  ));
}


}

/// @nodoc


class RegisterFaceScanStarted implements RegisterEvent {
  const RegisterFaceScanStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterFaceScanStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.faceScanStarted()';
}


}




/// @nodoc


class RegisterFaceScanCompleted implements RegisterEvent {
  const RegisterFaceScanCompleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterFaceScanCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.faceScanCompleted()';
}


}




/// @nodoc


class RegisterPinChanged implements RegisterEvent {
  const RegisterPinChanged(this.pin);
  

 final  String pin;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterPinChangedCopyWith<RegisterPinChanged> get copyWith => _$RegisterPinChangedCopyWithImpl<RegisterPinChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterPinChanged&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,pin);

@override
String toString() {
  return 'RegisterEvent.pinChanged(pin: $pin)';
}


}

/// @nodoc
abstract mixin class $RegisterPinChangedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterPinChangedCopyWith(RegisterPinChanged value, $Res Function(RegisterPinChanged) _then) = _$RegisterPinChangedCopyWithImpl;
@useResult
$Res call({
 String pin
});




}
/// @nodoc
class _$RegisterPinChangedCopyWithImpl<$Res>
    implements $RegisterPinChangedCopyWith<$Res> {
  _$RegisterPinChangedCopyWithImpl(this._self, this._then);

  final RegisterPinChanged _self;
  final $Res Function(RegisterPinChanged) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pin = null,}) {
  return _then(RegisterPinChanged(
null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RegisterBiometricToggled implements RegisterEvent {
  const RegisterBiometricToggled(this.value);
  

 final  bool value;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterBiometricToggledCopyWith<RegisterBiometricToggled> get copyWith => _$RegisterBiometricToggledCopyWithImpl<RegisterBiometricToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterBiometricToggled&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'RegisterEvent.biometricToggled(value: $value)';
}


}

/// @nodoc
abstract mixin class $RegisterBiometricToggledCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterBiometricToggledCopyWith(RegisterBiometricToggled value, $Res Function(RegisterBiometricToggled) _then) = _$RegisterBiometricToggledCopyWithImpl;
@useResult
$Res call({
 bool value
});




}
/// @nodoc
class _$RegisterBiometricToggledCopyWithImpl<$Res>
    implements $RegisterBiometricToggledCopyWith<$Res> {
  _$RegisterBiometricToggledCopyWithImpl(this._self, this._then);

  final RegisterBiometricToggled _self;
  final $Res Function(RegisterBiometricToggled) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(RegisterBiometricToggled(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class RegisterStepAdvanced implements RegisterEvent {
  const RegisterStepAdvanced();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterStepAdvanced);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.stepAdvanced()';
}


}




/// @nodoc


class RegisterStepBack implements RegisterEvent {
  const RegisterStepBack();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterStepBack);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.stepBack()';
}


}




/// @nodoc


class RegisterSubmitted implements RegisterEvent {
  const RegisterSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.submitted()';
}


}




/// @nodoc
mixin _$RegisterDraft {

 String get dni; String get nombres; String get apellidos; String get email; CaptureStatus get dniFront; CaptureStatus get dniBack; FaceScanStatus get faceStatus; String get pin; bool get biometricEnabled;
/// Create a copy of RegisterDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterDraftCopyWith<RegisterDraft> get copyWith => _$RegisterDraftCopyWithImpl<RegisterDraft>(this as RegisterDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterDraft&&(identical(other.dni, dni) || other.dni == dni)&&(identical(other.nombres, nombres) || other.nombres == nombres)&&(identical(other.apellidos, apellidos) || other.apellidos == apellidos)&&(identical(other.email, email) || other.email == email)&&(identical(other.dniFront, dniFront) || other.dniFront == dniFront)&&(identical(other.dniBack, dniBack) || other.dniBack == dniBack)&&(identical(other.faceStatus, faceStatus) || other.faceStatus == faceStatus)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,dni,nombres,apellidos,email,dniFront,dniBack,faceStatus,pin,biometricEnabled);

@override
String toString() {
  return 'RegisterDraft(dni: $dni, nombres: $nombres, apellidos: $apellidos, email: $email, dniFront: $dniFront, dniBack: $dniBack, faceStatus: $faceStatus, pin: $pin, biometricEnabled: $biometricEnabled)';
}


}

/// @nodoc
abstract mixin class $RegisterDraftCopyWith<$Res>  {
  factory $RegisterDraftCopyWith(RegisterDraft value, $Res Function(RegisterDraft) _then) = _$RegisterDraftCopyWithImpl;
@useResult
$Res call({
 String dni, String nombres, String apellidos, String email, CaptureStatus dniFront, CaptureStatus dniBack, FaceScanStatus faceStatus, String pin, bool biometricEnabled
});




}
/// @nodoc
class _$RegisterDraftCopyWithImpl<$Res>
    implements $RegisterDraftCopyWith<$Res> {
  _$RegisterDraftCopyWithImpl(this._self, this._then);

  final RegisterDraft _self;
  final $Res Function(RegisterDraft) _then;

/// Create a copy of RegisterDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dni = null,Object? nombres = null,Object? apellidos = null,Object? email = null,Object? dniFront = null,Object? dniBack = null,Object? faceStatus = null,Object? pin = null,Object? biometricEnabled = null,}) {
  return _then(_self.copyWith(
dni: null == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as String,nombres: null == nombres ? _self.nombres : nombres // ignore: cast_nullable_to_non_nullable
as String,apellidos: null == apellidos ? _self.apellidos : apellidos // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,dniFront: null == dniFront ? _self.dniFront : dniFront // ignore: cast_nullable_to_non_nullable
as CaptureStatus,dniBack: null == dniBack ? _self.dniBack : dniBack // ignore: cast_nullable_to_non_nullable
as CaptureStatus,faceStatus: null == faceStatus ? _self.faceStatus : faceStatus // ignore: cast_nullable_to_non_nullable
as FaceScanStatus,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,biometricEnabled: null == biometricEnabled ? _self.biometricEnabled : biometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterDraft].
extension RegisterDraftPatterns on RegisterDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterDraft value)  $default,){
final _that = this;
switch (_that) {
case _RegisterDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterDraft value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dni,  String nombres,  String apellidos,  String email,  CaptureStatus dniFront,  CaptureStatus dniBack,  FaceScanStatus faceStatus,  String pin,  bool biometricEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterDraft() when $default != null:
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.dniFront,_that.dniBack,_that.faceStatus,_that.pin,_that.biometricEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dni,  String nombres,  String apellidos,  String email,  CaptureStatus dniFront,  CaptureStatus dniBack,  FaceScanStatus faceStatus,  String pin,  bool biometricEnabled)  $default,) {final _that = this;
switch (_that) {
case _RegisterDraft():
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.dniFront,_that.dniBack,_that.faceStatus,_that.pin,_that.biometricEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dni,  String nombres,  String apellidos,  String email,  CaptureStatus dniFront,  CaptureStatus dniBack,  FaceScanStatus faceStatus,  String pin,  bool biometricEnabled)?  $default,) {final _that = this;
switch (_that) {
case _RegisterDraft() when $default != null:
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.dniFront,_that.dniBack,_that.faceStatus,_that.pin,_that.biometricEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _RegisterDraft implements RegisterDraft {
  const _RegisterDraft({this.dni = '', this.nombres = '', this.apellidos = '', this.email = '', this.dniFront = CaptureStatus.empty, this.dniBack = CaptureStatus.empty, this.faceStatus = FaceScanStatus.idle, this.pin = '', this.biometricEnabled = true});
  

@override@JsonKey() final  String dni;
@override@JsonKey() final  String nombres;
@override@JsonKey() final  String apellidos;
@override@JsonKey() final  String email;
@override@JsonKey() final  CaptureStatus dniFront;
@override@JsonKey() final  CaptureStatus dniBack;
@override@JsonKey() final  FaceScanStatus faceStatus;
@override@JsonKey() final  String pin;
@override@JsonKey() final  bool biometricEnabled;

/// Create a copy of RegisterDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterDraftCopyWith<_RegisterDraft> get copyWith => __$RegisterDraftCopyWithImpl<_RegisterDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterDraft&&(identical(other.dni, dni) || other.dni == dni)&&(identical(other.nombres, nombres) || other.nombres == nombres)&&(identical(other.apellidos, apellidos) || other.apellidos == apellidos)&&(identical(other.email, email) || other.email == email)&&(identical(other.dniFront, dniFront) || other.dniFront == dniFront)&&(identical(other.dniBack, dniBack) || other.dniBack == dniBack)&&(identical(other.faceStatus, faceStatus) || other.faceStatus == faceStatus)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,dni,nombres,apellidos,email,dniFront,dniBack,faceStatus,pin,biometricEnabled);

@override
String toString() {
  return 'RegisterDraft(dni: $dni, nombres: $nombres, apellidos: $apellidos, email: $email, dniFront: $dniFront, dniBack: $dniBack, faceStatus: $faceStatus, pin: $pin, biometricEnabled: $biometricEnabled)';
}


}

/// @nodoc
abstract mixin class _$RegisterDraftCopyWith<$Res> implements $RegisterDraftCopyWith<$Res> {
  factory _$RegisterDraftCopyWith(_RegisterDraft value, $Res Function(_RegisterDraft) _then) = __$RegisterDraftCopyWithImpl;
@override @useResult
$Res call({
 String dni, String nombres, String apellidos, String email, CaptureStatus dniFront, CaptureStatus dniBack, FaceScanStatus faceStatus, String pin, bool biometricEnabled
});




}
/// @nodoc
class __$RegisterDraftCopyWithImpl<$Res>
    implements _$RegisterDraftCopyWith<$Res> {
  __$RegisterDraftCopyWithImpl(this._self, this._then);

  final _RegisterDraft _self;
  final $Res Function(_RegisterDraft) _then;

/// Create a copy of RegisterDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dni = null,Object? nombres = null,Object? apellidos = null,Object? email = null,Object? dniFront = null,Object? dniBack = null,Object? faceStatus = null,Object? pin = null,Object? biometricEnabled = null,}) {
  return _then(_RegisterDraft(
dni: null == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as String,nombres: null == nombres ? _self.nombres : nombres // ignore: cast_nullable_to_non_nullable
as String,apellidos: null == apellidos ? _self.apellidos : apellidos // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,dniFront: null == dniFront ? _self.dniFront : dniFront // ignore: cast_nullable_to_non_nullable
as CaptureStatus,dniBack: null == dniBack ? _self.dniBack : dniBack // ignore: cast_nullable_to_non_nullable
as CaptureStatus,faceStatus: null == faceStatus ? _self.faceStatus : faceStatus // ignore: cast_nullable_to_non_nullable
as FaceScanStatus,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,biometricEnabled: null == biometricEnabled ? _self.biometricEnabled : biometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$RegisterErrors {

 FieldError? get dni; FieldError? get nombres; FieldError? get apellidos; FieldError? get email; bool get showBanner;
/// Create a copy of RegisterErrors
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterErrorsCopyWith<RegisterErrors> get copyWith => _$RegisterErrorsCopyWithImpl<RegisterErrors>(this as RegisterErrors, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterErrors&&(identical(other.dni, dni) || other.dni == dni)&&(identical(other.nombres, nombres) || other.nombres == nombres)&&(identical(other.apellidos, apellidos) || other.apellidos == apellidos)&&(identical(other.email, email) || other.email == email)&&(identical(other.showBanner, showBanner) || other.showBanner == showBanner));
}


@override
int get hashCode => Object.hash(runtimeType,dni,nombres,apellidos,email,showBanner);

@override
String toString() {
  return 'RegisterErrors(dni: $dni, nombres: $nombres, apellidos: $apellidos, email: $email, showBanner: $showBanner)';
}


}

/// @nodoc
abstract mixin class $RegisterErrorsCopyWith<$Res>  {
  factory $RegisterErrorsCopyWith(RegisterErrors value, $Res Function(RegisterErrors) _then) = _$RegisterErrorsCopyWithImpl;
@useResult
$Res call({
 FieldError? dni, FieldError? nombres, FieldError? apellidos, FieldError? email, bool showBanner
});




}
/// @nodoc
class _$RegisterErrorsCopyWithImpl<$Res>
    implements $RegisterErrorsCopyWith<$Res> {
  _$RegisterErrorsCopyWithImpl(this._self, this._then);

  final RegisterErrors _self;
  final $Res Function(RegisterErrors) _then;

/// Create a copy of RegisterErrors
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dni = freezed,Object? nombres = freezed,Object? apellidos = freezed,Object? email = freezed,Object? showBanner = null,}) {
  return _then(_self.copyWith(
dni: freezed == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as FieldError?,nombres: freezed == nombres ? _self.nombres : nombres // ignore: cast_nullable_to_non_nullable
as FieldError?,apellidos: freezed == apellidos ? _self.apellidos : apellidos // ignore: cast_nullable_to_non_nullable
as FieldError?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as FieldError?,showBanner: null == showBanner ? _self.showBanner : showBanner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterErrors].
extension RegisterErrorsPatterns on RegisterErrors {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterErrors value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterErrors() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterErrors value)  $default,){
final _that = this;
switch (_that) {
case _RegisterErrors():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterErrors value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterErrors() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FieldError? dni,  FieldError? nombres,  FieldError? apellidos,  FieldError? email,  bool showBanner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterErrors() when $default != null:
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.showBanner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FieldError? dni,  FieldError? nombres,  FieldError? apellidos,  FieldError? email,  bool showBanner)  $default,) {final _that = this;
switch (_that) {
case _RegisterErrors():
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.showBanner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FieldError? dni,  FieldError? nombres,  FieldError? apellidos,  FieldError? email,  bool showBanner)?  $default,) {final _that = this;
switch (_that) {
case _RegisterErrors() when $default != null:
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.showBanner);case _:
  return null;

}
}

}

/// @nodoc


class _RegisterErrors extends RegisterErrors {
  const _RegisterErrors({this.dni, this.nombres, this.apellidos, this.email, this.showBanner = false}): super._();
  

@override final  FieldError? dni;
@override final  FieldError? nombres;
@override final  FieldError? apellidos;
@override final  FieldError? email;
@override@JsonKey() final  bool showBanner;

/// Create a copy of RegisterErrors
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterErrorsCopyWith<_RegisterErrors> get copyWith => __$RegisterErrorsCopyWithImpl<_RegisterErrors>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterErrors&&(identical(other.dni, dni) || other.dni == dni)&&(identical(other.nombres, nombres) || other.nombres == nombres)&&(identical(other.apellidos, apellidos) || other.apellidos == apellidos)&&(identical(other.email, email) || other.email == email)&&(identical(other.showBanner, showBanner) || other.showBanner == showBanner));
}


@override
int get hashCode => Object.hash(runtimeType,dni,nombres,apellidos,email,showBanner);

@override
String toString() {
  return 'RegisterErrors(dni: $dni, nombres: $nombres, apellidos: $apellidos, email: $email, showBanner: $showBanner)';
}


}

/// @nodoc
abstract mixin class _$RegisterErrorsCopyWith<$Res> implements $RegisterErrorsCopyWith<$Res> {
  factory _$RegisterErrorsCopyWith(_RegisterErrors value, $Res Function(_RegisterErrors) _then) = __$RegisterErrorsCopyWithImpl;
@override @useResult
$Res call({
 FieldError? dni, FieldError? nombres, FieldError? apellidos, FieldError? email, bool showBanner
});




}
/// @nodoc
class __$RegisterErrorsCopyWithImpl<$Res>
    implements _$RegisterErrorsCopyWith<$Res> {
  __$RegisterErrorsCopyWithImpl(this._self, this._then);

  final _RegisterErrors _self;
  final $Res Function(_RegisterErrors) _then;

/// Create a copy of RegisterErrors
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dni = freezed,Object? nombres = freezed,Object? apellidos = freezed,Object? email = freezed,Object? showBanner = null,}) {
  return _then(_RegisterErrors(
dni: freezed == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as FieldError?,nombres: freezed == nombres ? _self.nombres : nombres // ignore: cast_nullable_to_non_nullable
as FieldError?,apellidos: freezed == apellidos ? _self.apellidos : apellidos // ignore: cast_nullable_to_non_nullable
as FieldError?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as FieldError?,showBanner: null == showBanner ? _self.showBanner : showBanner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$RegisterState {

 int get step; RegisterDraft get draft; RegisterErrors get errors; RegisterStatus get status; AuthError? get submitError;
/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterStateCopyWith<RegisterState> get copyWith => _$RegisterStateCopyWithImpl<RegisterState>(this as RegisterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterState&&(identical(other.step, step) || other.step == step)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.errors, errors) || other.errors == errors)&&(identical(other.status, status) || other.status == status)&&(identical(other.submitError, submitError) || other.submitError == submitError));
}


@override
int get hashCode => Object.hash(runtimeType,step,draft,errors,status,submitError);

@override
String toString() {
  return 'RegisterState(step: $step, draft: $draft, errors: $errors, status: $status, submitError: $submitError)';
}


}

/// @nodoc
abstract mixin class $RegisterStateCopyWith<$Res>  {
  factory $RegisterStateCopyWith(RegisterState value, $Res Function(RegisterState) _then) = _$RegisterStateCopyWithImpl;
@useResult
$Res call({
 int step, RegisterDraft draft, RegisterErrors errors, RegisterStatus status, AuthError? submitError
});


$RegisterDraftCopyWith<$Res> get draft;$RegisterErrorsCopyWith<$Res> get errors;

}
/// @nodoc
class _$RegisterStateCopyWithImpl<$Res>
    implements $RegisterStateCopyWith<$Res> {
  _$RegisterStateCopyWithImpl(this._self, this._then);

  final RegisterState _self;
  final $Res Function(RegisterState) _then;

/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? draft = null,Object? errors = null,Object? status = null,Object? submitError = freezed,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as RegisterDraft,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as RegisterErrors,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegisterStatus,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as AuthError?,
  ));
}
/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegisterDraftCopyWith<$Res> get draft {
  
  return $RegisterDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegisterErrorsCopyWith<$Res> get errors {
  
  return $RegisterErrorsCopyWith<$Res>(_self.errors, (value) {
    return _then(_self.copyWith(errors: value));
  });
}
}


/// Adds pattern-matching-related methods to [RegisterState].
extension RegisterStatePatterns on RegisterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterState value)  $default,){
final _that = this;
switch (_that) {
case _RegisterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterState value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int step,  RegisterDraft draft,  RegisterErrors errors,  RegisterStatus status,  AuthError? submitError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterState() when $default != null:
return $default(_that.step,_that.draft,_that.errors,_that.status,_that.submitError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int step,  RegisterDraft draft,  RegisterErrors errors,  RegisterStatus status,  AuthError? submitError)  $default,) {final _that = this;
switch (_that) {
case _RegisterState():
return $default(_that.step,_that.draft,_that.errors,_that.status,_that.submitError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int step,  RegisterDraft draft,  RegisterErrors errors,  RegisterStatus status,  AuthError? submitError)?  $default,) {final _that = this;
switch (_that) {
case _RegisterState() when $default != null:
return $default(_that.step,_that.draft,_that.errors,_that.status,_that.submitError);case _:
  return null;

}
}

}

/// @nodoc


class _RegisterState extends RegisterState {
  const _RegisterState({this.step = 0, this.draft = const RegisterDraft(), this.errors = const RegisterErrors(), this.status = RegisterStatus.editing, this.submitError}): super._();
  

@override@JsonKey() final  int step;
@override@JsonKey() final  RegisterDraft draft;
@override@JsonKey() final  RegisterErrors errors;
@override@JsonKey() final  RegisterStatus status;
@override final  AuthError? submitError;

/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterStateCopyWith<_RegisterState> get copyWith => __$RegisterStateCopyWithImpl<_RegisterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterState&&(identical(other.step, step) || other.step == step)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.errors, errors) || other.errors == errors)&&(identical(other.status, status) || other.status == status)&&(identical(other.submitError, submitError) || other.submitError == submitError));
}


@override
int get hashCode => Object.hash(runtimeType,step,draft,errors,status,submitError);

@override
String toString() {
  return 'RegisterState(step: $step, draft: $draft, errors: $errors, status: $status, submitError: $submitError)';
}


}

/// @nodoc
abstract mixin class _$RegisterStateCopyWith<$Res> implements $RegisterStateCopyWith<$Res> {
  factory _$RegisterStateCopyWith(_RegisterState value, $Res Function(_RegisterState) _then) = __$RegisterStateCopyWithImpl;
@override @useResult
$Res call({
 int step, RegisterDraft draft, RegisterErrors errors, RegisterStatus status, AuthError? submitError
});


@override $RegisterDraftCopyWith<$Res> get draft;@override $RegisterErrorsCopyWith<$Res> get errors;

}
/// @nodoc
class __$RegisterStateCopyWithImpl<$Res>
    implements _$RegisterStateCopyWith<$Res> {
  __$RegisterStateCopyWithImpl(this._self, this._then);

  final _RegisterState _self;
  final $Res Function(_RegisterState) _then;

/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? draft = null,Object? errors = null,Object? status = null,Object? submitError = freezed,}) {
  return _then(_RegisterState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as RegisterDraft,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as RegisterErrors,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegisterStatus,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as AuthError?,
  ));
}

/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegisterDraftCopyWith<$Res> get draft {
  
  return $RegisterDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegisterErrorsCopyWith<$Res> get errors {
  
  return $RegisterErrorsCopyWith<$Res>(_self.errors, (value) {
    return _then(_self.copyWith(errors: value));
  });
}
}

// dart format on
