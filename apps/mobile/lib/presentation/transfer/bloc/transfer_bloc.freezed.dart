// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransferEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransferEvent()';
}


}

/// @nodoc
class $TransferEventCopyWith<$Res>  {
$TransferEventCopyWith(TransferEvent _, $Res Function(TransferEvent) __);
}


/// Adds pattern-matching-related methods to [TransferEvent].
extension TransferEventPatterns on TransferEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TransferStarted value)?  started,TResult Function( TransferRecipientRequested value)?  recipientRequested,TResult Function( TransferRecipientCleared value)?  recipientCleared,TResult Function( TransferAmountEntered value)?  amountEntered,TResult Function( TransferConfirmationOpened value)?  confirmationOpened,TResult Function( TransferSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TransferStarted() when started != null:
return started(_that);case TransferRecipientRequested() when recipientRequested != null:
return recipientRequested(_that);case TransferRecipientCleared() when recipientCleared != null:
return recipientCleared(_that);case TransferAmountEntered() when amountEntered != null:
return amountEntered(_that);case TransferConfirmationOpened() when confirmationOpened != null:
return confirmationOpened(_that);case TransferSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TransferStarted value)  started,required TResult Function( TransferRecipientRequested value)  recipientRequested,required TResult Function( TransferRecipientCleared value)  recipientCleared,required TResult Function( TransferAmountEntered value)  amountEntered,required TResult Function( TransferConfirmationOpened value)  confirmationOpened,required TResult Function( TransferSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case TransferStarted():
return started(_that);case TransferRecipientRequested():
return recipientRequested(_that);case TransferRecipientCleared():
return recipientCleared(_that);case TransferAmountEntered():
return amountEntered(_that);case TransferConfirmationOpened():
return confirmationOpened(_that);case TransferSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TransferStarted value)?  started,TResult? Function( TransferRecipientRequested value)?  recipientRequested,TResult? Function( TransferRecipientCleared value)?  recipientCleared,TResult? Function( TransferAmountEntered value)?  amountEntered,TResult? Function( TransferConfirmationOpened value)?  confirmationOpened,TResult? Function( TransferSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case TransferStarted() when started != null:
return started(_that);case TransferRecipientRequested() when recipientRequested != null:
return recipientRequested(_that);case TransferRecipientCleared() when recipientCleared != null:
return recipientCleared(_that);case TransferAmountEntered() when amountEntered != null:
return amountEntered(_that);case TransferConfirmationOpened() when confirmationOpened != null:
return confirmationOpened(_that);case TransferSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Account cuenta)?  started,TResult Function( String dni)?  recipientRequested,TResult Function()?  recipientCleared,TResult Function( Money monto,  String? motivo)?  amountEntered,TResult Function()?  confirmationOpened,TResult Function( String pin)?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransferStarted() when started != null:
return started(_that.cuenta);case TransferRecipientRequested() when recipientRequested != null:
return recipientRequested(_that.dni);case TransferRecipientCleared() when recipientCleared != null:
return recipientCleared();case TransferAmountEntered() when amountEntered != null:
return amountEntered(_that.monto,_that.motivo);case TransferConfirmationOpened() when confirmationOpened != null:
return confirmationOpened();case TransferSubmitted() when submitted != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Account cuenta)  started,required TResult Function( String dni)  recipientRequested,required TResult Function()  recipientCleared,required TResult Function( Money monto,  String? motivo)  amountEntered,required TResult Function()  confirmationOpened,required TResult Function( String pin)  submitted,}) {final _that = this;
switch (_that) {
case TransferStarted():
return started(_that.cuenta);case TransferRecipientRequested():
return recipientRequested(_that.dni);case TransferRecipientCleared():
return recipientCleared();case TransferAmountEntered():
return amountEntered(_that.monto,_that.motivo);case TransferConfirmationOpened():
return confirmationOpened();case TransferSubmitted():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Account cuenta)?  started,TResult? Function( String dni)?  recipientRequested,TResult? Function()?  recipientCleared,TResult? Function( Money monto,  String? motivo)?  amountEntered,TResult? Function()?  confirmationOpened,TResult? Function( String pin)?  submitted,}) {final _that = this;
switch (_that) {
case TransferStarted() when started != null:
return started(_that.cuenta);case TransferRecipientRequested() when recipientRequested != null:
return recipientRequested(_that.dni);case TransferRecipientCleared() when recipientCleared != null:
return recipientCleared();case TransferAmountEntered() when amountEntered != null:
return amountEntered(_that.monto,_that.motivo);case TransferConfirmationOpened() when confirmationOpened != null:
return confirmationOpened();case TransferSubmitted() when submitted != null:
return submitted(_that.pin);case _:
  return null;

}
}

}

/// @nodoc


class TransferStarted implements TransferEvent {
  const TransferStarted(this.cuenta);
  

 final  Account cuenta;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferStartedCopyWith<TransferStarted> get copyWith => _$TransferStartedCopyWithImpl<TransferStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferStarted&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta));
}


@override
int get hashCode => Object.hash(runtimeType,cuenta);

@override
String toString() {
  return 'TransferEvent.started(cuenta: $cuenta)';
}


}

/// @nodoc
abstract mixin class $TransferStartedCopyWith<$Res> implements $TransferEventCopyWith<$Res> {
  factory $TransferStartedCopyWith(TransferStarted value, $Res Function(TransferStarted) _then) = _$TransferStartedCopyWithImpl;
@useResult
$Res call({
 Account cuenta
});




}
/// @nodoc
class _$TransferStartedCopyWithImpl<$Res>
    implements $TransferStartedCopyWith<$Res> {
  _$TransferStartedCopyWithImpl(this._self, this._then);

  final TransferStarted _self;
  final $Res Function(TransferStarted) _then;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cuenta = null,}) {
  return _then(TransferStarted(
null == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account,
  ));
}


}

/// @nodoc


class TransferRecipientRequested implements TransferEvent {
  const TransferRecipientRequested(this.dni);
  

 final  String dni;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferRecipientRequestedCopyWith<TransferRecipientRequested> get copyWith => _$TransferRecipientRequestedCopyWithImpl<TransferRecipientRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferRecipientRequested&&(identical(other.dni, dni) || other.dni == dni));
}


@override
int get hashCode => Object.hash(runtimeType,dni);

@override
String toString() {
  return 'TransferEvent.recipientRequested(dni: $dni)';
}


}

/// @nodoc
abstract mixin class $TransferRecipientRequestedCopyWith<$Res> implements $TransferEventCopyWith<$Res> {
  factory $TransferRecipientRequestedCopyWith(TransferRecipientRequested value, $Res Function(TransferRecipientRequested) _then) = _$TransferRecipientRequestedCopyWithImpl;
@useResult
$Res call({
 String dni
});




}
/// @nodoc
class _$TransferRecipientRequestedCopyWithImpl<$Res>
    implements $TransferRecipientRequestedCopyWith<$Res> {
  _$TransferRecipientRequestedCopyWithImpl(this._self, this._then);

  final TransferRecipientRequested _self;
  final $Res Function(TransferRecipientRequested) _then;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dni = null,}) {
  return _then(TransferRecipientRequested(
null == dni ? _self.dni : dni // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransferRecipientCleared implements TransferEvent {
  const TransferRecipientCleared();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferRecipientCleared);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransferEvent.recipientCleared()';
}


}




/// @nodoc


class TransferAmountEntered implements TransferEvent {
  const TransferAmountEntered({required this.monto, this.motivo});
  

 final  Money monto;
 final  String? motivo;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferAmountEnteredCopyWith<TransferAmountEntered> get copyWith => _$TransferAmountEnteredCopyWithImpl<TransferAmountEntered>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferAmountEntered&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.motivo, motivo) || other.motivo == motivo));
}


@override
int get hashCode => Object.hash(runtimeType,monto,motivo);

@override
String toString() {
  return 'TransferEvent.amountEntered(monto: $monto, motivo: $motivo)';
}


}

/// @nodoc
abstract mixin class $TransferAmountEnteredCopyWith<$Res> implements $TransferEventCopyWith<$Res> {
  factory $TransferAmountEnteredCopyWith(TransferAmountEntered value, $Res Function(TransferAmountEntered) _then) = _$TransferAmountEnteredCopyWithImpl;
@useResult
$Res call({
 Money monto, String? motivo
});




}
/// @nodoc
class _$TransferAmountEnteredCopyWithImpl<$Res>
    implements $TransferAmountEnteredCopyWith<$Res> {
  _$TransferAmountEnteredCopyWithImpl(this._self, this._then);

  final TransferAmountEntered _self;
  final $Res Function(TransferAmountEntered) _then;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? monto = null,Object? motivo = freezed,}) {
  return _then(TransferAmountEntered(
monto: null == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as Money,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class TransferConfirmationOpened implements TransferEvent {
  const TransferConfirmationOpened();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferConfirmationOpened);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransferEvent.confirmationOpened()';
}


}




/// @nodoc


class TransferSubmitted implements TransferEvent {
  const TransferSubmitted({required this.pin});
  

 final  String pin;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferSubmittedCopyWith<TransferSubmitted> get copyWith => _$TransferSubmittedCopyWithImpl<TransferSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferSubmitted&&(identical(other.pin, pin) || other.pin == pin));
}


@override
int get hashCode => Object.hash(runtimeType,pin);

@override
String toString() {
  return 'TransferEvent.submitted(pin: $pin)';
}


}

/// @nodoc
abstract mixin class $TransferSubmittedCopyWith<$Res> implements $TransferEventCopyWith<$Res> {
  factory $TransferSubmittedCopyWith(TransferSubmitted value, $Res Function(TransferSubmitted) _then) = _$TransferSubmittedCopyWithImpl;
@useResult
$Res call({
 String pin
});




}
/// @nodoc
class _$TransferSubmittedCopyWithImpl<$Res>
    implements $TransferSubmittedCopyWith<$Res> {
  _$TransferSubmittedCopyWithImpl(this._self, this._then);

  final TransferSubmitted _self;
  final $Res Function(TransferSubmitted) _then;

/// Create a copy of TransferEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pin = null,}) {
  return _then(TransferSubmitted(
pin: null == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TransferState {

 TransferStatus get status; Account? get cuenta; Recipient? get destinatario; Money? get monto; String? get motivo;/// Reservado para "guardar como frecuente" (`feature/beneficiary`, tarea
/// 16). Sin UI hasta entonces: un interruptor que no hace nada mentiría.
 bool get guardarFrecuente;/// Identifica la INTENCIÓN de enviar este monto a este destinatario. Se
/// fija al abrir la confirmación y solo se borra si cambia la intención;
/// jamás entre reintentos. Vacía = aún no hay intención.
 String get idempotencyKey;/// El último fallo (de la búsqueda o del envío, según la pantalla).
 TransferFailure? get failure;/// Un envío falló sin que se sepa si el dinero se movió (red, 429,
/// inesperado). Sella la intención: mientras esté encendida no se puede
/// cambiar destinatario ni monto, solo reintentar con la MISMA clave o
/// abandonar el flujo.
 bool get outcomeUnknown;/// Al abrir la confirmación había un envío pendiente de este usuario que
/// NO coincide exacto con esta intención (otro monto, otro motivo). No se
/// sella —no se sabe si es el mismo—, pero se avisa.
 bool get pendingElsewhere;/// La clave de este envío NO se pudo guardar: si el resultado queda
/// desconocido, reentrar al flujo no la recuperará.
 bool get keyUnsaved; TransferReceipt? get constancia;
/// Create a copy of TransferState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferStateCopyWith<TransferState> get copyWith => _$TransferStateCopyWithImpl<TransferState>(this as TransferState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferState&&(identical(other.status, status) || other.status == status)&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta)&&(identical(other.destinatario, destinatario) || other.destinatario == destinatario)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.guardarFrecuente, guardarFrecuente) || other.guardarFrecuente == guardarFrecuente)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.outcomeUnknown, outcomeUnknown) || other.outcomeUnknown == outcomeUnknown)&&(identical(other.pendingElsewhere, pendingElsewhere) || other.pendingElsewhere == pendingElsewhere)&&(identical(other.keyUnsaved, keyUnsaved) || other.keyUnsaved == keyUnsaved)&&(identical(other.constancia, constancia) || other.constancia == constancia));
}


@override
int get hashCode => Object.hash(runtimeType,status,cuenta,destinatario,monto,motivo,guardarFrecuente,idempotencyKey,failure,outcomeUnknown,pendingElsewhere,keyUnsaved,constancia);

@override
String toString() {
  return 'TransferState(status: $status, cuenta: $cuenta, destinatario: $destinatario, monto: $monto, motivo: $motivo, guardarFrecuente: $guardarFrecuente, idempotencyKey: $idempotencyKey, failure: $failure, outcomeUnknown: $outcomeUnknown, pendingElsewhere: $pendingElsewhere, keyUnsaved: $keyUnsaved, constancia: $constancia)';
}


}

/// @nodoc
abstract mixin class $TransferStateCopyWith<$Res>  {
  factory $TransferStateCopyWith(TransferState value, $Res Function(TransferState) _then) = _$TransferStateCopyWithImpl;
@useResult
$Res call({
 TransferStatus status, Account? cuenta, Recipient? destinatario, Money? monto, String? motivo, bool guardarFrecuente, String idempotencyKey, TransferFailure? failure, bool outcomeUnknown, bool pendingElsewhere, bool keyUnsaved, TransferReceipt? constancia
});




}
/// @nodoc
class _$TransferStateCopyWithImpl<$Res>
    implements $TransferStateCopyWith<$Res> {
  _$TransferStateCopyWithImpl(this._self, this._then);

  final TransferState _self;
  final $Res Function(TransferState) _then;

/// Create a copy of TransferState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? cuenta = freezed,Object? destinatario = freezed,Object? monto = freezed,Object? motivo = freezed,Object? guardarFrecuente = null,Object? idempotencyKey = null,Object? failure = freezed,Object? outcomeUnknown = null,Object? pendingElsewhere = null,Object? keyUnsaved = null,Object? constancia = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,cuenta: freezed == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account?,destinatario: freezed == destinatario ? _self.destinatario : destinatario // ignore: cast_nullable_to_non_nullable
as Recipient?,monto: freezed == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as Money?,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,guardarFrecuente: null == guardarFrecuente ? _self.guardarFrecuente : guardarFrecuente // ignore: cast_nullable_to_non_nullable
as bool,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as TransferFailure?,outcomeUnknown: null == outcomeUnknown ? _self.outcomeUnknown : outcomeUnknown // ignore: cast_nullable_to_non_nullable
as bool,pendingElsewhere: null == pendingElsewhere ? _self.pendingElsewhere : pendingElsewhere // ignore: cast_nullable_to_non_nullable
as bool,keyUnsaved: null == keyUnsaved ? _self.keyUnsaved : keyUnsaved // ignore: cast_nullable_to_non_nullable
as bool,constancia: freezed == constancia ? _self.constancia : constancia // ignore: cast_nullable_to_non_nullable
as TransferReceipt?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransferState].
extension TransferStatePatterns on TransferState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferState value)  $default,){
final _that = this;
switch (_that) {
case _TransferState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferState value)?  $default,){
final _that = this;
switch (_that) {
case _TransferState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransferStatus status,  Account? cuenta,  Recipient? destinatario,  Money? monto,  String? motivo,  bool guardarFrecuente,  String idempotencyKey,  TransferFailure? failure,  bool outcomeUnknown,  bool pendingElsewhere,  bool keyUnsaved,  TransferReceipt? constancia)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferState() when $default != null:
return $default(_that.status,_that.cuenta,_that.destinatario,_that.monto,_that.motivo,_that.guardarFrecuente,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.pendingElsewhere,_that.keyUnsaved,_that.constancia);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransferStatus status,  Account? cuenta,  Recipient? destinatario,  Money? monto,  String? motivo,  bool guardarFrecuente,  String idempotencyKey,  TransferFailure? failure,  bool outcomeUnknown,  bool pendingElsewhere,  bool keyUnsaved,  TransferReceipt? constancia)  $default,) {final _that = this;
switch (_that) {
case _TransferState():
return $default(_that.status,_that.cuenta,_that.destinatario,_that.monto,_that.motivo,_that.guardarFrecuente,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.pendingElsewhere,_that.keyUnsaved,_that.constancia);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransferStatus status,  Account? cuenta,  Recipient? destinatario,  Money? monto,  String? motivo,  bool guardarFrecuente,  String idempotencyKey,  TransferFailure? failure,  bool outcomeUnknown,  bool pendingElsewhere,  bool keyUnsaved,  TransferReceipt? constancia)?  $default,) {final _that = this;
switch (_that) {
case _TransferState() when $default != null:
return $default(_that.status,_that.cuenta,_that.destinatario,_that.monto,_that.motivo,_that.guardarFrecuente,_that.idempotencyKey,_that.failure,_that.outcomeUnknown,_that.pendingElsewhere,_that.keyUnsaved,_that.constancia);case _:
  return null;

}
}

}

/// @nodoc


class _TransferState implements TransferState {
  const _TransferState({this.status = TransferStatus.idle, this.cuenta, this.destinatario, this.monto, this.motivo, this.guardarFrecuente = false, this.idempotencyKey = '', this.failure, this.outcomeUnknown = false, this.pendingElsewhere = false, this.keyUnsaved = false, this.constancia});
  

@override@JsonKey() final  TransferStatus status;
@override final  Account? cuenta;
@override final  Recipient? destinatario;
@override final  Money? monto;
@override final  String? motivo;
/// Reservado para "guardar como frecuente" (`feature/beneficiary`, tarea
/// 16). Sin UI hasta entonces: un interruptor que no hace nada mentiría.
@override@JsonKey() final  bool guardarFrecuente;
/// Identifica la INTENCIÓN de enviar este monto a este destinatario. Se
/// fija al abrir la confirmación y solo se borra si cambia la intención;
/// jamás entre reintentos. Vacía = aún no hay intención.
@override@JsonKey() final  String idempotencyKey;
/// El último fallo (de la búsqueda o del envío, según la pantalla).
@override final  TransferFailure? failure;
/// Un envío falló sin que se sepa si el dinero se movió (red, 429,
/// inesperado). Sella la intención: mientras esté encendida no se puede
/// cambiar destinatario ni monto, solo reintentar con la MISMA clave o
/// abandonar el flujo.
@override@JsonKey() final  bool outcomeUnknown;
/// Al abrir la confirmación había un envío pendiente de este usuario que
/// NO coincide exacto con esta intención (otro monto, otro motivo). No se
/// sella —no se sabe si es el mismo—, pero se avisa.
@override@JsonKey() final  bool pendingElsewhere;
/// La clave de este envío NO se pudo guardar: si el resultado queda
/// desconocido, reentrar al flujo no la recuperará.
@override@JsonKey() final  bool keyUnsaved;
@override final  TransferReceipt? constancia;

/// Create a copy of TransferState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferStateCopyWith<_TransferState> get copyWith => __$TransferStateCopyWithImpl<_TransferState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferState&&(identical(other.status, status) || other.status == status)&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta)&&(identical(other.destinatario, destinatario) || other.destinatario == destinatario)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.guardarFrecuente, guardarFrecuente) || other.guardarFrecuente == guardarFrecuente)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.outcomeUnknown, outcomeUnknown) || other.outcomeUnknown == outcomeUnknown)&&(identical(other.pendingElsewhere, pendingElsewhere) || other.pendingElsewhere == pendingElsewhere)&&(identical(other.keyUnsaved, keyUnsaved) || other.keyUnsaved == keyUnsaved)&&(identical(other.constancia, constancia) || other.constancia == constancia));
}


@override
int get hashCode => Object.hash(runtimeType,status,cuenta,destinatario,monto,motivo,guardarFrecuente,idempotencyKey,failure,outcomeUnknown,pendingElsewhere,keyUnsaved,constancia);

@override
String toString() {
  return 'TransferState(status: $status, cuenta: $cuenta, destinatario: $destinatario, monto: $monto, motivo: $motivo, guardarFrecuente: $guardarFrecuente, idempotencyKey: $idempotencyKey, failure: $failure, outcomeUnknown: $outcomeUnknown, pendingElsewhere: $pendingElsewhere, keyUnsaved: $keyUnsaved, constancia: $constancia)';
}


}

/// @nodoc
abstract mixin class _$TransferStateCopyWith<$Res> implements $TransferStateCopyWith<$Res> {
  factory _$TransferStateCopyWith(_TransferState value, $Res Function(_TransferState) _then) = __$TransferStateCopyWithImpl;
@override @useResult
$Res call({
 TransferStatus status, Account? cuenta, Recipient? destinatario, Money? monto, String? motivo, bool guardarFrecuente, String idempotencyKey, TransferFailure? failure, bool outcomeUnknown, bool pendingElsewhere, bool keyUnsaved, TransferReceipt? constancia
});




}
/// @nodoc
class __$TransferStateCopyWithImpl<$Res>
    implements _$TransferStateCopyWith<$Res> {
  __$TransferStateCopyWithImpl(this._self, this._then);

  final _TransferState _self;
  final $Res Function(_TransferState) _then;

/// Create a copy of TransferState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? cuenta = freezed,Object? destinatario = freezed,Object? monto = freezed,Object? motivo = freezed,Object? guardarFrecuente = null,Object? idempotencyKey = null,Object? failure = freezed,Object? outcomeUnknown = null,Object? pendingElsewhere = null,Object? keyUnsaved = null,Object? constancia = freezed,}) {
  return _then(_TransferState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,cuenta: freezed == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account?,destinatario: freezed == destinatario ? _self.destinatario : destinatario // ignore: cast_nullable_to_non_nullable
as Recipient?,monto: freezed == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as Money?,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,guardarFrecuente: null == guardarFrecuente ? _self.guardarFrecuente : guardarFrecuente // ignore: cast_nullable_to_non_nullable
as bool,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
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
