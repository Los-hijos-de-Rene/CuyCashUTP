// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'beneficiaries_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BeneficiariesEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BeneficiariesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BeneficiariesEvent()';
}


}

/// @nodoc
class $BeneficiariesEventCopyWith<$Res>  {
$BeneficiariesEventCopyWith(BeneficiariesEvent _, $Res Function(BeneficiariesEvent) __);
}


/// Adds pattern-matching-related methods to [BeneficiariesEvent].
extension BeneficiariesEventPatterns on BeneficiariesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BeneficiariesOpened value)?  opened,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BeneficiariesOpened() when opened != null:
return opened(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BeneficiariesOpened value)  opened,}){
final _that = this;
switch (_that) {
case BeneficiariesOpened():
return opened(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BeneficiariesOpened value)?  opened,}){
final _that = this;
switch (_that) {
case BeneficiariesOpened() when opened != null:
return opened(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  opened,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BeneficiariesOpened() when opened != null:
return opened();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  opened,}) {final _that = this;
switch (_that) {
case BeneficiariesOpened():
return opened();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  opened,}) {final _that = this;
switch (_that) {
case BeneficiariesOpened() when opened != null:
return opened();case _:
  return null;

}
}

}

/// @nodoc


class BeneficiariesOpened implements BeneficiariesEvent {
  const BeneficiariesOpened();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BeneficiariesOpened);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BeneficiariesEvent.opened()';
}


}




/// @nodoc
mixin _$BeneficiariesState {

 BeneficiariesStatus get status; List<Beneficiary> get items;
/// Create a copy of BeneficiariesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BeneficiariesStateCopyWith<BeneficiariesState> get copyWith => _$BeneficiariesStateCopyWithImpl<BeneficiariesState>(this as BeneficiariesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BeneficiariesState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'BeneficiariesState(status: $status, items: $items)';
}


}

/// @nodoc
abstract mixin class $BeneficiariesStateCopyWith<$Res>  {
  factory $BeneficiariesStateCopyWith(BeneficiariesState value, $Res Function(BeneficiariesState) _then) = _$BeneficiariesStateCopyWithImpl;
@useResult
$Res call({
 BeneficiariesStatus status, List<Beneficiary> items
});




}
/// @nodoc
class _$BeneficiariesStateCopyWithImpl<$Res>
    implements $BeneficiariesStateCopyWith<$Res> {
  _$BeneficiariesStateCopyWithImpl(this._self, this._then);

  final BeneficiariesState _self;
  final $Res Function(BeneficiariesState) _then;

/// Create a copy of BeneficiariesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? items = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BeneficiariesStatus,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Beneficiary>,
  ));
}

}


/// Adds pattern-matching-related methods to [BeneficiariesState].
extension BeneficiariesStatePatterns on BeneficiariesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BeneficiariesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BeneficiariesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BeneficiariesState value)  $default,){
final _that = this;
switch (_that) {
case _BeneficiariesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BeneficiariesState value)?  $default,){
final _that = this;
switch (_that) {
case _BeneficiariesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BeneficiariesStatus status,  List<Beneficiary> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BeneficiariesState() when $default != null:
return $default(_that.status,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BeneficiariesStatus status,  List<Beneficiary> items)  $default,) {final _that = this;
switch (_that) {
case _BeneficiariesState():
return $default(_that.status,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BeneficiariesStatus status,  List<Beneficiary> items)?  $default,) {final _that = this;
switch (_that) {
case _BeneficiariesState() when $default != null:
return $default(_that.status,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _BeneficiariesState implements BeneficiariesState {
  const _BeneficiariesState({this.status = BeneficiariesStatus.loading, final  List<Beneficiary> items = const <Beneficiary>[]}): _items = items;
  

@override@JsonKey() final  BeneficiariesStatus status;
 final  List<Beneficiary> _items;
@override@JsonKey() List<Beneficiary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BeneficiariesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BeneficiariesStateCopyWith<_BeneficiariesState> get copyWith => __$BeneficiariesStateCopyWithImpl<_BeneficiariesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BeneficiariesState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'BeneficiariesState(status: $status, items: $items)';
}


}

/// @nodoc
abstract mixin class _$BeneficiariesStateCopyWith<$Res> implements $BeneficiariesStateCopyWith<$Res> {
  factory _$BeneficiariesStateCopyWith(_BeneficiariesState value, $Res Function(_BeneficiariesState) _then) = __$BeneficiariesStateCopyWithImpl;
@override @useResult
$Res call({
 BeneficiariesStatus status, List<Beneficiary> items
});




}
/// @nodoc
class __$BeneficiariesStateCopyWithImpl<$Res>
    implements _$BeneficiariesStateCopyWith<$Res> {
  __$BeneficiariesStateCopyWithImpl(this._self, this._then);

  final _BeneficiariesState _self;
  final $Res Function(_BeneficiariesState) _then;

/// Create a copy of BeneficiariesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? items = null,}) {
  return _then(_BeneficiariesState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BeneficiariesStatus,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Beneficiary>,
  ));
}


}

// dart format on
