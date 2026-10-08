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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RegisterFieldChanged value)?  fieldChanged,TResult Function( RegisterCaptured value)?  captured,TResult Function( RegisterCaptureFailed value)?  captureFailed,TResult Function( RegisterFaceScanStarted value)?  faceScanStarted,TResult Function( RegisterFaceScanCompleted value)?  faceScanCompleted,TResult Function( RegisterPinDigitPressed value)?  pinDigitPressed,TResult Function( RegisterPinBackspace value)?  pinBackspace,TResult Function( RegisterBiometricToggled value)?  biometricToggled,TResult Function( RegisterStepAdvanced value)?  stepAdvanced,TResult Function( RegisterStepBack value)?  stepBack,TResult Function( RegisterSubmitted value)?  submitted,TResult Function( RegisterAccountOpened value)?  accountOpened,TResult Function( RegisterBiometricNoticeShown value)?  biometricNoticeShown,TResult Function( RegisterBiometricChecked value)?  biometricChecked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that);case RegisterCaptured() when captured != null:
return captured(_that);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted(_that);case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted(_that);case RegisterPinDigitPressed() when pinDigitPressed != null:
return pinDigitPressed(_that);case RegisterPinBackspace() when pinBackspace != null:
return pinBackspace(_that);case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that);case RegisterStepBack() when stepBack != null:
return stepBack(_that);case RegisterSubmitted() when submitted != null:
return submitted(_that);case RegisterAccountOpened() when accountOpened != null:
return accountOpened(_that);case RegisterBiometricNoticeShown() when biometricNoticeShown != null:
return biometricNoticeShown(_that);case RegisterBiometricChecked() when biometricChecked != null:
return biometricChecked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RegisterFieldChanged value)  fieldChanged,required TResult Function( RegisterCaptured value)  captured,required TResult Function( RegisterCaptureFailed value)  captureFailed,required TResult Function( RegisterFaceScanStarted value)  faceScanStarted,required TResult Function( RegisterFaceScanCompleted value)  faceScanCompleted,required TResult Function( RegisterPinDigitPressed value)  pinDigitPressed,required TResult Function( RegisterPinBackspace value)  pinBackspace,required TResult Function( RegisterBiometricToggled value)  biometricToggled,required TResult Function( RegisterStepAdvanced value)  stepAdvanced,required TResult Function( RegisterStepBack value)  stepBack,required TResult Function( RegisterSubmitted value)  submitted,required TResult Function( RegisterAccountOpened value)  accountOpened,required TResult Function( RegisterBiometricNoticeShown value)  biometricNoticeShown,required TResult Function( RegisterBiometricChecked value)  biometricChecked,}){
final _that = this;
switch (_that) {
case RegisterFieldChanged():
return fieldChanged(_that);case RegisterCaptured():
return captured(_that);case RegisterCaptureFailed():
return captureFailed(_that);case RegisterFaceScanStarted():
return faceScanStarted(_that);case RegisterFaceScanCompleted():
return faceScanCompleted(_that);case RegisterPinDigitPressed():
return pinDigitPressed(_that);case RegisterPinBackspace():
return pinBackspace(_that);case RegisterBiometricToggled():
return biometricToggled(_that);case RegisterStepAdvanced():
return stepAdvanced(_that);case RegisterStepBack():
return stepBack(_that);case RegisterSubmitted():
return submitted(_that);case RegisterAccountOpened():
return accountOpened(_that);case RegisterBiometricNoticeShown():
return biometricNoticeShown(_that);case RegisterBiometricChecked():
return biometricChecked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RegisterFieldChanged value)?  fieldChanged,TResult? Function( RegisterCaptured value)?  captured,TResult? Function( RegisterCaptureFailed value)?  captureFailed,TResult? Function( RegisterFaceScanStarted value)?  faceScanStarted,TResult? Function( RegisterFaceScanCompleted value)?  faceScanCompleted,TResult? Function( RegisterPinDigitPressed value)?  pinDigitPressed,TResult? Function( RegisterPinBackspace value)?  pinBackspace,TResult? Function( RegisterBiometricToggled value)?  biometricToggled,TResult? Function( RegisterStepAdvanced value)?  stepAdvanced,TResult? Function( RegisterStepBack value)?  stepBack,TResult? Function( RegisterSubmitted value)?  submitted,TResult? Function( RegisterAccountOpened value)?  accountOpened,TResult? Function( RegisterBiometricNoticeShown value)?  biometricNoticeShown,TResult? Function( RegisterBiometricChecked value)?  biometricChecked,}){
final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that);case RegisterCaptured() when captured != null:
return captured(_that);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted(_that);case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted(_that);case RegisterPinDigitPressed() when pinDigitPressed != null:
return pinDigitPressed(_that);case RegisterPinBackspace() when pinBackspace != null:
return pinBackspace(_that);case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that);case RegisterStepBack() when stepBack != null:
return stepBack(_that);case RegisterSubmitted() when submitted != null:
return submitted(_that);case RegisterAccountOpened() when accountOpened != null:
return accountOpened(_that);case RegisterBiometricNoticeShown() when biometricNoticeShown != null:
return biometricNoticeShown(_that);case RegisterBiometricChecked() when biometricChecked != null:
return biometricChecked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( RegisterField field,  String value)?  fieldChanged,TResult Function( DocSide side,  Uint8List image)?  captured,TResult Function( DocSide side)?  captureFailed,TResult Function()?  faceScanStarted,TResult Function( String? kycTicket)?  faceScanCompleted,TResult Function( int digit)?  pinDigitPressed,TResult Function()?  pinBackspace,TResult Function( bool value)?  biometricToggled,TResult Function()?  stepAdvanced,TResult Function()?  stepBack,TResult Function()?  submitted,TResult Function( String biometricReason)?  accountOpened,TResult Function()?  biometricNoticeShown,TResult Function()?  biometricChecked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that.field,_that.value);case RegisterCaptured() when captured != null:
return captured(_that.side,_that.image);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that.side);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted();case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted(_that.kycTicket);case RegisterPinDigitPressed() when pinDigitPressed != null:
return pinDigitPressed(_that.digit);case RegisterPinBackspace() when pinBackspace != null:
return pinBackspace();case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that.value);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced();case RegisterStepBack() when stepBack != null:
return stepBack();case RegisterSubmitted() when submitted != null:
return submitted();case RegisterAccountOpened() when accountOpened != null:
return accountOpened(_that.biometricReason);case RegisterBiometricNoticeShown() when biometricNoticeShown != null:
return biometricNoticeShown();case RegisterBiometricChecked() when biometricChecked != null:
return biometricChecked();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( RegisterField field,  String value)  fieldChanged,required TResult Function( DocSide side,  Uint8List image)  captured,required TResult Function( DocSide side)  captureFailed,required TResult Function()  faceScanStarted,required TResult Function( String? kycTicket)  faceScanCompleted,required TResult Function( int digit)  pinDigitPressed,required TResult Function()  pinBackspace,required TResult Function( bool value)  biometricToggled,required TResult Function()  stepAdvanced,required TResult Function()  stepBack,required TResult Function()  submitted,required TResult Function( String biometricReason)  accountOpened,required TResult Function()  biometricNoticeShown,required TResult Function()  biometricChecked,}) {final _that = this;
switch (_that) {
case RegisterFieldChanged():
return fieldChanged(_that.field,_that.value);case RegisterCaptured():
return captured(_that.side,_that.image);case RegisterCaptureFailed():
return captureFailed(_that.side);case RegisterFaceScanStarted():
return faceScanStarted();case RegisterFaceScanCompleted():
return faceScanCompleted(_that.kycTicket);case RegisterPinDigitPressed():
return pinDigitPressed(_that.digit);case RegisterPinBackspace():
return pinBackspace();case RegisterBiometricToggled():
return biometricToggled(_that.value);case RegisterStepAdvanced():
return stepAdvanced();case RegisterStepBack():
return stepBack();case RegisterSubmitted():
return submitted();case RegisterAccountOpened():
return accountOpened(_that.biometricReason);case RegisterBiometricNoticeShown():
return biometricNoticeShown();case RegisterBiometricChecked():
return biometricChecked();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( RegisterField field,  String value)?  fieldChanged,TResult? Function( DocSide side,  Uint8List image)?  captured,TResult? Function( DocSide side)?  captureFailed,TResult? Function()?  faceScanStarted,TResult? Function( String? kycTicket)?  faceScanCompleted,TResult? Function( int digit)?  pinDigitPressed,TResult? Function()?  pinBackspace,TResult? Function( bool value)?  biometricToggled,TResult? Function()?  stepAdvanced,TResult? Function()?  stepBack,TResult? Function()?  submitted,TResult? Function( String biometricReason)?  accountOpened,TResult? Function()?  biometricNoticeShown,TResult? Function()?  biometricChecked,}) {final _that = this;
switch (_that) {
case RegisterFieldChanged() when fieldChanged != null:
return fieldChanged(_that.field,_that.value);case RegisterCaptured() when captured != null:
return captured(_that.side,_that.image);case RegisterCaptureFailed() when captureFailed != null:
return captureFailed(_that.side);case RegisterFaceScanStarted() when faceScanStarted != null:
return faceScanStarted();case RegisterFaceScanCompleted() when faceScanCompleted != null:
return faceScanCompleted(_that.kycTicket);case RegisterPinDigitPressed() when pinDigitPressed != null:
return pinDigitPressed(_that.digit);case RegisterPinBackspace() when pinBackspace != null:
return pinBackspace();case RegisterBiometricToggled() when biometricToggled != null:
return biometricToggled(_that.value);case RegisterStepAdvanced() when stepAdvanced != null:
return stepAdvanced();case RegisterStepBack() when stepBack != null:
return stepBack();case RegisterSubmitted() when submitted != null:
return submitted();case RegisterAccountOpened() when accountOpened != null:
return accountOpened(_that.biometricReason);case RegisterBiometricNoticeShown() when biometricNoticeShown != null:
return biometricNoticeShown();case RegisterBiometricChecked() when biometricChecked != null:
return biometricChecked();case _:
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
  const RegisterCaptured(this.side, this.image);
  

 final  DocSide side;
 final  Uint8List image;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterCapturedCopyWith<RegisterCaptured> get copyWith => _$RegisterCapturedCopyWithImpl<RegisterCaptured>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterCaptured&&(identical(other.side, side) || other.side == side)&&const DeepCollectionEquality().equals(other.image, image));
}


@override
int get hashCode => Object.hash(runtimeType,side,const DeepCollectionEquality().hash(image));

@override
String toString() {
  return 'RegisterEvent.captured(side: $side, image: $image)';
}


}

/// @nodoc
abstract mixin class $RegisterCapturedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterCapturedCopyWith(RegisterCaptured value, $Res Function(RegisterCaptured) _then) = _$RegisterCapturedCopyWithImpl;
@useResult
$Res call({
 DocSide side, Uint8List image
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
@pragma('vm:prefer-inline') $Res call({Object? side = null,Object? image = null,}) {
  return _then(RegisterCaptured(
null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as DocSide,null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as Uint8List,
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
  const RegisterFaceScanCompleted({this.kycTicket});
  

 final  String? kycTicket;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterFaceScanCompletedCopyWith<RegisterFaceScanCompleted> get copyWith => _$RegisterFaceScanCompletedCopyWithImpl<RegisterFaceScanCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterFaceScanCompleted&&(identical(other.kycTicket, kycTicket) || other.kycTicket == kycTicket));
}


@override
int get hashCode => Object.hash(runtimeType,kycTicket);

@override
String toString() {
  return 'RegisterEvent.faceScanCompleted(kycTicket: $kycTicket)';
}


}

/// @nodoc
abstract mixin class $RegisterFaceScanCompletedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterFaceScanCompletedCopyWith(RegisterFaceScanCompleted value, $Res Function(RegisterFaceScanCompleted) _then) = _$RegisterFaceScanCompletedCopyWithImpl;
@useResult
$Res call({
 String? kycTicket
});




}
/// @nodoc
class _$RegisterFaceScanCompletedCopyWithImpl<$Res>
    implements $RegisterFaceScanCompletedCopyWith<$Res> {
  _$RegisterFaceScanCompletedCopyWithImpl(this._self, this._then);

  final RegisterFaceScanCompleted _self;
  final $Res Function(RegisterFaceScanCompleted) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kycTicket = freezed,}) {
  return _then(RegisterFaceScanCompleted(
kycTicket: freezed == kycTicket ? _self.kycTicket : kycTicket // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class RegisterPinDigitPressed implements RegisterEvent {
  const RegisterPinDigitPressed(this.digit);
  

 final  int digit;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterPinDigitPressedCopyWith<RegisterPinDigitPressed> get copyWith => _$RegisterPinDigitPressedCopyWithImpl<RegisterPinDigitPressed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterPinDigitPressed&&(identical(other.digit, digit) || other.digit == digit));
}


@override
int get hashCode => Object.hash(runtimeType,digit);

@override
String toString() {
  return 'RegisterEvent.pinDigitPressed(digit: $digit)';
}


}

/// @nodoc
abstract mixin class $RegisterPinDigitPressedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterPinDigitPressedCopyWith(RegisterPinDigitPressed value, $Res Function(RegisterPinDigitPressed) _then) = _$RegisterPinDigitPressedCopyWithImpl;
@useResult
$Res call({
 int digit
});




}
/// @nodoc
class _$RegisterPinDigitPressedCopyWithImpl<$Res>
    implements $RegisterPinDigitPressedCopyWith<$Res> {
  _$RegisterPinDigitPressedCopyWithImpl(this._self, this._then);

  final RegisterPinDigitPressed _self;
  final $Res Function(RegisterPinDigitPressed) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? digit = null,}) {
  return _then(RegisterPinDigitPressed(
null == digit ? _self.digit : digit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RegisterPinBackspace implements RegisterEvent {
  const RegisterPinBackspace();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterPinBackspace);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.pinBackspace()';
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


class RegisterAccountOpened implements RegisterEvent {
  const RegisterAccountOpened({required this.biometricReason});
  

 final  String biometricReason;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterAccountOpenedCopyWith<RegisterAccountOpened> get copyWith => _$RegisterAccountOpenedCopyWithImpl<RegisterAccountOpened>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterAccountOpened&&(identical(other.biometricReason, biometricReason) || other.biometricReason == biometricReason));
}


@override
int get hashCode => Object.hash(runtimeType,biometricReason);

@override
String toString() {
  return 'RegisterEvent.accountOpened(biometricReason: $biometricReason)';
}


}

/// @nodoc
abstract mixin class $RegisterAccountOpenedCopyWith<$Res> implements $RegisterEventCopyWith<$Res> {
  factory $RegisterAccountOpenedCopyWith(RegisterAccountOpened value, $Res Function(RegisterAccountOpened) _then) = _$RegisterAccountOpenedCopyWithImpl;
@useResult
$Res call({
 String biometricReason
});




}
/// @nodoc
class _$RegisterAccountOpenedCopyWithImpl<$Res>
    implements $RegisterAccountOpenedCopyWith<$Res> {
  _$RegisterAccountOpenedCopyWithImpl(this._self, this._then);

  final RegisterAccountOpened _self;
  final $Res Function(RegisterAccountOpened) _then;

/// Create a copy of RegisterEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? biometricReason = null,}) {
  return _then(RegisterAccountOpened(
biometricReason: null == biometricReason ? _self.biometricReason : biometricReason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RegisterBiometricNoticeShown implements RegisterEvent {
  const RegisterBiometricNoticeShown();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterBiometricNoticeShown);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.biometricNoticeShown()';
}


}




/// @nodoc


class RegisterBiometricChecked implements RegisterEvent {
  const RegisterBiometricChecked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterBiometricChecked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegisterEvent.biometricChecked()';
}


}




/// @nodoc
mixin _$RegisterDraft {

 String get dni; String get nombres; String get apellidos; String get email; CaptureStatus get dniFront; CaptureStatus get dniBack;/// Bytes de las capturas. Viven en memoria hasta la verificación y se
/// sueltan ahí: son datos de identidad, no van a disco.
 Uint8List? get dniFrontImage; Uint8List? get dniBackImage;/// Por qué no sirve cada foto (null si sirve o no se revisó).
 DocumentIssue? get dniFrontIssue; DocumentIssue? get dniBackIssue;/// DNI contra el que se cotejó el reverso: si el usuario lo cambia
/// después, hay que volver a cotejar.
 String? get backCheckedDni;/// Ticket del KYC aprobado: `/register` lo exige al servidor. Vence pronto
/// y es de un solo uso, así que no se guarda fuera de este borrador.
 String? get kycTicket; FaceScanStatus get faceStatus; String get pin;/// Segunda escritura del PIN. Sin ella, un error de tecleo deja al usuario
/// fuera de la cuenta que acaba de abrir.
 String get confirmPin; bool get biometricEnabled;
/// Create a copy of RegisterDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterDraftCopyWith<RegisterDraft> get copyWith => _$RegisterDraftCopyWithImpl<RegisterDraft>(this as RegisterDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterDraft&&(identical(other.dni, dni) || other.dni == dni)&&(identical(other.nombres, nombres) || other.nombres == nombres)&&(identical(other.apellidos, apellidos) || other.apellidos == apellidos)&&(identical(other.email, email) || other.email == email)&&(identical(other.dniFront, dniFront) || other.dniFront == dniFront)&&(identical(other.dniBack, dniBack) || other.dniBack == dniBack)&&const DeepCollectionEquality().equals(other.dniFrontImage, dniFrontImage)&&const DeepCollectionEquality().equals(other.dniBackImage, dniBackImage)&&(identical(other.dniFrontIssue, dniFrontIssue) || other.dniFrontIssue == dniFrontIssue)&&(identical(other.dniBackIssue, dniBackIssue) || other.dniBackIssue == dniBackIssue)&&(identical(other.backCheckedDni, backCheckedDni) || other.backCheckedDni == backCheckedDni)&&(identical(other.kycTicket, kycTicket) || other.kycTicket == kycTicket)&&(identical(other.faceStatus, faceStatus) || other.faceStatus == faceStatus)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.confirmPin, confirmPin) || other.confirmPin == confirmPin)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,dni,nombres,apellidos,email,dniFront,dniBack,const DeepCollectionEquality().hash(dniFrontImage),const DeepCollectionEquality().hash(dniBackImage),dniFrontIssue,dniBackIssue,backCheckedDni,kycTicket,faceStatus,pin,confirmPin,biometricEnabled);

@override
String toString() {
  return 'RegisterDraft(dni: $dni, nombres: $nombres, apellidos: $apellidos, email: $email, dniFront: $dniFront, dniBack: $dniBack, dniFrontImage: $dniFrontImage, dniBackImage: $dniBackImage, dniFrontIssue: $dniFrontIssue, dniBackIssue: $dniBackIssue, backCheckedDni: $backCheckedDni, kycTicket: $kycTicket, faceStatus: $faceStatus, pin: $pin, confirmPin: $confirmPin, biometricEnabled: $biometricEnabled)';
}


}

/// @nodoc
abstract mixin class $RegisterDraftCopyWith<$Res>  {
  factory $RegisterDraftCopyWith(RegisterDraft value, $Res Function(RegisterDraft) _then) = _$RegisterDraftCopyWithImpl;
@useResult
$Res call({
 String dni, String nombres, String apellidos, String email, CaptureStatus dniFront, CaptureStatus dniBack, Uint8List? dniFrontImage, Uint8List? dniBackImage, DocumentIssue? dniFrontIssue, DocumentIssue? dniBackIssue, String? backCheckedDni, String? kycTicket, FaceScanStatus faceStatus, String pin, String confirmPin, bool biometricEnabled
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
@pragma('vm:prefer-inline') @override $Res call({Object? dni = null,Object? nombres = null,Object? apellidos = null,Object? email = null,Object? dniFront = null,Object? dniBack = null,Object? dniFrontImage = freezed,Object? dniBackImage = freezed,Object? dniFrontIssue = freezed,Object? dniBackIssue = freezed,Object? backCheckedDni = freezed,Object? kycTicket = freezed,Object? faceStatus = null,Object? pin = null,Object? confirmPin = null,Object? biometricEnabled = null,}) {
  return _then(_self.copyWith(
dni: null == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as String,nombres: null == nombres ? _self.nombres : nombres // ignore: cast_nullable_to_non_nullable
as String,apellidos: null == apellidos ? _self.apellidos : apellidos // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,dniFront: null == dniFront ? _self.dniFront : dniFront // ignore: cast_nullable_to_non_nullable
as CaptureStatus,dniBack: null == dniBack ? _self.dniBack : dniBack // ignore: cast_nullable_to_non_nullable
as CaptureStatus,dniFrontImage: freezed == dniFrontImage ? _self.dniFrontImage : dniFrontImage // ignore: cast_nullable_to_non_nullable
as Uint8List?,dniBackImage: freezed == dniBackImage ? _self.dniBackImage : dniBackImage // ignore: cast_nullable_to_non_nullable
as Uint8List?,dniFrontIssue: freezed == dniFrontIssue ? _self.dniFrontIssue : dniFrontIssue // ignore: cast_nullable_to_non_nullable
as DocumentIssue?,dniBackIssue: freezed == dniBackIssue ? _self.dniBackIssue : dniBackIssue // ignore: cast_nullable_to_non_nullable
as DocumentIssue?,backCheckedDni: freezed == backCheckedDni ? _self.backCheckedDni : backCheckedDni // ignore: cast_nullable_to_non_nullable
as String?,kycTicket: freezed == kycTicket ? _self.kycTicket : kycTicket // ignore: cast_nullable_to_non_nullable
as String?,faceStatus: null == faceStatus ? _self.faceStatus : faceStatus // ignore: cast_nullable_to_non_nullable
as FaceScanStatus,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,confirmPin: null == confirmPin ? _self.confirmPin : confirmPin // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dni,  String nombres,  String apellidos,  String email,  CaptureStatus dniFront,  CaptureStatus dniBack,  Uint8List? dniFrontImage,  Uint8List? dniBackImage,  DocumentIssue? dniFrontIssue,  DocumentIssue? dniBackIssue,  String? backCheckedDni,  String? kycTicket,  FaceScanStatus faceStatus,  String pin,  String confirmPin,  bool biometricEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterDraft() when $default != null:
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.dniFront,_that.dniBack,_that.dniFrontImage,_that.dniBackImage,_that.dniFrontIssue,_that.dniBackIssue,_that.backCheckedDni,_that.kycTicket,_that.faceStatus,_that.pin,_that.confirmPin,_that.biometricEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dni,  String nombres,  String apellidos,  String email,  CaptureStatus dniFront,  CaptureStatus dniBack,  Uint8List? dniFrontImage,  Uint8List? dniBackImage,  DocumentIssue? dniFrontIssue,  DocumentIssue? dniBackIssue,  String? backCheckedDni,  String? kycTicket,  FaceScanStatus faceStatus,  String pin,  String confirmPin,  bool biometricEnabled)  $default,) {final _that = this;
switch (_that) {
case _RegisterDraft():
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.dniFront,_that.dniBack,_that.dniFrontImage,_that.dniBackImage,_that.dniFrontIssue,_that.dniBackIssue,_that.backCheckedDni,_that.kycTicket,_that.faceStatus,_that.pin,_that.confirmPin,_that.biometricEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dni,  String nombres,  String apellidos,  String email,  CaptureStatus dniFront,  CaptureStatus dniBack,  Uint8List? dniFrontImage,  Uint8List? dniBackImage,  DocumentIssue? dniFrontIssue,  DocumentIssue? dniBackIssue,  String? backCheckedDni,  String? kycTicket,  FaceScanStatus faceStatus,  String pin,  String confirmPin,  bool biometricEnabled)?  $default,) {final _that = this;
switch (_that) {
case _RegisterDraft() when $default != null:
return $default(_that.dni,_that.nombres,_that.apellidos,_that.email,_that.dniFront,_that.dniBack,_that.dniFrontImage,_that.dniBackImage,_that.dniFrontIssue,_that.dniBackIssue,_that.backCheckedDni,_that.kycTicket,_that.faceStatus,_that.pin,_that.confirmPin,_that.biometricEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _RegisterDraft implements RegisterDraft {
  const _RegisterDraft({this.dni = '', this.nombres = '', this.apellidos = '', this.email = '', this.dniFront = CaptureStatus.empty, this.dniBack = CaptureStatus.empty, this.dniFrontImage, this.dniBackImage, this.dniFrontIssue, this.dniBackIssue, this.backCheckedDni, this.kycTicket, this.faceStatus = FaceScanStatus.idle, this.pin = '', this.confirmPin = '', this.biometricEnabled = true});
  

@override@JsonKey() final  String dni;
@override@JsonKey() final  String nombres;
@override@JsonKey() final  String apellidos;
@override@JsonKey() final  String email;
@override@JsonKey() final  CaptureStatus dniFront;
@override@JsonKey() final  CaptureStatus dniBack;
/// Bytes de las capturas. Viven en memoria hasta la verificación y se
/// sueltan ahí: son datos de identidad, no van a disco.
@override final  Uint8List? dniFrontImage;
@override final  Uint8List? dniBackImage;
/// Por qué no sirve cada foto (null si sirve o no se revisó).
@override final  DocumentIssue? dniFrontIssue;
@override final  DocumentIssue? dniBackIssue;
/// DNI contra el que se cotejó el reverso: si el usuario lo cambia
/// después, hay que volver a cotejar.
@override final  String? backCheckedDni;
/// Ticket del KYC aprobado: `/register` lo exige al servidor. Vence pronto
/// y es de un solo uso, así que no se guarda fuera de este borrador.
@override final  String? kycTicket;
@override@JsonKey() final  FaceScanStatus faceStatus;
@override@JsonKey() final  String pin;
/// Segunda escritura del PIN. Sin ella, un error de tecleo deja al usuario
/// fuera de la cuenta que acaba de abrir.
@override@JsonKey() final  String confirmPin;
@override@JsonKey() final  bool biometricEnabled;

/// Create a copy of RegisterDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterDraftCopyWith<_RegisterDraft> get copyWith => __$RegisterDraftCopyWithImpl<_RegisterDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterDraft&&(identical(other.dni, dni) || other.dni == dni)&&(identical(other.nombres, nombres) || other.nombres == nombres)&&(identical(other.apellidos, apellidos) || other.apellidos == apellidos)&&(identical(other.email, email) || other.email == email)&&(identical(other.dniFront, dniFront) || other.dniFront == dniFront)&&(identical(other.dniBack, dniBack) || other.dniBack == dniBack)&&const DeepCollectionEquality().equals(other.dniFrontImage, dniFrontImage)&&const DeepCollectionEquality().equals(other.dniBackImage, dniBackImage)&&(identical(other.dniFrontIssue, dniFrontIssue) || other.dniFrontIssue == dniFrontIssue)&&(identical(other.dniBackIssue, dniBackIssue) || other.dniBackIssue == dniBackIssue)&&(identical(other.backCheckedDni, backCheckedDni) || other.backCheckedDni == backCheckedDni)&&(identical(other.kycTicket, kycTicket) || other.kycTicket == kycTicket)&&(identical(other.faceStatus, faceStatus) || other.faceStatus == faceStatus)&&(identical(other.pin, pin) || other.pin == pin)&&(identical(other.confirmPin, confirmPin) || other.confirmPin == confirmPin)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,dni,nombres,apellidos,email,dniFront,dniBack,const DeepCollectionEquality().hash(dniFrontImage),const DeepCollectionEquality().hash(dniBackImage),dniFrontIssue,dniBackIssue,backCheckedDni,kycTicket,faceStatus,pin,confirmPin,biometricEnabled);

@override
String toString() {
  return 'RegisterDraft(dni: $dni, nombres: $nombres, apellidos: $apellidos, email: $email, dniFront: $dniFront, dniBack: $dniBack, dniFrontImage: $dniFrontImage, dniBackImage: $dniBackImage, dniFrontIssue: $dniFrontIssue, dniBackIssue: $dniBackIssue, backCheckedDni: $backCheckedDni, kycTicket: $kycTicket, faceStatus: $faceStatus, pin: $pin, confirmPin: $confirmPin, biometricEnabled: $biometricEnabled)';
}


}

/// @nodoc
abstract mixin class _$RegisterDraftCopyWith<$Res> implements $RegisterDraftCopyWith<$Res> {
  factory _$RegisterDraftCopyWith(_RegisterDraft value, $Res Function(_RegisterDraft) _then) = __$RegisterDraftCopyWithImpl;
@override @useResult
$Res call({
 String dni, String nombres, String apellidos, String email, CaptureStatus dniFront, CaptureStatus dniBack, Uint8List? dniFrontImage, Uint8List? dniBackImage, DocumentIssue? dniFrontIssue, DocumentIssue? dniBackIssue, String? backCheckedDni, String? kycTicket, FaceScanStatus faceStatus, String pin, String confirmPin, bool biometricEnabled
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
@override @pragma('vm:prefer-inline') $Res call({Object? dni = null,Object? nombres = null,Object? apellidos = null,Object? email = null,Object? dniFront = null,Object? dniBack = null,Object? dniFrontImage = freezed,Object? dniBackImage = freezed,Object? dniFrontIssue = freezed,Object? dniBackIssue = freezed,Object? backCheckedDni = freezed,Object? kycTicket = freezed,Object? faceStatus = null,Object? pin = null,Object? confirmPin = null,Object? biometricEnabled = null,}) {
  return _then(_RegisterDraft(
dni: null == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as String,nombres: null == nombres ? _self.nombres : nombres // ignore: cast_nullable_to_non_nullable
as String,apellidos: null == apellidos ? _self.apellidos : apellidos // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,dniFront: null == dniFront ? _self.dniFront : dniFront // ignore: cast_nullable_to_non_nullable
as CaptureStatus,dniBack: null == dniBack ? _self.dniBack : dniBack // ignore: cast_nullable_to_non_nullable
as CaptureStatus,dniFrontImage: freezed == dniFrontImage ? _self.dniFrontImage : dniFrontImage // ignore: cast_nullable_to_non_nullable
as Uint8List?,dniBackImage: freezed == dniBackImage ? _self.dniBackImage : dniBackImage // ignore: cast_nullable_to_non_nullable
as Uint8List?,dniFrontIssue: freezed == dniFrontIssue ? _self.dniFrontIssue : dniFrontIssue // ignore: cast_nullable_to_non_nullable
as DocumentIssue?,dniBackIssue: freezed == dniBackIssue ? _self.dniBackIssue : dniBackIssue // ignore: cast_nullable_to_non_nullable
as DocumentIssue?,backCheckedDni: freezed == backCheckedDni ? _self.backCheckedDni : backCheckedDni // ignore: cast_nullable_to_non_nullable
as String?,kycTicket: freezed == kycTicket ? _self.kycTicket : kycTicket // ignore: cast_nullable_to_non_nullable
as String?,faceStatus: null == faceStatus ? _self.faceStatus : faceStatus // ignore: cast_nullable_to_non_nullable
as FaceScanStatus,pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,confirmPin: null == confirmPin ? _self.confirmPin : confirmPin // ignore: cast_nullable_to_non_nullable
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

 int get step; SecurityStep get securityStep; bool get pinMismatch; RegisterDraft get draft; RegisterErrors get errors; RegisterStatus get status; AuthError? get submitError;// Cuenta creada tras un registro exitoso (aún NO autenticada): dispara la
// pantalla de éxito. Se activa con `RegisterEvent.accountOpened`.
 AuthSession? get createdSession;// ¿El teléfono tiene sensor? Sin él, el paso 4C no ofrece la huella.
 bool get biometricAvailable;// La huella no pudo activarse tras el alta. No deshace la cuenta.
 bool get biometricEnrollFailed;
/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterStateCopyWith<RegisterState> get copyWith => _$RegisterStateCopyWithImpl<RegisterState>(this as RegisterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterState&&(identical(other.step, step) || other.step == step)&&(identical(other.securityStep, securityStep) || other.securityStep == securityStep)&&(identical(other.pinMismatch, pinMismatch) || other.pinMismatch == pinMismatch)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.errors, errors) || other.errors == errors)&&(identical(other.status, status) || other.status == status)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.createdSession, createdSession) || other.createdSession == createdSession)&&(identical(other.biometricAvailable, biometricAvailable) || other.biometricAvailable == biometricAvailable)&&(identical(other.biometricEnrollFailed, biometricEnrollFailed) || other.biometricEnrollFailed == biometricEnrollFailed));
}


@override
int get hashCode => Object.hash(runtimeType,step,securityStep,pinMismatch,draft,errors,status,submitError,createdSession,biometricAvailable,biometricEnrollFailed);

@override
String toString() {
  return 'RegisterState(step: $step, securityStep: $securityStep, pinMismatch: $pinMismatch, draft: $draft, errors: $errors, status: $status, submitError: $submitError, createdSession: $createdSession, biometricAvailable: $biometricAvailable, biometricEnrollFailed: $biometricEnrollFailed)';
}


}

/// @nodoc
abstract mixin class $RegisterStateCopyWith<$Res>  {
  factory $RegisterStateCopyWith(RegisterState value, $Res Function(RegisterState) _then) = _$RegisterStateCopyWithImpl;
@useResult
$Res call({
 int step, SecurityStep securityStep, bool pinMismatch, RegisterDraft draft, RegisterErrors errors, RegisterStatus status, AuthError? submitError, AuthSession? createdSession, bool biometricAvailable, bool biometricEnrollFailed
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
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? securityStep = null,Object? pinMismatch = null,Object? draft = null,Object? errors = null,Object? status = null,Object? submitError = freezed,Object? createdSession = freezed,Object? biometricAvailable = null,Object? biometricEnrollFailed = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,securityStep: null == securityStep ? _self.securityStep : securityStep // ignore: cast_nullable_to_non_nullable
as SecurityStep,pinMismatch: null == pinMismatch ? _self.pinMismatch : pinMismatch // ignore: cast_nullable_to_non_nullable
as bool,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as RegisterDraft,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as RegisterErrors,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegisterStatus,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as AuthError?,createdSession: freezed == createdSession ? _self.createdSession : createdSession // ignore: cast_nullable_to_non_nullable
as AuthSession?,biometricAvailable: null == biometricAvailable ? _self.biometricAvailable : biometricAvailable // ignore: cast_nullable_to_non_nullable
as bool,biometricEnrollFailed: null == biometricEnrollFailed ? _self.biometricEnrollFailed : biometricEnrollFailed // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int step,  SecurityStep securityStep,  bool pinMismatch,  RegisterDraft draft,  RegisterErrors errors,  RegisterStatus status,  AuthError? submitError,  AuthSession? createdSession,  bool biometricAvailable,  bool biometricEnrollFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterState() when $default != null:
return $default(_that.step,_that.securityStep,_that.pinMismatch,_that.draft,_that.errors,_that.status,_that.submitError,_that.createdSession,_that.biometricAvailable,_that.biometricEnrollFailed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int step,  SecurityStep securityStep,  bool pinMismatch,  RegisterDraft draft,  RegisterErrors errors,  RegisterStatus status,  AuthError? submitError,  AuthSession? createdSession,  bool biometricAvailable,  bool biometricEnrollFailed)  $default,) {final _that = this;
switch (_that) {
case _RegisterState():
return $default(_that.step,_that.securityStep,_that.pinMismatch,_that.draft,_that.errors,_that.status,_that.submitError,_that.createdSession,_that.biometricAvailable,_that.biometricEnrollFailed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int step,  SecurityStep securityStep,  bool pinMismatch,  RegisterDraft draft,  RegisterErrors errors,  RegisterStatus status,  AuthError? submitError,  AuthSession? createdSession,  bool biometricAvailable,  bool biometricEnrollFailed)?  $default,) {final _that = this;
switch (_that) {
case _RegisterState() when $default != null:
return $default(_that.step,_that.securityStep,_that.pinMismatch,_that.draft,_that.errors,_that.status,_that.submitError,_that.createdSession,_that.biometricAvailable,_that.biometricEnrollFailed);case _:
  return null;

}
}

}

/// @nodoc


class _RegisterState extends RegisterState {
  const _RegisterState({this.step = 0, this.securityStep = SecurityStep.crear, this.pinMismatch = false, this.draft = const RegisterDraft(), this.errors = const RegisterErrors(), this.status = RegisterStatus.editing, this.submitError, this.createdSession, this.biometricAvailable = false, this.biometricEnrollFailed = false}): super._();
  

@override@JsonKey() final  int step;
@override@JsonKey() final  SecurityStep securityStep;
@override@JsonKey() final  bool pinMismatch;
@override@JsonKey() final  RegisterDraft draft;
@override@JsonKey() final  RegisterErrors errors;
@override@JsonKey() final  RegisterStatus status;
@override final  AuthError? submitError;
// Cuenta creada tras un registro exitoso (aún NO autenticada): dispara la
// pantalla de éxito. Se activa con `RegisterEvent.accountOpened`.
@override final  AuthSession? createdSession;
// ¿El teléfono tiene sensor? Sin él, el paso 4C no ofrece la huella.
@override@JsonKey() final  bool biometricAvailable;
// La huella no pudo activarse tras el alta. No deshace la cuenta.
@override@JsonKey() final  bool biometricEnrollFailed;

/// Create a copy of RegisterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterStateCopyWith<_RegisterState> get copyWith => __$RegisterStateCopyWithImpl<_RegisterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterState&&(identical(other.step, step) || other.step == step)&&(identical(other.securityStep, securityStep) || other.securityStep == securityStep)&&(identical(other.pinMismatch, pinMismatch) || other.pinMismatch == pinMismatch)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.errors, errors) || other.errors == errors)&&(identical(other.status, status) || other.status == status)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.createdSession, createdSession) || other.createdSession == createdSession)&&(identical(other.biometricAvailable, biometricAvailable) || other.biometricAvailable == biometricAvailable)&&(identical(other.biometricEnrollFailed, biometricEnrollFailed) || other.biometricEnrollFailed == biometricEnrollFailed));
}


@override
int get hashCode => Object.hash(runtimeType,step,securityStep,pinMismatch,draft,errors,status,submitError,createdSession,biometricAvailable,biometricEnrollFailed);

@override
String toString() {
  return 'RegisterState(step: $step, securityStep: $securityStep, pinMismatch: $pinMismatch, draft: $draft, errors: $errors, status: $status, submitError: $submitError, createdSession: $createdSession, biometricAvailable: $biometricAvailable, biometricEnrollFailed: $biometricEnrollFailed)';
}


}

/// @nodoc
abstract mixin class _$RegisterStateCopyWith<$Res> implements $RegisterStateCopyWith<$Res> {
  factory _$RegisterStateCopyWith(_RegisterState value, $Res Function(_RegisterState) _then) = __$RegisterStateCopyWithImpl;
@override @useResult
$Res call({
 int step, SecurityStep securityStep, bool pinMismatch, RegisterDraft draft, RegisterErrors errors, RegisterStatus status, AuthError? submitError, AuthSession? createdSession, bool biometricAvailable, bool biometricEnrollFailed
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
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? securityStep = null,Object? pinMismatch = null,Object? draft = null,Object? errors = null,Object? status = null,Object? submitError = freezed,Object? createdSession = freezed,Object? biometricAvailable = null,Object? biometricEnrollFailed = null,}) {
  return _then(_RegisterState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,securityStep: null == securityStep ? _self.securityStep : securityStep // ignore: cast_nullable_to_non_nullable
as SecurityStep,pinMismatch: null == pinMismatch ? _self.pinMismatch : pinMismatch // ignore: cast_nullable_to_non_nullable
as bool,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as RegisterDraft,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as RegisterErrors,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegisterStatus,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as AuthError?,createdSession: freezed == createdSession ? _self.createdSession : createdSession // ignore: cast_nullable_to_non_nullable
as AuthSession?,biometricAvailable: null == biometricAvailable ? _self.biometricAvailable : biometricAvailable // ignore: cast_nullable_to_non_nullable
as bool,biometricEnrollFailed: null == biometricEnrollFailed ? _self.biometricEnrollFailed : biometricEnrollFailed // ignore: cast_nullable_to_non_nullable
as bool,
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
