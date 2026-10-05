// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topup_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopUpEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopUpEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TopUpEvent()';
}


}

/// @nodoc
class $TopUpEventCopyWith<$Res>  {
$TopUpEventCopyWith(TopUpEvent _, $Res Function(TopUpEvent) __);
}


/// Adds pattern-matching-related methods to [TopUpEvent].
extension TopUpEventPatterns on TopUpEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TopUpOpened value)?  opened,TResult Function( TopUpAmountChanged value)?  amountChanged,TResult Function( TopUpSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TopUpOpened() when opened != null:
return opened(_that);case TopUpAmountChanged() when amountChanged != null:
return amountChanged(_that);case TopUpSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TopUpOpened value)  opened,required TResult Function( TopUpAmountChanged value)  amountChanged,required TResult Function( TopUpSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case TopUpOpened():
return opened(_that);case TopUpAmountChanged():
return amountChanged(_that);case TopUpSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TopUpOpened value)?  opened,TResult? Function( TopUpAmountChanged value)?  amountChanged,TResult? Function( TopUpSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case TopUpOpened() when opened != null:
return opened(_that);case TopUpAmountChanged() when amountChanged != null:
return amountChanged(_that);case TopUpSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String cuentaId)?  opened,TResult Function( Money? monto)?  amountChanged,TResult Function( String pin)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TopUpOpened() when opened != null:
return opened(_that.cuentaId);case TopUpAmountChanged() when amountChanged != null:
return amountChanged(_that.monto);case TopUpSubmitted() when submitted != null:
return submitted(_that.pin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String cuentaId)  opened,required TResult Function( Money? monto)  amountChanged,required TResult Function( String pin)  submitted,}) {final _that = this;
switch (_that) {
case TopUpOpened():
return opened(_that.cuentaId);case TopUpAmountChanged():
return amountChanged(_that.monto);case TopUpSubmitted():
return submitted(_that.pin);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String cuentaId)?  opened,TResult? Function( Money? monto)?  amountChanged,TResult? Function( String pin)?  submitted,}) {final _that = this;
switch (_that) {
case TopUpOpened() when opened != null:
return opened(_that.cuentaId);case TopUpAmountChanged() when amountChanged != null:
return amountChanged(_that.monto);case TopUpSubmitted() when submitted != null:
return submitted(_that.pin);case _:
  return null;

}
}

}

/// @nodoc


class TopUpOpened implements TopUpEvent {
  const TopUpOpened({required this.cuentaId});
  

 final  String cuentaId;

/// Create a copy of TopUpEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopUpOpenedCopyWith<TopUpOpened> get copyWith => _$TopUpOpenedCopyWithImpl<TopUpOpened>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopUpOpened&&(identical(other.cuentaId, cuentaId) || other.cuentaId == cuentaId));
}


@override
int get hashCode => Object.hash(runtimeType,cuentaId);

@override
String toString() {
  return 'TopUpEvent.opened(cuentaId: $cuentaId)';
}


}

/// @nodoc
abstract mixin class $TopUpOpenedCopyWith<$Res> implements $TopUpEventCopyWith<$Res> {
  factory $TopUpOpenedCopyWith(TopUpOpened value, $Res Function(TopUpOpened) _then) = _$TopUpOpenedCopyWithImpl;
@useResult
$Res call({
 String cuentaId
});




}
/// @nodoc
class _$TopUpOpenedCopyWithImpl<$Res>
    implements $TopUpOpenedCopyWith<$Res> {
  _$TopUpOpenedCopyWithImpl(this._self, this._then);

  final TopUpOpened _self;
  final $Res Function(TopUpOpened) _then;

/// Create a copy of TopUpEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cuentaId = null,}) {
  return _then(TopUpOpened(
cuentaId: null == cuentaId ? _self.cuentaId : cuentaId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TopUpAmountChanged implements TopUpEvent {
  const TopUpAmountChanged(this.monto);
  

 final  Money? monto;

/// Create a copy of TopUpEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopUpAmountChangedCopyWith<TopUpAmountChanged> get copyWith => _$TopUpAmountChangedCopyWithImpl<TopUpAmountChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopUpAmountChanged&&(identical(other.monto, monto) || other.monto == monto));
}


@override
int get hashCode => Object.hash(runtimeType,monto);

@override
String toString() {
  return 'TopUpEvent.amountChanged(monto: $monto)';
}


}

/// @nodoc
abstract mixin class $TopUpAmountChangedCopyWith<$Res> implements $TopUpEventCopyWith<$Res> {
  factory $TopUpAmountChangedCopyWith(TopUpAmountChanged value, $Res Function(TopUpAmountChanged) _then) = _$TopUpAmountChangedCopyWithImpl;
@useResult
$Res call({
 Money? monto
});




}
/// @nodoc
class _$TopUpAmountChangedCopyWithImpl<$Res>
    implements $TopUpAmountChangedCopyWith<$Res> {
  _$TopUpAmountChangedCopyWithImpl(this._self, this._then);

  final TopUpAmountChanged _self;
  final $Res Function(TopUpAmountChanged) _then;

/// Create a copy of TopUpEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? monto = freezed,}) {
  return _then(TopUpAmountChanged(
freezed == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as Money?,
  ));
}


}

/// @nodoc


class TopUpSubmitted implements TopUpEvent {
  const TopUpSubmitted({required this.pin});
  

 final  String pin;

/// Create a copy of TopUpEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopUpSubmittedCopyWith<TopUpSubmitted> get copyWith => _$TopUpSubmittedCopyWithImpl<TopUpSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopUpSubmitted&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,pin);

@override
String toString() {
  return 'TopUpEvent.submitted(pin: $pin)';
}


}

/// @nodoc
abstract mixin class $TopUpSubmittedCopyWith<$Res> implements $TopUpEventCopyWith<$Res> {
  factory $TopUpSubmittedCopyWith(TopUpSubmitted value, $Res Function(TopUpSubmitted) _then) = _$TopUpSubmittedCopyWithImpl;
@useResult
$Res call({
 String pin
});




}
/// @nodoc
class _$TopUpSubmittedCopyWithImpl<$Res>
    implements $TopUpSubmittedCopyWith<$Res> {
  _$TopUpSubmittedCopyWithImpl(this._self, this._then);

  final TopUpSubmitted _self;
  final $Res Function(TopUpSubmitted) _then;

/// Create a copy of TopUpEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pin = null,}) {
  return _then(TopUpSubmitted(
pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TopUpState {

 TopUpStatus get status; String get cuentaId; Money? get monto;/// Identifica la INTENCIÓN de recargar este monto. Nace al abrir la
/// pantalla, cambia solo si cambia el monto y jamás entre reintentos.
 String get idempotencyKey; TransferFailure? get failure;/// La recarga falló sin que se sepa si se acreditó (red, 429, inesperado),
/// o la clave se recuperó de un intento anterior sin resolver. Sella la
/// intención: no se edita el monto, solo reintentar con la MISMA clave o
/// salir con aviso.
 bool get outcomeUnknown;/// Había una operación sin resolver de este usuario al abrir la pantalla.
 bool get pendingElsewhere;/// La clave de este intento NO se pudo guardar.
 bool get keyUnsaved; TransferReceipt? get constancia;
/// Create a copy of TopUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopUpStateCopyWith<TopUpState> get copyWith => _$TopUpStateCopyWithImpl<TopUpState>(this as TopUpState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopUpState&&(identical(other.status, status) || other.status == status)&&(identical(other.cuentaId, cuentaId) || other.cuentaId == cuentaId)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.outcomeUnknown, outcomeUnknown) || other.outcomeUnknown == outcomeUnknown)&&(identical(other.pendingElsewhere, pendingElsewhere) || other.pendingElsewhere == pendingElsewhere)&&(identical(other.keyUnsaved, keyUnsaved) || other.keyUnsaved == keyUnsaved)&&(identical(other.constancia, constancia) || other.constancia == constancia));
}


@override
int get hashCode => Object.hash(runtimeType,status,cuentaId,monto,idempotencyKey,failure,outcomeUnknown,pendingElsewhere,keyUnsaved,constancia);

@override
String toString() {
  return 'TopUpState(status: $status, cuentaId: $cuentaId, monto: $monto, idempotencyKey: $idempotencyKey, failure: $failure, outcomeUnknown: $outcomeUnknown, pendingElsewhere: $pendingElsewhere, keyUnsaved: $keyUnsaved, constancia: $constancia)';
}


}

/// @nodoc
abstract mixin class $TopUpStateCopyWith<$Res>  {
  factory $TopUpStateCopyWith(TopUpState value, $Res Function(TopUpState) _then) = _$TopUpStateCopyWithImpl;
@useResult
$Res call({
 TopUpStatus status, String cuentaId, Money? monto, String idempotencyKey, TransferFailure? failure, bool outcomeUnknown, bool pendingElsewhere, bool keyUnsaved, TransferReceipt? constancia
});




}
/// @nodoc
class _$TopUpStateCopyWithImpl<$Res>
    implements $TopUpStateCopyWith<$Res> {
  _$TopUpStateCopyWithImpl(this._self, this._then);

  final TopUpState _self;
  final $Res Function(TopUpState) _then;

/// Create a copy of TopUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? cuentaId = null,Object? monto = freezed,Object? idempotencyKey = null,Object? failure = freezed,Object? outcomeUnknown = null,Object? pendingElsewhere = null,Object? keyUnsaved = null,Object? constancia = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopUpStatus,cuentaId: null == cuentaId ? _self.cuentaId : cuentaId // ignore: cast_nullable_to_non_nullable
as String,monto: freezed == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as Money?,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as TransferFailure?,outcomeUnknown: null == outcomeUnknown ? _self.outcomeUnknown : outcomeUnknown // ignore: cast_nullable_to_non_nullable
as bool,pendingElsewhere: null == pendingElsewhere ? _self.pendingElsewhere : pendingElsewhere // ignore: cast_nullable_to_non_nullable
as bool,keyUnsaved: null == keyUnsaved ? _self.keyUnsaved : keyUnsaved // ignore: cast_nullable_to_non_nullable
as bool,constancia: freezed == constancia ? _self.constancia : constancia // ignore: cast_nullable_to_non_nullable
as TransferReceipt?,
  ));
}

}


/// Adds pattern-matching-related methods to [TopUpState].
extension TopUpStatePatterns on TopUpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopUpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopUpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopUpState value)  $default,){
final _that = this;
switch (_that) {
case _TopUpState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopUpState value)?  $default,){
final _that = this;
switch (_that) {
case _TopUpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TopUpStatus status,  String cuentaId,  Money? monto,  String idempotencyKey,  TransferFailure? failure,  bool outcomeUnknown,  bool pendingElsewhere,  bool keyUnsaved,  TransferReceipt? constancia)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopUpState() when $default != null:
return $default(_that.status,_that.cuentaId,_that.monto,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.pendingElsewhere,_that.keyUnsaved,_that.constancia);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TopUpStatus status,  String cuentaId,  Money? monto,  String idempotencyKey,  TransferFailure? failure,  bool outcomeUnknown,  bool pendingElsewhere,  bool keyUnsaved,  TransferReceipt? constancia)  $default,) {final _that = this;
switch (_that) {
case _TopUpState():
return $default(_that.status,_that.cuentaId,_that.monto,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.pendingElsewhere,_that.keyUnsaved,_that.constancia);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TopUpStatus status,  String cuentaId,  Money? monto,  String idempotencyKey,  TransferFailure? failure,  bool outcomeUnknown,  bool pendingElsewhere,  bool keyUnsaved,  TransferReceipt? constancia)?  $default,) {final _that = this;
switch (_that) {
case _TopUpState() when $default != null:
return $default(_that.status,_that.cuentaId,_that.monto,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.pendingElsewhere,_that.keyUnsaved,_that.constancia);case _:
  return null;

}
}

}

/// @nodoc


class _TopUpState implements TopUpState {
  const _TopUpState({this.status = TopUpStatus.editing, this.cuentaId = '', this.monto, this.idempotencyKey = '', this.failure, this.outcomeUnknown = false, this.pendingElsewhere = false, this.keyUnsaved = false, this.constancia});
  

@override@JsonKey() final  TopUpStatus status;
@override@JsonKey() final  String cuentaId;
@override final  Money? monto;
/// Identifica la INTENCIÓN de recargar este monto. Nace al abrir la
/// pantalla, cambia solo si cambia el monto y jamás entre reintentos.
@override@JsonKey() final  String idempotencyKey;
@override final  TransferFailure? failure;
/// La recarga falló sin que se sepa si se acreditó (red, 429, inesperado),
/// o la clave se recuperó de un intento anterior sin resolver. Sella la
/// intención: no se edita el monto, solo reintentar con la MISMA clave o
/// salir con aviso.
@override@JsonKey() final  bool outcomeUnknown;
/// Había una operación sin resolver de este usuario al abrir la pantalla.
@override@JsonKey() final  bool pendingElsewhere;
/// La clave de este intento NO se pudo guardar.
@override@JsonKey() final  bool keyUnsaved;
@override final  TransferReceipt? constancia;

/// Create a copy of TopUpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopUpStateCopyWith<_TopUpState> get copyWith => __$TopUpStateCopyWithImpl<_TopUpState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopUpState&&(identical(other.status, status) || other.status == status)&&(identical(other.cuentaId, cuentaId) || other.cuentaId == cuentaId)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.outcomeUnknown, outcomeUnknown) || other.outcomeUnknown == outcomeUnknown)&&(identical(other.pendingElsewhere, pendingElsewhere) || other.pendingElsewhere == pendingElsewhere)&&(identical(other.keyUnsaved, keyUnsaved) || other.keyUnsaved == keyUnsaved)&&(identical(other.constancia, constancia) || other.constancia == constancia));
}


@override
int get hashCode => Object.hash(runtimeType,status,cuentaId,monto,idempotencyKey,failure,outcomeUnknown,pendingElsewhere,keyUnsaved,constancia);

@override
String toString() {
  return 'TopUpState(status: $status, cuentaId: $cuentaId, monto: $monto, idempotencyKey: $idempotencyKey, failure: $failure, outcomeUnknown: $outcomeUnknown, pendingElsewhere: $pendingElsewhere, keyUnsaved: $keyUnsaved, constancia: $constancia)';
}


}

/// @nodoc
abstract mixin class _$TopUpStateCopyWith<$Res> implements $TopUpStateCopyWith<$Res> {
  factory _$TopUpStateCopyWith(_TopUpState value, $Res Function(_TopUpState) _then) = __$TopUpStateCopyWithImpl;
@override @useResult
$Res call({
 TopUpStatus status, String cuentaId, Money? monto, String idempotencyKey, TransferFailure? failure, bool outcomeUnknown, bool pendingElsewhere, bool keyUnsaved, TransferReceipt? constancia
});




}
/// @nodoc
class __$TopUpStateCopyWithImpl<$Res>
    implements _$TopUpStateCopyWith<$Res> {
  __$TopUpStateCopyWithImpl(this._self, this._then);

  final _TopUpState _self;
  final $Res Function(_TopUpState) _then;

/// Create a copy of TopUpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? cuentaId = null,Object? monto = freezed,Object? idempotencyKey = null,Object? failure = freezed,Object? outcomeUnknown = null,Object? pendingElsewhere = null,Object? keyUnsaved = null,Object? constancia = freezed,}) {
  return _then(_TopUpState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopUpStatus,cuentaId: null == cuentaId ? _self.cuentaId : cuentaId // ignore: cast_nullable_to_non_nullable
as String,monto: freezed == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as Money?,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as TransferFailure?,outcomeUnknown: null == outcomeUnknown ? _self.outcomeUnknown : outcomeUnknown // ignore: cast_nullable_to_non_nullable
as bool,pendingElsewhere: null == pendingElsewhere ? _self.pendingElsewhere : pendingElsewhere // ignore: cast_nullable_to_non_nullable
as bool,keyUnsaved: null == keyUnsaved ? _self.keyUnsaved : keyUnsaved // ignore: cast_nullable_to_non_nullable
as bool,constancia: freezed == constancia ? _self.constancia : constancia // ignore: cast_nullable_to_non_nullable
as TransferReceipt?,
  ));
}


}

// dart format on
