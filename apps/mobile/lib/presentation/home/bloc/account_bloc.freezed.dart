// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent()';
}


}

/// @nodoc
class $AccountEventCopyWith<$Res>  {
$AccountEventCopyWith(AccountEvent _, $Res Function(AccountEvent) __);
}


/// Adds pattern-matching-related methods to [AccountEvent].
extension AccountEventPatterns on AccountEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AccountStarted value)?  started,TResult Function( AccountRefreshed value)?  refreshed,TResult Function( AccountMoreRequested value)?  moreRequested,TResult Function( AccountSelected value)?  selected,TResult Function( AccountOpened value)?  opened,TResult Function( AccountRenameRequested value)?  renameRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started(_that);case AccountRefreshed() when refreshed != null:
return refreshed(_that);case AccountMoreRequested() when moreRequested != null:
return moreRequested(_that);case AccountSelected() when selected != null:
return selected(_that);case AccountOpened() when opened != null:
return opened(_that);case AccountRenameRequested() when renameRequested != null:
return renameRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AccountStarted value)  started,required TResult Function( AccountRefreshed value)  refreshed,required TResult Function( AccountMoreRequested value)  moreRequested,required TResult Function( AccountSelected value)  selected,required TResult Function( AccountOpened value)  opened,required TResult Function( AccountRenameRequested value)  renameRequested,}){
final _that = this;
switch (_that) {
case AccountStarted():
return started(_that);case AccountRefreshed():
return refreshed(_that);case AccountMoreRequested():
return moreRequested(_that);case AccountSelected():
return selected(_that);case AccountOpened():
return opened(_that);case AccountRenameRequested():
return renameRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AccountStarted value)?  started,TResult? Function( AccountRefreshed value)?  refreshed,TResult? Function( AccountMoreRequested value)?  moreRequested,TResult? Function( AccountSelected value)?  selected,TResult? Function( AccountOpened value)?  opened,TResult? Function( AccountRenameRequested value)?  renameRequested,}){
final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started(_that);case AccountRefreshed() when refreshed != null:
return refreshed(_that);case AccountMoreRequested() when moreRequested != null:
return moreRequested(_that);case AccountSelected() when selected != null:
return selected(_that);case AccountOpened() when opened != null:
return opened(_that);case AccountRenameRequested() when renameRequested != null:
return renameRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  refreshed,TResult Function()?  moreRequested,TResult Function( int indice)?  selected,TResult Function( Account cuenta)?  opened,TResult Function( String cuentaId,  String? nombre)?  renameRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started();case AccountRefreshed() when refreshed != null:
return refreshed();case AccountMoreRequested() when moreRequested != null:
return moreRequested();case AccountSelected() when selected != null:
return selected(_that.indice);case AccountOpened() when opened != null:
return opened(_that.cuenta);case AccountRenameRequested() when renameRequested != null:
return renameRequested(_that.cuentaId,_that.nombre);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  refreshed,required TResult Function()  moreRequested,required TResult Function( int indice)  selected,required TResult Function( Account cuenta)  opened,required TResult Function( String cuentaId,  String? nombre)  renameRequested,}) {final _that = this;
switch (_that) {
case AccountStarted():
return started();case AccountRefreshed():
return refreshed();case AccountMoreRequested():
return moreRequested();case AccountSelected():
return selected(_that.indice);case AccountOpened():
return opened(_that.cuenta);case AccountRenameRequested():
return renameRequested(_that.cuentaId,_that.nombre);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  refreshed,TResult? Function()?  moreRequested,TResult? Function( int indice)?  selected,TResult? Function( Account cuenta)?  opened,TResult? Function( String cuentaId,  String? nombre)?  renameRequested,}) {final _that = this;
switch (_that) {
case AccountStarted() when started != null:
return started();case AccountRefreshed() when refreshed != null:
return refreshed();case AccountMoreRequested() when moreRequested != null:
return moreRequested();case AccountSelected() when selected != null:
return selected(_that.indice);case AccountOpened() when opened != null:
return opened(_that.cuenta);case AccountRenameRequested() when renameRequested != null:
return renameRequested(_that.cuentaId,_that.nombre);case _:
  return null;

}
}

}

/// @nodoc


class AccountStarted implements AccountEvent {
  const AccountStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent.started()';
}


}




/// @nodoc


class AccountRefreshed implements AccountEvent {
  const AccountRefreshed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountRefreshed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent.refreshed()';
}


}




/// @nodoc


class AccountMoreRequested implements AccountEvent {
  const AccountMoreRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountMoreRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountEvent.moreRequested()';
}


}




/// @nodoc


class AccountSelected implements AccountEvent {
  const AccountSelected(this.indice);
  

 final  int indice;

/// Create a copy of AccountEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountSelectedCopyWith<AccountSelected> get copyWith => _$AccountSelectedCopyWithImpl<AccountSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountSelected&&(identical(other.indice, indice) || other.indice == indice));
}


@override
int get hashCode => Object.hash(runtimeType,indice);

@override
String toString() {
  return 'AccountEvent.selected(indice: $indice)';
}


}

/// @nodoc
abstract mixin class $AccountSelectedCopyWith<$Res> implements $AccountEventCopyWith<$Res> {
  factory $AccountSelectedCopyWith(AccountSelected value, $Res Function(AccountSelected) _then) = _$AccountSelectedCopyWithImpl;
@useResult
$Res call({
 int indice
});




}
/// @nodoc
class _$AccountSelectedCopyWithImpl<$Res>
    implements $AccountSelectedCopyWith<$Res> {
  _$AccountSelectedCopyWithImpl(this._self, this._then);

  final AccountSelected _self;
  final $Res Function(AccountSelected) _then;

/// Create a copy of AccountEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? indice = null,}) {
  return _then(AccountSelected(
null == indice ? _self.indice : indice // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class AccountOpened implements AccountEvent {
  const AccountOpened(this.cuenta);
  

 final  Account cuenta;

/// Create a copy of AccountEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountOpenedCopyWith<AccountOpened> get copyWith => _$AccountOpenedCopyWithImpl<AccountOpened>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountOpened&&(identical(other.cuenta, cuenta) || other.cuenta == cuenta));
}


@override
int get hashCode => Object.hash(runtimeType,cuenta);

@override
String toString() {
  return 'AccountEvent.opened(cuenta: $cuenta)';
}


}

/// @nodoc
abstract mixin class $AccountOpenedCopyWith<$Res> implements $AccountEventCopyWith<$Res> {
  factory $AccountOpenedCopyWith(AccountOpened value, $Res Function(AccountOpened) _then) = _$AccountOpenedCopyWithImpl;
@useResult
$Res call({
 Account cuenta
});




}
/// @nodoc
class _$AccountOpenedCopyWithImpl<$Res>
    implements $AccountOpenedCopyWith<$Res> {
  _$AccountOpenedCopyWithImpl(this._self, this._then);

  final AccountOpened _self;
  final $Res Function(AccountOpened) _then;

/// Create a copy of AccountEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cuenta = null,}) {
  return _then(AccountOpened(
null == cuenta ? _self.cuenta : cuenta // ignore: cast_nullable_to_non_nullable
as Account,
  ));
}


}

/// @nodoc


class AccountRenameRequested implements AccountEvent {
  const AccountRenameRequested({required this.cuentaId, this.nombre});
  

 final  String cuentaId;
 final  String? nombre;

/// Create a copy of AccountEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountRenameRequestedCopyWith<AccountRenameRequested> get copyWith => _$AccountRenameRequestedCopyWithImpl<AccountRenameRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountRenameRequested&&(identical(other.cuentaId, cuentaId) || other.cuentaId == cuentaId)&&(identical(other.nombre, nombre) || other.nombre == nombre));
}


@override
int get hashCode => Object.hash(runtimeType,cuentaId,nombre);

@override
String toString() {
  return 'AccountEvent.renameRequested(cuentaId: $cuentaId, nombre: $nombre)';
}


}

/// @nodoc
abstract mixin class $AccountRenameRequestedCopyWith<$Res> implements $AccountEventCopyWith<$Res> {
  factory $AccountRenameRequestedCopyWith(AccountRenameRequested value, $Res Function(AccountRenameRequested) _then) = _$AccountRenameRequestedCopyWithImpl;
@useResult
$Res call({
 String cuentaId, String? nombre
});




}
/// @nodoc
class _$AccountRenameRequestedCopyWithImpl<$Res>
    implements $AccountRenameRequestedCopyWith<$Res> {
  _$AccountRenameRequestedCopyWithImpl(this._self, this._then);

  final AccountRenameRequested _self;
  final $Res Function(AccountRenameRequested) _then;

/// Create a copy of AccountEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cuentaId = null,Object? nombre = freezed,}) {
  return _then(AccountRenameRequested(
cuentaId: null == cuentaId ? _self.cuentaId : cuentaId // ignore: cast_nullable_to_non_nullable
as String,nombre: freezed == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AccountState {

 AccountStatus get status;/// Todas las cuentas del titular, en el orden del servidor.
 List<Account> get cuentas;/// Índice en [cuentas] de la que se ve en el carrusel.
 int get seleccionada; List<Movement> get movimientos;/// Cursor opaco de la siguiente página; `null` = no hay más.
 String? get nextCursor;/// Llega la primera página de la cuenta recién elegida en el carrusel: la
/// lista está vacía porque aún no llegó, no porque no haya movimientos.
 bool get cargandoMovimientos;/// Pidiendo la página siguiente (scroll). Solo paginación.
 bool get loadingMore; bool get refreshing;/// El último refresco falló y lo que se ve son datos anteriores.
 bool get refreshFailed;/// Solo con `status == error`.
 AccountFailure? get failure;/// Hay un cambio de nombre en vuelo.
 bool get renaming;/// El último cambio de nombre falló; `null` si salió bien o no hubo.
 AccountFailure? get renameFailure;
/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountStateCopyWith<AccountState> get copyWith => _$AccountStateCopyWithImpl<AccountState>(this as AccountState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.cuentas, cuentas)&&(identical(other.seleccionada, seleccionada) || other.seleccionada == seleccionada)&&const DeepCollectionEquality().equals(other.movimientos, movimientos)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.cargandoMovimientos, cargandoMovimientos) || other.cargandoMovimientos == cargandoMovimientos)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.refreshFailed, refreshFailed) || other.refreshFailed == refreshFailed)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.renaming, renaming) || other.renaming == renaming)&&(identical(other.renameFailure, renameFailure) || other.renameFailure == renameFailure));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(cuentas),seleccionada,const DeepCollectionEquality().hash(movimientos),nextCursor,cargandoMovimientos,loadingMore,refreshing,refreshFailed,failure,renaming,renameFailure);

@override
String toString() {
  return 'AccountState(status: $status, cuentas: $cuentas, seleccionada: $seleccionada, movimientos: $movimientos, nextCursor: $nextCursor, cargandoMovimientos: $cargandoMovimientos, loadingMore: $loadingMore, refreshing: $refreshing, refreshFailed: $refreshFailed, failure: $failure, renaming: $renaming, renameFailure: $renameFailure)';
}


}

/// @nodoc
abstract mixin class $AccountStateCopyWith<$Res>  {
  factory $AccountStateCopyWith(AccountState value, $Res Function(AccountState) _then) = _$AccountStateCopyWithImpl;
@useResult
$Res call({
 AccountStatus status, List<Account> cuentas, int seleccionada, List<Movement> movimientos, String? nextCursor, bool cargandoMovimientos, bool loadingMore, bool refreshing, bool refreshFailed, AccountFailure? failure, bool renaming, AccountFailure? renameFailure
});




}
/// @nodoc
class _$AccountStateCopyWithImpl<$Res>
    implements $AccountStateCopyWith<$Res> {
  _$AccountStateCopyWithImpl(this._self, this._then);

  final AccountState _self;
  final $Res Function(AccountState) _then;

/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? cuentas = null,Object? seleccionada = null,Object? movimientos = null,Object? nextCursor = freezed,Object? cargandoMovimientos = null,Object? loadingMore = null,Object? refreshing = null,Object? refreshFailed = null,Object? failure = freezed,Object? renaming = null,Object? renameFailure = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountStatus,cuentas: null == cuentas ? _self.cuentas : cuentas // ignore: cast_nullable_to_non_nullable
as List<Account>,seleccionada: null == seleccionada ? _self.seleccionada : seleccionada // ignore: cast_nullable_to_non_nullable
as int,movimientos: null == movimientos ? _self.movimientos : movimientos // ignore: cast_nullable_to_non_nullable
as List<Movement>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,cargandoMovimientos: null == cargandoMovimientos ? _self.cargandoMovimientos : cargandoMovimientos // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshFailed: null == refreshFailed ? _self.refreshFailed : refreshFailed // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,renaming: null == renaming ? _self.renaming : renaming // ignore: cast_nullable_to_non_nullable
as bool,renameFailure: freezed == renameFailure ? _self.renameFailure : renameFailure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountState].
extension AccountStatePatterns on AccountState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountState value)  $default,){
final _that = this;
switch (_that) {
case _AccountState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountState value)?  $default,){
final _that = this;
switch (_that) {
case _AccountState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccountStatus status,  List<Account> cuentas,  int seleccionada,  List<Movement> movimientos,  String? nextCursor,  bool cargandoMovimientos,  bool loadingMore,  bool refreshing,  bool refreshFailed,  AccountFailure? failure,  bool renaming,  AccountFailure? renameFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountState() when $default != null:
return $default(_that.status,_that.cuentas,_that.seleccionada,_that.movimientos,_that.nextCursor,_that.cargandoMovimientos,_that.loadingMore,_that.refreshing,_that.refreshFailed,_that.failure,_that.renaming,_that.renameFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccountStatus status,  List<Account> cuentas,  int seleccionada,  List<Movement> movimientos,  String? nextCursor,  bool cargandoMovimientos,  bool loadingMore,  bool refreshing,  bool refreshFailed,  AccountFailure? failure,  bool renaming,  AccountFailure? renameFailure)  $default,) {final _that = this;
switch (_that) {
case _AccountState():
return $default(_that.status,_that.cuentas,_that.seleccionada,_that.movimientos,_that.nextCursor,_that.cargandoMovimientos,_that.loadingMore,_that.refreshing,_that.refreshFailed,_that.failure,_that.renaming,_that.renameFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccountStatus status,  List<Account> cuentas,  int seleccionada,  List<Movement> movimientos,  String? nextCursor,  bool cargandoMovimientos,  bool loadingMore,  bool refreshing,  bool refreshFailed,  AccountFailure? failure,  bool renaming,  AccountFailure? renameFailure)?  $default,) {final _that = this;
switch (_that) {
case _AccountState() when $default != null:
return $default(_that.status,_that.cuentas,_that.seleccionada,_that.movimientos,_that.nextCursor,_that.cargandoMovimientos,_that.loadingMore,_that.refreshing,_that.refreshFailed,_that.failure,_that.renaming,_that.renameFailure);case _:
  return null;

}
}

}

/// @nodoc


class _AccountState extends AccountState {
  const _AccountState({this.status = AccountStatus.loading, final  List<Account> cuentas = const <Account>[], this.seleccionada = 0, final  List<Movement> movimientos = const <Movement>[], this.nextCursor, this.cargandoMovimientos = false, this.loadingMore = false, this.refreshing = false, this.refreshFailed = false, this.failure, this.renaming = false, this.renameFailure}): _cuentas = cuentas,_movimientos = movimientos,super._();
  

@override@JsonKey() final  AccountStatus status;
/// Todas las cuentas del titular, en el orden del servidor.
 final  List<Account> _cuentas;
/// Todas las cuentas del titular, en el orden del servidor.
@override@JsonKey() List<Account> get cuentas {
  if (_cuentas is EqualUnmodifiableListView) return _cuentas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cuentas);
}

/// Índice en [cuentas] de la que se ve en el carrusel.
@override@JsonKey() final  int seleccionada;
 final  List<Movement> _movimientos;
@override@JsonKey() List<Movement> get movimientos {
  if (_movimientos is EqualUnmodifiableListView) return _movimientos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_movimientos);
}

/// Cursor opaco de la siguiente página; `null` = no hay más.
@override final  String? nextCursor;
/// Llega la primera página de la cuenta recién elegida en el carrusel: la
/// lista está vacía porque aún no llegó, no porque no haya movimientos.
@override@JsonKey() final  bool cargandoMovimientos;
/// Pidiendo la página siguiente (scroll). Solo paginación.
@override@JsonKey() final  bool loadingMore;
@override@JsonKey() final  bool refreshing;
/// El último refresco falló y lo que se ve son datos anteriores.
@override@JsonKey() final  bool refreshFailed;
/// Solo con `status == error`.
@override final  AccountFailure? failure;
/// Hay un cambio de nombre en vuelo.
@override@JsonKey() final  bool renaming;
/// El último cambio de nombre falló; `null` si salió bien o no hubo.
@override final  AccountFailure? renameFailure;

/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountStateCopyWith<_AccountState> get copyWith => __$AccountStateCopyWithImpl<_AccountState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._cuentas, _cuentas)&&(identical(other.seleccionada, seleccionada) || other.seleccionada == seleccionada)&&const DeepCollectionEquality().equals(other._movimientos, _movimientos)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.cargandoMovimientos, cargandoMovimientos) || other.cargandoMovimientos == cargandoMovimientos)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.refreshFailed, refreshFailed) || other.refreshFailed == refreshFailed)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.renaming, renaming) || other.renaming == renaming)&&(identical(other.renameFailure, renameFailure) || other.renameFailure == renameFailure));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_cuentas),seleccionada,const DeepCollectionEquality().hash(_movimientos),nextCursor,cargandoMovimientos,loadingMore,refreshing,refreshFailed,failure,renaming,renameFailure);

@override
String toString() {
  return 'AccountState(status: $status, cuentas: $cuentas, seleccionada: $seleccionada, movimientos: $movimientos, nextCursor: $nextCursor, cargandoMovimientos: $cargandoMovimientos, loadingMore: $loadingMore, refreshing: $refreshing, refreshFailed: $refreshFailed, failure: $failure, renaming: $renaming, renameFailure: $renameFailure)';
}


}

/// @nodoc
abstract mixin class _$AccountStateCopyWith<$Res> implements $AccountStateCopyWith<$Res> {
  factory _$AccountStateCopyWith(_AccountState value, $Res Function(_AccountState) _then) = __$AccountStateCopyWithImpl;
@override @useResult
$Res call({
 AccountStatus status, List<Account> cuentas, int seleccionada, List<Movement> movimientos, String? nextCursor, bool cargandoMovimientos, bool loadingMore, bool refreshing, bool refreshFailed, AccountFailure? failure, bool renaming, AccountFailure? renameFailure
});




}
/// @nodoc
class __$AccountStateCopyWithImpl<$Res>
    implements _$AccountStateCopyWith<$Res> {
  __$AccountStateCopyWithImpl(this._self, this._then);

  final _AccountState _self;
  final $Res Function(_AccountState) _then;

/// Create a copy of AccountState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? cuentas = null,Object? seleccionada = null,Object? movimientos = null,Object? nextCursor = freezed,Object? cargandoMovimientos = null,Object? loadingMore = null,Object? refreshing = null,Object? refreshFailed = null,Object? failure = freezed,Object? renaming = null,Object? renameFailure = freezed,}) {
  return _then(_AccountState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountStatus,cuentas: null == cuentas ? _self._cuentas : cuentas // ignore: cast_nullable_to_non_nullable
as List<Account>,seleccionada: null == seleccionada ? _self.seleccionada : seleccionada // ignore: cast_nullable_to_non_nullable
as int,movimientos: null == movimientos ? _self._movimientos : movimientos // ignore: cast_nullable_to_non_nullable
as List<Movement>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,cargandoMovimientos: null == cargandoMovimientos ? _self.cargandoMovimientos : cargandoMovimientos // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshFailed: null == refreshFailed ? _self.refreshFailed : refreshFailed // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,renaming: null == renaming ? _self.renaming : renaming // ignore: cast_nullable_to_non_nullable
as bool,renameFailure: freezed == renameFailure ? _self.renameFailure : renameFailure // ignore: cast_nullable_to_non_nullable
as AccountFailure?,
  ));
}


}

// dart format on
