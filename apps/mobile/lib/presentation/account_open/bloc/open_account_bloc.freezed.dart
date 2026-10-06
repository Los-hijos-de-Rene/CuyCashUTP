// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'open_account_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpenAccountEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAccountEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OpenAccountEvent()';
}


}

/// @nodoc
class $OpenAccountEventCopyWith<$Res>  {
$OpenAccountEventCopyWith(OpenAccountEvent _, $Res Function(OpenAccountEvent) __);
}


/// Adds pattern-matching-related methods to [OpenAccountEvent].
extension OpenAccountEventPatterns on OpenAccountEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OpenAccountOpened value)?  opened,TResult Function( OpenAccountTipoChanged value)?  tipoChanged,TResult Function( OpenAccountMonedaChanged value)?  monedaChanged,TResult Function( OpenAccountNombreChanged value)?  nombreChanged,TResult Function( OpenAccountSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OpenAccountOpened() when opened != null:
return opened(_that);case OpenAccountTipoChanged() when tipoChanged != null:
return tipoChanged(_that);case OpenAccountMonedaChanged() when monedaChanged != null:
return monedaChanged(_that);case OpenAccountNombreChanged() when nombreChanged != null:
return nombreChanged(_that);case OpenAccountSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OpenAccountOpened value)  opened,required TResult Function( OpenAccountTipoChanged value)  tipoChanged,required TResult Function( OpenAccountMonedaChanged value)  monedaChanged,required TResult Function( OpenAccountNombreChanged value)  nombreChanged,required TResult Function( OpenAccountSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case OpenAccountOpened():
return opened(_that);case OpenAccountTipoChanged():
return tipoChanged(_that);case OpenAccountMonedaChanged():
return monedaChanged(_that);case OpenAccountNombreChanged():
return nombreChanged(_that);case OpenAccountSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OpenAccountOpened value)?  opened,TResult? Function( OpenAccountTipoChanged value)?  tipoChanged,TResult? Function( OpenAccountMonedaChanged value)?  monedaChanged,TResult? Function( OpenAccountNombreChanged value)?  nombreChanged,TResult? Function( OpenAccountSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case OpenAccountOpened() when opened != null:
return opened(_that);case OpenAccountTipoChanged() when tipoChanged != null:
return tipoChanged(_that);case OpenAccountMonedaChanged() when monedaChanged != null:
return monedaChanged(_that);case OpenAccountNombreChanged() when nombreChanged != null:
return nombreChanged(_that);case OpenAccountSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  opened,TResult Function( AccountType tipo)?  tipoChanged,TResult Function( Currency moneda)?  monedaChanged,TResult Function( String nombre)?  nombreChanged,TResult Function( String pin)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OpenAccountOpened() when opened != null:
return opened();case OpenAccountTipoChanged() when tipoChanged != null:
return tipoChanged(_that.tipo);case OpenAccountMonedaChanged() when monedaChanged != null:
return monedaChanged(_that.moneda);case OpenAccountNombreChanged() when nombreChanged != null:
return nombreChanged(_that.nombre);case OpenAccountSubmitted() when submitted != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  opened,required TResult Function( AccountType tipo)  tipoChanged,required TResult Function( Currency moneda)  monedaChanged,required TResult Function( String nombre)  nombreChanged,required TResult Function( String pin)  submitted,}) {final _that = this;
switch (_that) {
case OpenAccountOpened():
return opened();case OpenAccountTipoChanged():
return tipoChanged(_that.tipo);case OpenAccountMonedaChanged():
return monedaChanged(_that.moneda);case OpenAccountNombreChanged():
return nombreChanged(_that.nombre);case OpenAccountSubmitted():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  opened,TResult? Function( AccountType tipo)?  tipoChanged,TResult? Function( Currency moneda)?  monedaChanged,TResult? Function( String nombre)?  nombreChanged,TResult? Function( String pin)?  submitted,}) {final _that = this;
switch (_that) {
case OpenAccountOpened() when opened != null:
return opened();case OpenAccountTipoChanged() when tipoChanged != null:
return tipoChanged(_that.tipo);case OpenAccountMonedaChanged() when monedaChanged != null:
return monedaChanged(_that.moneda);case OpenAccountNombreChanged() when nombreChanged != null:
return nombreChanged(_that.nombre);case OpenAccountSubmitted() when submitted != null:
return submitted(_that.pin);case _:
  return null;

}
}

}

/// @nodoc


class OpenAccountOpened implements OpenAccountEvent {
  const OpenAccountOpened();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAccountOpened);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OpenAccountEvent.opened()';
}


}




/// @nodoc


class OpenAccountTipoChanged implements OpenAccountEvent {
  const OpenAccountTipoChanged(this.tipo);
  

 final  AccountType tipo;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAccountTipoChangedCopyWith<OpenAccountTipoChanged> get copyWith => _$OpenAccountTipoChangedCopyWithImpl<OpenAccountTipoChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAccountTipoChanged&&(identical(other.tipo, tipo) || other.tipo == tipo));
}


@override
int get hashCode => Object.hash(runtimeType,tipo);

@override
String toString() {
  return 'OpenAccountEvent.tipoChanged(tipo: $tipo)';
}


}

/// @nodoc
abstract mixin class $OpenAccountTipoChangedCopyWith<$Res> implements $OpenAccountEventCopyWith<$Res> {
  factory $OpenAccountTipoChangedCopyWith(OpenAccountTipoChanged value, $Res Function(OpenAccountTipoChanged) _then) = _$OpenAccountTipoChangedCopyWithImpl;
@useResult
$Res call({
 AccountType tipo
});




}
/// @nodoc
class _$OpenAccountTipoChangedCopyWithImpl<$Res>
    implements $OpenAccountTipoChangedCopyWith<$Res> {
  _$OpenAccountTipoChangedCopyWithImpl(this._self, this._then);

  final OpenAccountTipoChanged _self;
  final $Res Function(OpenAccountTipoChanged) _then;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tipo = null,}) {
  return _then(OpenAccountTipoChanged(
null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as AccountType,
  ));
}


}

/// @nodoc


class OpenAccountMonedaChanged implements OpenAccountEvent {
  const OpenAccountMonedaChanged(this.moneda);
  

 final  Currency moneda;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAccountMonedaChangedCopyWith<OpenAccountMonedaChanged> get copyWith => _$OpenAccountMonedaChangedCopyWithImpl<OpenAccountMonedaChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAccountMonedaChanged&&(identical(other.moneda, moneda) || other.moneda == moneda));
}


@override
int get hashCode => Object.hash(runtimeType,moneda);

@override
String toString() {
  return 'OpenAccountEvent.monedaChanged(moneda: $moneda)';
}


}

/// @nodoc
abstract mixin class $OpenAccountMonedaChangedCopyWith<$Res> implements $OpenAccountEventCopyWith<$Res> {
  factory $OpenAccountMonedaChangedCopyWith(OpenAccountMonedaChanged value, $Res Function(OpenAccountMonedaChanged) _then) = _$OpenAccountMonedaChangedCopyWithImpl;
@useResult
$Res call({
 Currency moneda
});




}
/// @nodoc
class _$OpenAccountMonedaChangedCopyWithImpl<$Res>
    implements $OpenAccountMonedaChangedCopyWith<$Res> {
  _$OpenAccountMonedaChangedCopyWithImpl(this._self, this._then);

  final OpenAccountMonedaChanged _self;
  final $Res Function(OpenAccountMonedaChanged) _then;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? moneda = null,}) {
  return _then(OpenAccountMonedaChanged(
null == moneda ? _self.moneda : moneda // ignore: cast_nullable_to_non_nullable
as Currency,
  ));
}


}

/// @nodoc


class OpenAccountNombreChanged implements OpenAccountEvent {
  const OpenAccountNombreChanged(this.nombre);
  

 final  String nombre;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAccountNombreChangedCopyWith<OpenAccountNombreChanged> get copyWith => _$OpenAccountNombreChangedCopyWithImpl<OpenAccountNombreChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAccountNombreChanged&&(identical(other.nombre, nombre) || other.nombre == nombre));
}


@override
int get hashCode => Object.hash(runtimeType,nombre);

@override
String toString() {
  return 'OpenAccountEvent.nombreChanged(nombre: $nombre)';
}


}

/// @nodoc
abstract mixin class $OpenAccountNombreChangedCopyWith<$Res> implements $OpenAccountEventCopyWith<$Res> {
  factory $OpenAccountNombreChangedCopyWith(OpenAccountNombreChanged value, $Res Function(OpenAccountNombreChanged) _then) = _$OpenAccountNombreChangedCopyWithImpl;
@useResult
$Res call({
 String nombre
});




}
/// @nodoc
class _$OpenAccountNombreChangedCopyWithImpl<$Res>
    implements $OpenAccountNombreChangedCopyWith<$Res> {
  _$OpenAccountNombreChangedCopyWithImpl(this._self, this._then);

  final OpenAccountNombreChanged _self;
  final $Res Function(OpenAccountNombreChanged) _then;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? nombre = null,}) {
  return _then(OpenAccountNombreChanged(
null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OpenAccountSubmitted implements OpenAccountEvent {
  const OpenAccountSubmitted({required this.pin});
  

 final  String pin;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAccountSubmittedCopyWith<OpenAccountSubmitted> get copyWith => _$OpenAccountSubmittedCopyWithImpl<OpenAccountSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAccountSubmitted&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,pin);

@override
String toString() {
  return 'OpenAccountEvent.submitted(pin: $pin)';
}


}

/// @nodoc
abstract mixin class $OpenAccountSubmittedCopyWith<$Res> implements $OpenAccountEventCopyWith<$Res> {
  factory $OpenAccountSubmittedCopyWith(OpenAccountSubmitted value, $Res Function(OpenAccountSubmitted) _then) = _$OpenAccountSubmittedCopyWithImpl;
@useResult
$Res call({
 String pin
});




}
/// @nodoc
class _$OpenAccountSubmittedCopyWithImpl<$Res>
    implements $OpenAccountSubmittedCopyWith<$Res> {
  _$OpenAccountSubmittedCopyWithImpl(this._self, this._then);

  final OpenAccountSubmitted _self;
  final $Res Function(OpenAccountSubmitted) _then;

/// Create a copy of OpenAccountEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pin = null,}) {
  return _then(OpenAccountSubmitted(
pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$OpenAccountState {

 OpenAccountStatus get status; AccountType get tipo; Currency get moneda; String get nombre;/// Identifica la INTENCIÓN (tipo + moneda + nombre). Nace al abrir,
/// cambia solo si cambia la intención y jamás entre reintentos.
 String get idempotencyKey; AccountFailure? get failure;/// Falló sin saberse si se abrió: la intención queda sellada.
 bool get outcomeUnknown; bool get keyUnsaved;/// ¿Hay ya una sueldo entre las cuentas del titular?
 bool get tieneSueldo; Account? get cuenta;
/// Create a copy of OpenAccountState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenAccountStateCopyWith<OpenAccountState> get copyWith => _$OpenAccountStateCopyWithImpl<OpenAccountState>(this as OpenAccountState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenAccountState&&(identical(other.status, status) || other.status == status)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.moneda, moneda) || other.moneda == moneda)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.outcomeUnknown, outcomeUnknown) || other.outcomeUnknown == outcomeUnknown)&&(identical(other.keyUnsaved, keyUnsaved) || other.keyUnsaved == keyUnsaved)&&(identical(other.tieneSueldo, tieneSueldo) || other.tieneSueldo == tieneSueldo)&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta));
}


@override
int get hashCode => Object.hash(runtimeType,status,tipo,moneda,nombre,idempotencyKey,failure,outcomeUnknown,keyUnsaved,tieneSueldo,cuenta);

@override
String toString() {
  return 'OpenAccountState(status: $status, tipo: $tipo, moneda: $moneda, nombre: $nombre, idempotencyKey: $idempotencyKey, failure: $failure, outcomeUnknown: $outcomeUnknown, keyUnsaved: $keyUnsaved, tieneSueldo: $tieneSueldo, cuenta: $cuenta)';
}


}

/// @nodoc
abstract mixin class $OpenAccountStateCopyWith<$Res>  {
  factory $OpenAccountStateCopyWith(OpenAccountState value, $Res Function(OpenAccountState) _then) = _$OpenAccountStateCopyWithImpl;
@useResult
$Res call({
 OpenAccountStatus status, AccountType tipo, Currency moneda, String nombre, String idempotencyKey, AccountFailure? failure, bool outcomeUnknown, bool keyUnsaved, bool tieneSueldo, Account? cuenta
});




}
/// @nodoc
class _$OpenAccountStateCopyWithImpl<$Res>
    implements $OpenAccountStateCopyWith<$Res> {
  _$OpenAccountStateCopyWithImpl(this._self, this._then);

  final OpenAccountState _self;
  final $Res Function(OpenAccountState) _then;

/// Create a copy of OpenAccountState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? tipo = null,Object? moneda = null,Object? nombre = null,Object? idempotencyKey = null,Object? failure = freezed,Object? outcomeUnknown = null,Object? keyUnsaved = null,Object? tieneSueldo = null,Object? cuenta = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OpenAccountStatus,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as AccountType,moneda: null == moneda ? _self.moneda : moneda // ignore: cast_nullable_to_non_nullable
as Currency,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,outcomeUnknown: null == outcomeUnknown ? _self.outcomeUnknown : outcomeUnknown // ignore: cast_nullable_to_non_nullable
as bool,keyUnsaved: null == keyUnsaved ? _self.keyUnsaved : keyUnsaved // ignore: cast_nullable_to_non_nullable
as bool,tieneSueldo: null == tieneSueldo ? _self.tieneSueldo : tieneSueldo // ignore: cast_nullable_to_non_nullable
as bool,cuenta: freezed == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account?,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenAccountState].
extension OpenAccountStatePatterns on OpenAccountState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenAccountState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenAccountState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenAccountState value)  $default,){
final _that = this;
switch (_that) {
case _OpenAccountState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenAccountState value)?  $default,){
final _that = this;
switch (_that) {
case _OpenAccountState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OpenAccountStatus status,  AccountType tipo,  Currency moneda,  String nombre,  String idempotencyKey,  AccountFailure? failure,  bool outcomeUnknown,  bool keyUnsaved,  bool tieneSueldo,  Account? cuenta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenAccountState() when $default != null:
return $default(_that.status,_that.tipo,_that.moneda,_that.nombre,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.keyUnsaved,_that.tieneSueldo,_that.cuenta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OpenAccountStatus status,  AccountType tipo,  Currency moneda,  String nombre,  String idempotencyKey,  AccountFailure? failure,  bool outcomeUnknown,  bool keyUnsaved,  bool tieneSueldo,  Account? cuenta)  $default,) {final _that = this;
switch (_that) {
case _OpenAccountState():
return $default(_that.status,_that.tipo,_that.moneda,_that.nombre,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.keyUnsaved,_that.tieneSueldo,_that.cuenta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OpenAccountStatus status,  AccountType tipo,  Currency moneda,  String nombre,  String idempotencyKey,  AccountFailure? failure,  bool outcomeUnknown,  bool keyUnsaved,  bool tieneSueldo,  Account? cuenta)?  $default,) {final _that = this;
switch (_that) {
case _OpenAccountState() when $default != null:
return $default(_that.status,_that.tipo,_that.moneda,_that.nombre,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.keyUnsaved,_that.tieneSueldo,_that.cuenta);case _:
  return null;

}
}

}

/// @nodoc


class _OpenAccountState extends OpenAccountState {
  const _OpenAccountState({this.status = OpenAccountStatus.editing, this.tipo = AccountType.ahorro, this.moneda = Currency.pen, this.nombre = '', this.idempotencyKey = '', this.failure, this.outcomeUnknown = false, this.keyUnsaved = false, this.tieneSueldo = false, this.cuenta}): super._();
  

@override@JsonKey() final  OpenAccountStatus status;
@override@JsonKey() final  AccountType tipo;
@override@JsonKey() final  Currency moneda;
@override@JsonKey() final  String nombre;
/// Identifica la INTENCIÓN (tipo + moneda + nombre). Nace al abrir,
/// cambia solo si cambia la intención y jamás entre reintentos.
@override@JsonKey() final  String idempotencyKey;
@override final  AccountFailure? failure;
/// Falló sin saberse si se abrió: la intención queda sellada.
@override@JsonKey() final  bool outcomeUnknown;
@override@JsonKey() final  bool keyUnsaved;
/// ¿Hay ya una sueldo entre las cuentas del titular?
@override@JsonKey() final  bool tieneSueldo;
@override final  Account? cuenta;

/// Create a copy of OpenAccountState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenAccountStateCopyWith<_OpenAccountState> get copyWith => __$OpenAccountStateCopyWithImpl<_OpenAccountState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenAccountState&&(identical(other.status, status) || other.status == status)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.moneda, moneda) || other.moneda == moneda)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.outcomeUnknown, outcomeUnknown) || other.outcomeUnknown == outcomeUnknown)&&(identical(other.keyUnsaved, keyUnsaved) || other.keyUnsaved == keyUnsaved)&&(identical(other.tieneSueldo, tieneSueldo) || other.tieneSueldo == tieneSueldo)&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta));
}


@override
int get hashCode => Object.hash(runtimeType,status,tipo,moneda,nombre,idempotencyKey,failure,outcomeUnknown,keyUnsaved,tieneSueldo,cuenta);

@override
String toString() {
  return 'OpenAccountState(status: $status, tipo: $tipo, moneda: $moneda, nombre: $nombre, idempotencyKey: $idempotencyKey, failure: $failure, outcomeUnknown: $outcomeUnknown, keyUnsaved: $keyUnsaved, tieneSueldo: $tieneSueldo, cuenta: $cuenta)';
}


}

/// @nodoc
abstract mixin class _$OpenAccountStateCopyWith<$Res> implements $OpenAccountStateCopyWith<$Res> {
  factory _$OpenAccountStateCopyWith(_OpenAccountState value, $Res Function(_OpenAccountState) _then) = __$OpenAccountStateCopyWithImpl;
@override @useResult
$Res call({
 OpenAccountStatus status, AccountType tipo, Currency moneda, String nombre, String idempotencyKey, AccountFailure? failure, bool outcomeUnknown, bool keyUnsaved, bool tieneSueldo, Account? cuenta
});




}
/// @nodoc
class __$OpenAccountStateCopyWithImpl<$Res>
    implements _$OpenAccountStateCopyWith<$Res> {
  __$OpenAccountStateCopyWithImpl(this._self, this._then);

  final _OpenAccountState _self;
  final $Res Function(_OpenAccountState) _then;

/// Create a copy of OpenAccountState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? tipo = null,Object? moneda = null,Object? nombre = null,Object? idempotencyKey = null,Object? failure = freezed,Object? outcomeUnknown = null,Object? keyUnsaved = null,Object? tieneSueldo = null,Object? cuenta = freezed,}) {
  return _then(_OpenAccountState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OpenAccountStatus,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as AccountType,moneda: null == moneda ? _self.moneda : moneda // ignore: cast_nullable_to_non_nullable
as Currency,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,outcomeUnknown: null == outcomeUnknown ? _self.outcomeUnknown : outcomeUnknown // ignore: cast_nullable_to_non_nullable
as bool,keyUnsaved: null == keyUnsaved ? _self.keyUnsaved : keyUnsaved // ignore: cast_nullable_to_non_nullable
as bool,tieneSueldo: null == tieneSueldo ? _self.tieneSueldo : tieneSueldo // ignore: cast_nullable_to_non_nullable
as bool,cuenta: freezed == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account?,
  ));
}


}

// dart format on
