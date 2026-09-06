import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';
import '../../auth/bloc/auth_bloc.dart' show AuthError;

part 'register_bloc.freezed.dart';
part 'register_event.dart';
part 'register_state.dart';

/// Validadores puros del wizard (testeables sin bloc).
abstract final class RegisterValidators {
  static final _dni = RegExp(r'^\d{8}$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _pin = RegExp(r'^\d{6}$');

  static bool dataValid(RegisterDraft draft) =>
      dniError(draft.dni) == null &&
      requiredError(draft.nombres) == null &&
      requiredError(draft.apellidos) == null &&
      emailError(draft.email) == null;

  static FieldError? dniError(String value) =>
      _dni.hasMatch(value.trim()) ? null : FieldError.dniLength;

  static FieldError? requiredError(String value) =>
      value.trim().isEmpty ? FieldError.requiredField : null;

  static FieldError? emailError(String value) =>
      _email.hasMatch(value.trim()) ? null : FieldError.emailInvalid;

  /// PIN válido: 6 dígitos, no todos iguales, no secuencia trivial ascendente
  /// o descendente (123456 / 654321).
  static bool pinValid(String pin) {
    if (!_pin.hasMatch(pin)) return false;
    if (pin.split('').toSet().length == 1) return false; // 000000
    const asc = '0123456789';
    const desc = '9876543210';
    if (asc.contains(pin) || desc.contains(pin)) return false;
    return true;
  }
}

/// Bloc del wizard de registro. Consume `AuthActions` por constructor. En el
/// submit final NO navega: la sesión llega por el stream de auth y el gate del
/// router lleva a /home.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc(AuthActions actions)
      : _actions = actions,
        super(const RegisterState()) {
    on<RegisterFieldChanged>(_onFieldChanged);
    on<RegisterCaptured>((event, emit) => emit(_setSide(event.side, CaptureStatus.captured)));
    on<RegisterCaptureFailed>((event, emit) => emit(_setSide(event.side, CaptureStatus.unreadable)));
    on<RegisterFaceScanStarted>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(faceStatus: FaceScanStatus.scanning))));
    on<RegisterFaceScanCompleted>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(faceStatus: FaceScanStatus.success))));
    on<RegisterPinChanged>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(pin: event.pin), submitError: null)));
    on<RegisterBiometricToggled>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(biometricEnabled: event.value))));
    on<RegisterStepAdvanced>(_onStepAdvanced);
    on<RegisterStepBack>((event, emit) {
      if (state.step > 0) emit(state.copyWith(step: state.step - 1));
    });
    on<RegisterSubmitted>(_onSubmitted);
  }

  final AuthActions _actions;

  RegisterState _setSide(DocSide side, CaptureStatus status) => state.copyWith(
        draft: side == DocSide.front
            ? state.draft.copyWith(dniFront: status)
            : state.draft.copyWith(dniBack: status),
      );

  void _onFieldChanged(RegisterFieldChanged event, Emitter<RegisterState> emit) {
    final draft = switch (event.field) {
      RegisterField.dni => state.draft.copyWith(dni: event.value),
      RegisterField.nombres => state.draft.copyWith(nombres: event.value),
      RegisterField.apellidos => state.draft.copyWith(apellidos: event.value),
      RegisterField.email => state.draft.copyWith(email: event.value),
    };
    // Recalcula errores solo si ya se mostró el banner (no molesta al tipear
    // la primera vez), o para limpiar un error del campo tocado.
    final errors = state.errors.showBanner
        ? _validateAll(draft)
        : state.errors.copyWith(
            dni: event.field == RegisterField.dni ? null : state.errors.dni,
            nombres: event.field == RegisterField.nombres ? null : state.errors.nombres,
            apellidos: event.field == RegisterField.apellidos ? null : state.errors.apellidos,
            email: event.field == RegisterField.email ? null : state.errors.email,
          );
    emit(state.copyWith(draft: draft, errors: errors));
  }

  RegisterErrors _validateAll(RegisterDraft draft) => RegisterErrors(
        dni: RegisterValidators.dniError(draft.dni),
        nombres: RegisterValidators.requiredError(draft.nombres),
        apellidos: RegisterValidators.requiredError(draft.apellidos),
        email: RegisterValidators.emailError(draft.email),
        showBanner: true,
      );

  void _onStepAdvanced(RegisterStepAdvanced event, Emitter<RegisterState> emit) {
    if (state.step == 0 && !RegisterValidators.dataValid(state.draft)) {
      emit(state.copyWith(errors: _validateAll(state.draft)));
      return;
    }
    if (!state.canAdvance) return;
    if (state.step < 3) emit(state.copyWith(step: state.step + 1));
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (!RegisterValidators.pinValid(state.draft.pin)) return;
    emit(state.copyWith(status: RegisterStatus.submitting, submitError: null));
    final result = await _actions.register(
      dni: state.draft.dni,
      nombres: state.draft.nombres,
      apellidos: state.draft.apellidos,
      email: state.draft.email,
      pin: state.draft.pin,
    );
    result.match(
      (failure) => emit(state.copyWith(
          status: RegisterStatus.editing, submitError: _errorFor(failure))),
      (_) => emit(
          state.copyWith(status: RegisterStatus.editing)), // éxito → sesión por el stream → AuthBloc → gate → /home
    );
  }

  AuthError _errorFor(GlobalFailure<AuthFailure> failure) => switch (failure) {
        ServerFailure(failure: IdentifierTaken()) => AuthError.identifierTaken,
        ServerFailure(failure: WeakPin()) => AuthError.weakPin,
        _ => AuthError.generic,
      };
}
