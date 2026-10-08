// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liveness_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LivenessEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LivenessEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LivenessEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LivenessEvent()';
}


}

/// @nodoc
class $LivenessEventCopyWith<$Res>  {
$LivenessEventCopyWith(LivenessEvent _, $Res Function(LivenessEvent) __);
}


/// Adds pattern-matching-related methods to [LivenessEvent].
extension LivenessEventPatterns on LivenessEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LivenessStarted value)?  started,TResult Function( LivenessObserved value)?  observed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LivenessStarted() when started != null:
return started(_that);case LivenessObserved() when observed != null:
return observed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LivenessStarted value)  started,required TResult Function( LivenessObserved value)  observed,}){
final _that = this;
switch (_that) {
case LivenessStarted():
return started(_that);case LivenessObserved():
return observed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LivenessStarted value)?  started,TResult? Function( LivenessObserved value)?  observed,}){
final _that = this;
switch (_that) {
case LivenessStarted() when started != null:
return started(_that);case LivenessObserved() when observed != null:
return observed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( FaceObservation observation)?  observed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LivenessStarted() when started != null:
return started();case LivenessObserved() when observed != null:
return observed(_that.observation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( FaceObservation observation)  observed,}) {final _that = this;
switch (_that) {
case LivenessStarted():
return started();case LivenessObserved():
return observed(_that.observation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( FaceObservation observation)?  observed,}) {final _that = this;
switch (_that) {
case LivenessStarted() when started != null:
return started();case LivenessObserved() when observed != null:
return observed(_that.observation);case _:
  return null;

}
}

}

/// @nodoc


class LivenessStarted with DiagnosticableTreeMixin implements LivenessEvent {
  const LivenessStarted();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LivenessEvent.started'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LivenessStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LivenessEvent.started()';
}


}




/// @nodoc


class LivenessObserved with DiagnosticableTreeMixin implements LivenessEvent {
  const LivenessObserved(this.observation);
  

 final  FaceObservation observation;

/// Create a copy of LivenessEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LivenessObservedCopyWith<LivenessObserved> get copyWith => _$LivenessObservedCopyWithImpl<LivenessObserved>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LivenessEvent.observed'))
    ..add(DiagnosticsProperty('observation', observation));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LivenessObserved&&(identical(other.observation, observation) || other.observation == observation));
}


@override
int get hashCode => Object.hash(runtimeType,observation);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LivenessEvent.observed(observation: $observation)';
}


}

/// @nodoc
abstract mixin class $LivenessObservedCopyWith<$Res> implements $LivenessEventCopyWith<$Res> {
  factory $LivenessObservedCopyWith(LivenessObserved value, $Res Function(LivenessObserved) _then) = _$LivenessObservedCopyWithImpl;
@useResult
$Res call({
 FaceObservation observation
});




}
/// @nodoc
class _$LivenessObservedCopyWithImpl<$Res>
    implements $LivenessObservedCopyWith<$Res> {
  _$LivenessObservedCopyWithImpl(this._self, this._then);

  final LivenessObserved _self;
  final $Res Function(LivenessObserved) _then;

/// Create a copy of LivenessEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? observation = null,}) {
  return _then(LivenessObserved(
null == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as FaceObservation,
  ));
}


}

/// @nodoc
mixin _$LivenessState implements DiagnosticableTreeMixin {

 LivenessPhase get phase;/// Tareas en el orden que impuso el servidor.
 List<LivenessStep> get steps;/// Índice de la tarea pendiente.
 int get currentIndex;/// Qué corregir del encuadre ahora mismo (null = está bien).
 FramingIssue? get framing;/// El gesto lleva rato sin completarse: sugerir hacerlo más marcado.
 bool get slow; LivenessError? get error; KycVerification? get verification;
/// Create a copy of LivenessState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LivenessStateCopyWith<LivenessState> get copyWith => _$LivenessStateCopyWithImpl<LivenessState>(this as LivenessState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LivenessState'))
    ..add(DiagnosticsProperty('phase', phase))..add(DiagnosticsProperty('steps', steps))..add(DiagnosticsProperty('currentIndex', currentIndex))..add(DiagnosticsProperty('framing', framing))..add(DiagnosticsProperty('slow', slow))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('verification', verification));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LivenessState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.framing, framing) || other.framing == framing)&&(identical(other.slow, slow) || other.slow == slow)&&(identical(other.error, error) || other.error == error)&&(identical(other.verification, verification) || other.verification == verification));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(steps),currentIndex,framing,slow,error,verification);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LivenessState(phase: $phase, steps: $steps, currentIndex: $currentIndex, framing: $framing, slow: $slow, error: $error, verification: $verification)';
}


}

/// @nodoc
abstract mixin class $LivenessStateCopyWith<$Res>  {
  factory $LivenessStateCopyWith(LivenessState value, $Res Function(LivenessState) _then) = _$LivenessStateCopyWithImpl;
@useResult
$Res call({
 LivenessPhase phase, List<LivenessStep> steps, int currentIndex, FramingIssue? framing, bool slow, LivenessError? error, KycVerification? verification
});




}
/// @nodoc
class _$LivenessStateCopyWithImpl<$Res>
    implements $LivenessStateCopyWith<$Res> {
  _$LivenessStateCopyWithImpl(this._self, this._then);

  final LivenessState _self;
  final $Res Function(LivenessState) _then;

/// Create a copy of LivenessState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? steps = null,Object? currentIndex = null,Object? framing = freezed,Object? slow = null,Object? error = freezed,Object? verification = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivenessPhase,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<LivenessStep>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,framing: freezed == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as FramingIssue?,slow: null == slow ? _self.slow : slow // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as LivenessError?,verification: freezed == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as KycVerification?,
  ));
}

}


/// Adds pattern-matching-related methods to [LivenessState].
extension LivenessStatePatterns on LivenessState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LivenessState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LivenessState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LivenessState value)  $default,){
final _that = this;
switch (_that) {
case _LivenessState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LivenessState value)?  $default,){
final _that = this;
switch (_that) {
case _LivenessState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LivenessPhase phase,  List<LivenessStep> steps,  int currentIndex,  FramingIssue? framing,  bool slow,  LivenessError? error,  KycVerification? verification)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LivenessState() when $default != null:
return $default(_that.phase,_that.steps,_that.currentIndex,_that.framing,_that.slow,_that.error,_that.verification);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LivenessPhase phase,  List<LivenessStep> steps,  int currentIndex,  FramingIssue? framing,  bool slow,  LivenessError? error,  KycVerification? verification)  $default,) {final _that = this;
switch (_that) {
case _LivenessState():
return $default(_that.phase,_that.steps,_that.currentIndex,_that.framing,_that.slow,_that.error,_that.verification);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LivenessPhase phase,  List<LivenessStep> steps,  int currentIndex,  FramingIssue? framing,  bool slow,  LivenessError? error,  KycVerification? verification)?  $default,) {final _that = this;
switch (_that) {
case _LivenessState() when $default != null:
return $default(_that.phase,_that.steps,_that.currentIndex,_that.framing,_that.slow,_that.error,_that.verification);case _:
  return null;

}
}

}

/// @nodoc


class _LivenessState extends LivenessState with DiagnosticableTreeMixin {
  const _LivenessState({this.phase = LivenessPhase.preparing, final  List<LivenessStep> steps = const <LivenessStep>[], this.currentIndex = 0, this.framing, this.slow = false, this.error, this.verification}): _steps = steps,super._();
  

@override@JsonKey() final  LivenessPhase phase;
/// Tareas en el orden que impuso el servidor.
 final  List<LivenessStep> _steps;
/// Tareas en el orden que impuso el servidor.
@override@JsonKey() List<LivenessStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

/// Índice de la tarea pendiente.
@override@JsonKey() final  int currentIndex;
/// Qué corregir del encuadre ahora mismo (null = está bien).
@override final  FramingIssue? framing;
/// El gesto lleva rato sin completarse: sugerir hacerlo más marcado.
@override@JsonKey() final  bool slow;
@override final  LivenessError? error;
@override final  KycVerification? verification;

/// Create a copy of LivenessState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LivenessStateCopyWith<_LivenessState> get copyWith => __$LivenessStateCopyWithImpl<_LivenessState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LivenessState'))
    ..add(DiagnosticsProperty('phase', phase))..add(DiagnosticsProperty('steps', steps))..add(DiagnosticsProperty('currentIndex', currentIndex))..add(DiagnosticsProperty('framing', framing))..add(DiagnosticsProperty('slow', slow))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('verification', verification));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LivenessState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.framing, framing) || other.framing == framing)&&(identical(other.slow, slow) || other.slow == slow)&&(identical(other.error, error) || other.error == error)&&(identical(other.verification, verification) || other.verification == verification));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(_steps),currentIndex,framing,slow,error,verification);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LivenessState(phase: $phase, steps: $steps, currentIndex: $currentIndex, framing: $framing, slow: $slow, error: $error, verification: $verification)';
}


}

/// @nodoc
abstract mixin class _$LivenessStateCopyWith<$Res> implements $LivenessStateCopyWith<$Res> {
  factory _$LivenessStateCopyWith(_LivenessState value, $Res Function(_LivenessState) _then) = __$LivenessStateCopyWithImpl;
@override @useResult
$Res call({
 LivenessPhase phase, List<LivenessStep> steps, int currentIndex, FramingIssue? framing, bool slow, LivenessError? error, KycVerification? verification
});




}
/// @nodoc
class __$LivenessStateCopyWithImpl<$Res>
    implements _$LivenessStateCopyWith<$Res> {
  __$LivenessStateCopyWithImpl(this._self, this._then);

  final _LivenessState _self;
  final $Res Function(_LivenessState) _then;

/// Create a copy of LivenessState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? steps = null,Object? currentIndex = null,Object? framing = freezed,Object? slow = null,Object? error = freezed,Object? verification = freezed,}) {
  return _then(_LivenessState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivenessPhase,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<LivenessStep>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,framing: freezed == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as FramingIssue?,slow: null == slow ? _self.slow : slow // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as LivenessError?,verification: freezed == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as KycVerification?,
  ));
}


}

// dart format on
