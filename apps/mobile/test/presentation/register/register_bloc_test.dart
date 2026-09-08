import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

RegisterBloc build([MemoryAuthRepository? repo]) =>
    RegisterBloc(AuthActions(repo ?? MemoryAuthRepository()));

void main() {
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
      ..add(const RegisterEvent.captured(DocSide.front))
      ..add(const RegisterEvent.captured(DocSide.back))
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 2),
  );

  blocTest<RegisterBloc, RegisterState>(
    'captura no legible no permite avanzar',
    build: build,
    seed: () => const RegisterState(step: 1),
    act: (b) => b
      ..add(const RegisterEvent.captured(DocSide.front))
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
      return RegisterBloc(AuthActions(repo));
    },
    seed: () => const RegisterState(
      step: 3,
      draft: RegisterDraft(
        dni: '87654321', nombres: 'Juan', apellidos: 'Pérez',
        email: 'j@p.pe', pin: '024689',
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
    final bloc = RegisterBloc(AuthActions(repo));
    addTearDown(bloc.close);
    bloc.add(const RegisterEvent.fieldChanged(RegisterField.dni, '87654321'));
    bloc.add(const RegisterEvent.fieldChanged(RegisterField.nombres, 'Juan'));
    bloc.add(const RegisterEvent.fieldChanged(RegisterField.apellidos, 'Pérez'));
    bloc.add(const RegisterEvent.fieldChanged(RegisterField.email, 'j@p.pe'));
    for (final d in '024689'.split('')) {
      bloc.add(RegisterEvent.pinDigitPressed(int.parse(d)));
    }
    bloc.add(const RegisterEvent.submitted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.currentSession, isNull); // aún no autenticado
    bloc.add(const RegisterEvent.accountOpened());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.currentSession?.identifier, '87654321');
  });

  blocTest<RegisterBloc, RegisterState>(
    'submit con DNI duplicado → submitError identifierTaken',
    build: () {
      final repo = MemoryAuthRepository();
      // pre-registra el DNI
      repo.register(
          dni: '87654321', nombres: 'A', apellidos: 'B', email: 'a@b.pe', pin: '024689');
      return RegisterBloc(AuthActions(repo));
    },
    seed: () => const RegisterState(
      step: 3,
      draft: RegisterDraft(
        dni: '87654321', nombres: 'Juan', apellidos: 'Pérez',
        email: 'j@p.pe', pin: '135790',
      ),
    ),
    act: (b) => b.add(const RegisterEvent.submitted()),
    wait: const Duration(milliseconds: 10),
    verify: (b) => expect(b.state.submitError, AuthError.identifierTaken),
  );
}
