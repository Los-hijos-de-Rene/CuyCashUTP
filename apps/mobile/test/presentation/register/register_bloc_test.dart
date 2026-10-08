import 'register_test_support.dart';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// PIN del alta en los tests de huella: `000000` no pasa `PinRules`.
const _pinAlta = '839201';

late MemorySecurityState estado;
late MemoryDeviceStore store;
late MemoryBiometricGate gate;
late MemoryAuthRepository auth;

EnableBiometricUseCase _biometric() => EnableBiometricUseCase(
  repo: MemorySecurityRepository(estado, clock: DateTime.now),
  gate: gate,
  store: store,
);

RegisterBloc build([MemoryAuthRepository? repo]) => RegisterBloc(
  AuthActions(repo ?? MemoryAuthRepository()),
  biometric: _biometric(),
  kyc: kycParaTests(),
);

RegisterBloc construirBloc() =>
    RegisterBloc(AuthActions(auth), biometric: _biometric(), kyc: kycParaTests());

/// Datos, PIN y envío: deja la cuenta creada pero sin activar.
Future<void> recorrerHastaCrearCuenta(
  RegisterBloc b, {
  required String pin,
}) async {
  b.add(const RegisterEvent.fieldChanged(RegisterField.dni, '87654321'));
  b.add(const RegisterEvent.fieldChanged(RegisterField.nombres, 'Juan'));
  b.add(const RegisterEvent.fieldChanged(RegisterField.apellidos, 'Pérez'));
  b.add(const RegisterEvent.fieldChanged(RegisterField.email, 'j@p.pe'));
  for (final d in pin.split('')) {
    b.add(RegisterEvent.pinDigitPressed(int.parse(d)));
  }
  b.add(const RegisterEvent.submitted());
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  setUp(() {
    estado = MemorySecurityState.demo(clock: DateTime.now, pin: _pinAlta);
    store = MemoryDeviceStore();
    gate = MemoryBiometricGate();
    auth = MemoryAuthRepository(security: estado);
  });

  group('validadores', () {
    test('DNI 8 dígitos', () {
      expect(RegisterValidators.dniError('12345678'), isNull);
      expect(RegisterValidators.dniError('1234'), FieldError.dniLength);
    });
    test('email', () {
      expect(RegisterValidators.emailError('a@b.pe'), isNull);
      expect(RegisterValidators.emailError('nope'), FieldError.emailInvalid);
    });
    test('pin 6 sin secuencia', () {
      expect(RegisterValidators.pinValid('024689'), isTrue);
      expect(RegisterValidators.pinValid('12345'), isFalse);
      expect(RegisterValidators.pinValid('123456'), isFalse);
      expect(RegisterValidators.pinValid('000000'), isFalse);
    });
  });

  blocTest<RegisterBloc, RegisterState>(
    'avanzar en paso 0 con datos inválidos marca errores y no avanza',
    build: build,
    act: (b) => b.add(const RegisterEvent.stepAdvanced()),
    verify: (b) {
      expect(b.state.step, 0);
      expect(b.state.errors.showBanner, isTrue);
      expect(b.state.errors.count, 4);
    },
  );

  blocTest<RegisterBloc, RegisterState>(
    'datos válidos → avanza a paso 1',
    build: build,
    act: (b) => b
      ..add(const RegisterEvent.fieldChanged(RegisterField.dni, '12345678'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.nombres, 'Juan'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.apellidos, 'Pérez'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.email, 'j@p.pe'))
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 1),
  );

  blocTest<RegisterBloc, RegisterState>(
    'captura front+back habilita avanzar a paso 2',
    build: build,
    seed: () => const RegisterState(step: 1),
    act: (b) => b
      ..add(RegisterEvent.captured(DocSide.front, Uint8List.fromList([1])))
      ..add(RegisterEvent.captured(DocSide.back, Uint8List.fromList([1])))
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 2),
  );

  blocTest<RegisterBloc, RegisterState>(
    'captura no legible no permite avanzar',
    build: build,
    seed: () => const RegisterState(step: 1),
    act: (b) => b
      ..add(RegisterEvent.captured(DocSide.front, Uint8List.fromList([1])))
      ..add(const RegisterEvent.captureFailed(DocSide.back))
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 1),
  );

  blocTest<RegisterBloc, RegisterState>(
    'face scan completado avanza a paso 3',
    build: build,
    seed: () => const RegisterState(step: 2),
    act: (b) => b
      ..add(const RegisterEvent.faceScanCompleted())
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 3),
  );

  blocTest<RegisterBloc, RegisterState>(
    'stepBack retrocede',
    build: build,
    seed: () => const RegisterState(step: 2),
    act: (b) => b.add(const RegisterEvent.stepBack()),
    verify: (b) => expect(b.state.step, 1),
  );

  blocTest<RegisterBloc, RegisterState>(
    'submit con PIN válido crea la cuenta (createdSession) sin autenticar aún',
    build: () {
      final repo = MemoryAuthRepository();
      return RegisterBloc(AuthActions(repo), biometric: _biometric(), kyc: kycParaTests());
    },
    seed: () => const RegisterState(
      step: 3,
      draft: RegisterDraft(
        dni: '87654321',
        nombres: 'Juan',
        apellidos: 'Pérez',
        email: 'j@p.pe',
        pin: '024689',
      ),
    ),
    act: (b) => b.add(const RegisterEvent.submitted()),
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.status, RegisterStatus.editing);
      expect(b.state.createdSession?.identifier, '87654321');
    },
  );

  test('accountOpened activa la sesión creada (repo.currentSession)', () async {
    final repo = MemoryAuthRepository();
    final bloc = RegisterBloc(AuthActions(repo), biometric: _biometric(), kyc: kycParaTests());
    addTearDown(bloc.close);
    bloc.add(const RegisterEvent.fieldChanged(RegisterField.dni, '87654321'));
    bloc.add(const RegisterEvent.fieldChanged(RegisterField.nombres, 'Juan'));
    bloc.add(
      const RegisterEvent.fieldChanged(RegisterField.apellidos, 'Pérez'),
    );
    bloc.add(const RegisterEvent.fieldChanged(RegisterField.email, 'j@p.pe'));
    for (final d in '024689'.split('')) {
      bloc.add(RegisterEvent.pinDigitPressed(int.parse(d)));
    }
    bloc.add(const RegisterEvent.submitted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.currentSession, isNull); // aún no autenticado
    bloc.add(const RegisterEvent.accountOpened(biometricReason: 'r'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.currentSession?.identifier, '87654321');
  });

  blocTest<RegisterBloc, RegisterState>(
    'submit con DNI duplicado → submitError identifierTaken',
    build: () {
      final repo = MemoryAuthRepository();
      // pre-registra el DNI
      repo.register(
        dni: '87654321',
        nombres: 'A',
        apellidos: 'B',
        email: 'a@b.pe',
        pin: '024689',
      );
      return RegisterBloc(AuthActions(repo), biometric: _biometric(), kyc: kycParaTests());
    },
    seed: () => const RegisterState(
      step: 3,
      draft: RegisterDraft(
        dni: '87654321',
        nombres: 'Juan',
        apellidos: 'Pérez',
        email: 'j@p.pe',
        pin: '135790',
      ),
    ),
    act: (b) => b.add(const RegisterEvent.submitted()),
    wait: const Duration(milliseconds: 10),
    verify: (b) => expect(b.state.submitError, AuthError.identifierTaken),
  );

  blocTest<RegisterBloc, RegisterState>(
    'sin sensor apaga la opción de huella',
    build: () {
      gate.available = false;
      return construirBloc();
    },
    act: (b) => b.add(const RegisterEvent.biometricChecked()),
    verify: (b) {
      expect(b.state.biometricAvailable, isFalse);
      expect(b.state.draft.biometricEnabled, isFalse);
    },
  );

  test('al abrir la cuenta con la huella encendida, la activa ANTES de abrir '
      'la sesión', () async {
    // Activar la sesión saca al usuario del registro (y cierra el bloc): la
    // huella tiene que quedar resuelta antes.
    final sesionAlGuardar = <Object?>[];
    store = _StoreEspia(() => sesionAlGuardar.add(auth.currentSession));
    final b = construirBloc()..add(const RegisterEvent.biometricChecked());
    await recorrerHastaCrearCuenta(b, pin: _pinAlta);

    b.add(const RegisterEvent.accountOpened(biometricReason: 'r'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(await store.readBiometricCredential(), isNotNull);
    expect(sesionAlGuardar, [isNull]);
    expect(auth.currentSession?.identifier, '87654321');
    expect(b.state.biometricEnrollFailed, isFalse);
    await b.close();
  });

  test('si activar la huella falla, avisa primero y abre la sesión cuando la '
      'pantalla confirma el aviso', () async {
    store.failCredentialWrites = true;
    final b = construirBloc()..add(const RegisterEvent.biometricChecked());
    await recorrerHastaCrearCuenta(b, pin: _pinAlta);

    b.add(const RegisterEvent.accountOpened(biometricReason: 'r'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // El aviso sale con la sesión aún cerrada: si se abriera, el router
    // dejaría el registro antes de mostrarlo.
    expect(b.state.biometricEnrollFailed, isTrue);
    expect(auth.currentSession, isNull);

    b.add(const RegisterEvent.biometricNoticeShown());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(auth.currentSession?.identifier, '87654321');
    await b.close();
  });

  test('un reintento tras el aviso no vuelve a pedir la huella', () async {
    store.failCredentialWrites = true;
    final b = construirBloc()..add(const RegisterEvent.biometricChecked());
    await recorrerHastaCrearCuenta(b, pin: _pinAlta);
    b.add(const RegisterEvent.accountOpened(biometricReason: 'r'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final pedidas = gate.prompts;

    b.add(const RegisterEvent.accountOpened(biometricReason: 'r'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(gate.prompts, pedidas);
    expect(auth.currentSession, isNotNull);
    await b.close();
  });
}

/// Store que avisa cuándo se guarda la credencial, para ver el orden.
class _StoreEspia extends MemoryDeviceStore {
  _StoreEspia(this._alGuardar);
  final void Function() _alGuardar;

  @override
  Future<bool> saveBiometricCredential(String credential) {
    _alGuardar();
    return super.saveBiometricCredential(credential);
  }
}
