import 'dart:async';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';
import '../../../feature/auth/domain/auth_session.dart';
import '../../../feature/auth/domain/pin_rules.dart';
import '../../auth/bloc/auth_bloc.dart' show AuthError;

part 'register_bloc.freezed.dart';
part 'register_event.dart';
part 'register_state.dart';

/// Validadores puros del wizard (testeables sin bloc).
abstract final class RegisterValidators {
  static final _dni = RegExp(r'^\d{8}$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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

  // Las reglas del PIN viven en `PinRules`; aquí solo se delegan.
  static bool hasSixDigits(String pin) => PinRules.hasSixDigits(pin);
  static bool hasNoRepeatedDigit(String pin) =>
      PinRules.hasNoRepeatedDigit(pin);
  static bool hasNoSequence(String pin) => PinRules.hasNoSequence(pin);
  static bool pinValid(String pin) => PinRules.isValid(pin);
}

/// Bloc del wizard de registro. Consume `AuthActions` por constructor. En el
/// submit final NO navega: la sesión llega por el stream de auth y el gate del
/// router lleva a /home.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc(AuthActions actions)
      : _actions = actions,
        super(const RegisterState()) {
    on<RegisterFieldChanged>(_onFieldChanged);
    on<RegisterCaptured>((event, emit) =>
        emit(_setSide(event.side, CaptureStatus.captured, event.image)));
    on<RegisterCaptureFailed>((event, emit) => emit(_setSide(event.side, CaptureStatus.unreadable)));
    on<RegisterFaceScanStarted>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(faceStatus: FaceScanStatus.scanning))));
    on<RegisterFaceScanCompleted>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(faceStatus: FaceScanStatus.success))));
    on<RegisterPinDigitPressed>(_onPinDigit);
    on<RegisterPinBackspace>(_onPinBackspace);
    on<RegisterBiometricToggled>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(biometricEnabled: event.value))));
    on<RegisterStepAdvanced>(_onStepAdvanced);
    on<RegisterStepBack>(_onStepBack);
    on<RegisterSubmitted>(_onSubmitted);
    on<RegisterAccountOpened>((event, emit) async {
      final session = state.createdSession;
      if (session == null) return;
      // El resultado SÍ se mira: antes se descartaba, y una activación
      // imposible dejaba el botón muerto sin éxito ni error.
      final resultado = await _actions.activate(session);
      resultado.match(
        (failure) => emit(state.copyWith(submitError: _errorFor(failure))),
        (_) => null,
      );
    });
  }

  final AuthActions _actions;

  /// Escribe en el grupo activo. Al sexto dígito, cada subpaso decide solo:
  /// crear valida las reglas y pasa a confirmar; confirmar compara y pasa a
  /// biometría. No hay botón que tocar.
  void _onPinDigit(RegisterPinDigitPressed event, Emitter<RegisterState> emit) {
    if (state.status == RegisterStatus.submitting) return;
    switch (state.securityStep) {
      case SecurityStep.crear:
        if (state.draft.pin.length >= 6) return;
        final pin = '${state.draft.pin}${event.digit}';
        final next = state.copyWith(
            draft: state.draft.copyWith(pin: pin),
            pinMismatch: false,
            submitError: null);
        // Con seis dígitos que incumplen una regla NO se avanza: la checklist
        // ya dice cuál falta y el usuario corrige ahí mismo.
        emit(pin.length == 6 && RegisterValidators.pinValid(pin)
            ? next.copyWith(securityStep: SecurityStep.confirmar)
            : next);
      case SecurityStep.confirmar:
        if (state.draft.confirmPin.length >= 6) return;
        final confirm = '${state.draft.confirmPin}${event.digit}';
        if (confirm.length < 6) {
          emit(state.copyWith(
              draft: state.draft.copyWith(confirmPin: confirm),
              pinMismatch: false));
          return;
        }
        if (confirm == state.draft.pin) {
          emit(state.copyWith(
            draft: state.draft.copyWith(confirmPin: confirm),
            securityStep: SecurityStep.biometria,
            pinMismatch: false,
          ));
        } else {
          // Se limpia SOLO la confirmación; el PIN elegido se conserva.
          emit(state.copyWith(
            draft: state.draft.copyWith(confirmPin: ''),
            pinMismatch: true,
          ));
        }
      case SecurityStep.biometria:
        return;
    }
  }

  void _onPinBackspace(
    RegisterPinBackspace event,
    Emitter<RegisterState> emit,
  ) {
    if (state.status == RegisterStatus.submitting) return;
    switch (state.securityStep) {
      case SecurityStep.crear:
        final pin = state.draft.pin;
        if (pin.isEmpty) return;
        emit(state.copyWith(
            draft: state.draft.copyWith(pin: pin.substring(0, pin.length - 1)),
            pinMismatch: false));
      case SecurityStep.confirmar:
        final confirm = state.draft.confirmPin;
        if (confirm.isEmpty) return;
        emit(state.copyWith(
            draft: state.draft
                .copyWith(confirmPin: confirm.substring(0, confirm.length - 1)),
            pinMismatch: false));
      case SecurityStep.biometria:
        return;
    }
  }

  /// Atrás dentro del paso 4 retrocede de subpaso; solo desde `crear` sale al
  /// paso anterior del wizard.
  void _onStepBack(RegisterStepBack event, Emitter<RegisterState> emit) {
    if (state.step == 3 && state.securityStep != SecurityStep.crear) {
      emit(state.copyWith(
        securityStep: switch (state.securityStep) {
          SecurityStep.biometria => SecurityStep.confirmar,
          _ => SecurityStep.crear,
        },
        // Volver deja las casillas del subpaso vacías: se reescriben.
        draft: state.draft.copyWith(
          confirmPin: '',
          pin: state.securityStep == SecurityStep.confirmar
              ? ''
              : state.draft.pin,
        ),
        pinMismatch: false,
      ));
      return;
    }
    if (state.step > 0) emit(state.copyWith(step: state.step - 1));
  }

  RegisterState _setSide(DocSide side, CaptureStatus status,
          [Uint8List? image]) =>
      state.copyWith(
        draft: side == DocSide.front
            ? state.draft.copyWith(dniFront: status, dniFrontImage: image)
            : state.draft.copyWith(dniBack: status, dniBackImage: image),
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
      (session) => emit(state.copyWith(
          status: RegisterStatus.editing,
          createdSession: session)), // éxito → pantalla de éxito (aún sin login)
    );
  }

  AuthError _errorFor(GlobalFailure<AuthFailure> failure) => switch (failure) {
        ServerFailure(failure: IdentifierTaken()) => AuthError.identifierTaken,
        ServerFailure(failure: WeakPin()) => AuthError.weakPin,
        _ => AuthError.generic,
      };
}
