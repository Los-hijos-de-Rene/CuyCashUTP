// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'linked_devices_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LinkedDevicesEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedDevicesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LinkedDevicesEvent()';
}


}

/// @nodoc
class $LinkedDevicesEventCopyWith<$Res>  {
$LinkedDevicesEventCopyWith(LinkedDevicesEvent _, $Res Function(LinkedDevicesEvent) __);
}


/// Adds pattern-matching-related methods to [LinkedDevicesEvent].
extension LinkedDevicesEventPatterns on LinkedDevicesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LinkedDevicesStarted value)?  started,TResult Function( LinkedDevicesUnlinkRequested value)?  unlinkRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LinkedDevicesStarted() when started != null:
return started(_that);case LinkedDevicesUnlinkRequested() when unlinkRequested != null:
return unlinkRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LinkedDevicesStarted value)  started,required TResult Function( LinkedDevicesUnlinkRequested value)  unlinkRequested,}){
final _that = this;
switch (_that) {
case LinkedDevicesStarted():
return started(_that);case LinkedDevicesUnlinkRequested():
return unlinkRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LinkedDevicesStarted value)?  started,TResult? Function( LinkedDevicesUnlinkRequested value)?  unlinkRequested,}){
final _that = this;
switch (_that) {
case LinkedDevicesStarted() when started != null:
return started(_that);case LinkedDevicesUnlinkRequested() when unlinkRequested != null:
return unlinkRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( String id)?  unlinkRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LinkedDevicesStarted() when started != null:
return started();case LinkedDevicesUnlinkRequested() when unlinkRequested != null:
return unlinkRequested(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( String id)  unlinkRequested,}) {final _that = this;
switch (_that) {
case LinkedDevicesStarted():
return started();case LinkedDevicesUnlinkRequested():
return unlinkRequested(_that.id);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( String id)?  unlinkRequested,}) {final _that = this;
switch (_that) {
case LinkedDevicesStarted() when started != null:
return started();case LinkedDevicesUnlinkRequested() when unlinkRequested != null:
return unlinkRequested(_that.id);case _:
  return null;

}
}

}

/// @nodoc


class LinkedDevicesStarted implements LinkedDevicesEvent {
  const LinkedDevicesStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedDevicesStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LinkedDevicesEvent.started()';
}


}




/// @nodoc


class LinkedDevicesUnlinkRequested implements LinkedDevicesEvent {
  const LinkedDevicesUnlinkRequested(this.id);
  

 final  String id;

/// Create a copy of LinkedDevicesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedDevicesUnlinkRequestedCopyWith<LinkedDevicesUnlinkRequested> get copyWith => _$LinkedDevicesUnlinkRequestedCopyWithImpl<LinkedDevicesUnlinkRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedDevicesUnlinkRequested&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'LinkedDevicesEvent.unlinkRequested(id: $id)';
}


}

/// @nodoc
abstract mixin class $LinkedDevicesUnlinkRequestedCopyWith<$Res> implements $LinkedDevicesEventCopyWith<$Res> {
  factory $LinkedDevicesUnlinkRequestedCopyWith(LinkedDevicesUnlinkRequested value, $Res Function(LinkedDevicesUnlinkRequested) _then) = _$LinkedDevicesUnlinkRequestedCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$LinkedDevicesUnlinkRequestedCopyWithImpl<$Res>
    implements $LinkedDevicesUnlinkRequestedCopyWith<$Res> {
  _$LinkedDevicesUnlinkRequestedCopyWithImpl(this._self, this._then);

  final LinkedDevicesUnlinkRequested _self;
  final $Res Function(LinkedDevicesUnlinkRequested) _then;

/// Create a copy of LinkedDevicesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(LinkedDevicesUnlinkRequested(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LinkedDevicesState {

 LinkedDevicesStatus get status; List<LinkedDevice> get devices; String? get unlinking; DevicesMessage? get message;
/// Create a copy of LinkedDevicesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedDevicesStateCopyWith<LinkedDevicesState> get copyWith => _$LinkedDevicesStateCopyWithImpl<LinkedDevicesState>(this as LinkedDevicesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedDevicesState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.devices, devices)&&(identical(other.unlinking, unlinking) || other.unlinking == unlinking)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(devices),unlinking,message);

@override
String toString() {
  return 'LinkedDevicesState(status: $status, devices: $devices, unlinking: $unlinking, message: $message)';
}


}

/// @nodoc
abstract mixin class $LinkedDevicesStateCopyWith<$Res>  {
  factory $LinkedDevicesStateCopyWith(LinkedDevicesState value, $Res Function(LinkedDevicesState) _then) = _$LinkedDevicesStateCopyWithImpl;
@useResult
$Res call({
 LinkedDevicesStatus status, List<LinkedDevice> devices, String? unlinking, DevicesMessage? message
});




}
/// @nodoc
class _$LinkedDevicesStateCopyWithImpl<$Res>
    implements $LinkedDevicesStateCopyWith<$Res> {
  _$LinkedDevicesStateCopyWithImpl(this._self, this._then);

  final LinkedDevicesState _self;
  final $Res Function(LinkedDevicesState) _then;

/// Create a copy of LinkedDevicesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? devices = null,Object? unlinking = freezed,Object? message = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LinkedDevicesStatus,devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<LinkedDevice>,unlinking: freezed == unlinking ? _self.unlinking : unlinking // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as DevicesMessage?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedDevicesState].
extension LinkedDevicesStatePatterns on LinkedDevicesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedDevicesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedDevicesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedDevicesState value)  $default,){
final _that = this;
switch (_that) {
case _LinkedDevicesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedDevicesState value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedDevicesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LinkedDevicesStatus status,  List<LinkedDevice> devices,  String? unlinking,  DevicesMessage? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedDevicesState() when $default != null:
return $default(_that.status,_that.devices,_that.unlinking,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LinkedDevicesStatus status,  List<LinkedDevice> devices,  String? unlinking,  DevicesMessage? message)  $default,) {final _that = this;
switch (_that) {
case _LinkedDevicesState():
return $default(_that.status,_that.devices,_that.unlinking,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LinkedDevicesStatus status,  List<LinkedDevice> devices,  String? unlinking,  DevicesMessage? message)?  $default,) {final _that = this;
switch (_that) {
case _LinkedDevicesState() when $default != null:
return $default(_that.status,_that.devices,_that.unlinking,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _LinkedDevicesState implements LinkedDevicesState {
  const _LinkedDevicesState({this.status = LinkedDevicesStatus.loading, final  List<LinkedDevice> devices = const <LinkedDevice>[], this.unlinking, this.message}): _devices = devices;
  

@override@JsonKey() final  LinkedDevicesStatus status;
 final  List<LinkedDevice> _devices;
@override@JsonKey() List<LinkedDevice> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}

@override final  String? unlinking;
@override final  DevicesMessage? message;

/// Create a copy of LinkedDevicesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedDevicesStateCopyWith<_LinkedDevicesState> get copyWith => __$LinkedDevicesStateCopyWithImpl<_LinkedDevicesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedDevicesState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._devices, _devices)&&(identical(other.unlinking, unlinking) || other.unlinking == unlinking)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_devices),unlinking,message);

@override
String toString() {
  return 'LinkedDevicesState(status: $status, devices: $devices, unlinking: $unlinking, message: $message)';
}


}

/// @nodoc
abstract mixin class _$LinkedDevicesStateCopyWith<$Res> implements $LinkedDevicesStateCopyWith<$Res> {
  factory _$LinkedDevicesStateCopyWith(_LinkedDevicesState value, $Res Function(_LinkedDevicesState) _then) = __$LinkedDevicesStateCopyWithImpl;
@override @useResult
$Res call({
 LinkedDevicesStatus status, List<LinkedDevice> devices, String? unlinking, DevicesMessage? message
});




}
/// @nodoc
class __$LinkedDevicesStateCopyWithImpl<$Res>
    implements _$LinkedDevicesStateCopyWith<$Res> {
  __$LinkedDevicesStateCopyWithImpl(this._self, this._then);

  final _LinkedDevicesState _self;
  final $Res Function(_LinkedDevicesState) _then;

/// Create a copy of LinkedDevicesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? devices = null,Object? unlinking = freezed,Object? message = freezed,}) {
  return _then(_LinkedDevicesState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LinkedDevicesStatus,devices: null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<LinkedDevice>,unlinking: freezed == unlinking ? _self.unlinking : unlinking // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as DevicesMessage?,
  ));
}


}

// dart format on
