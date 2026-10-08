import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart' show AuthError;
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'register_test_support.dart';

/// El alta exige el ticket del KYC: es el servidor, no la app, el que decide
/// si la identidad se verificó.
void main() {
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  RegisterBloc build(MemoryAuthRepository repo) => RegisterBloc(
        AuthActions(repo),
        biometric: biometricParaTests(),
        kyc: kycParaTests(),
      );

  /// Borrador completo, en el paso del PIN, listo para enviar.
  RegisterState listo({String? ticket}) => RegisterState(
        step: 3,
        securityStep: SecurityStep.biometria,
        draft: RegisterDraft(
          dni: '12345678',
          nombres: 'Juan',
          apellidos: 'Pérez',
          email: 'juan@correo.com',
          pin: '024689',
          confirmPin: '024689',
          faceStatus: FaceScanStatus.success,
          kycTicket: ticket,
        ),
      );

  test('el rostro aprobado guarda el ticket del servidor', () async {
    final bloc = build(MemoryAuthRepository());
    addTearDown(bloc.close);

    bloc.add(const RegisterEvent.faceScanCompleted(kycTicket: 't-1'));
    await settle();

    expect(bloc.state.draft.faceStatus, FaceScanStatus.success);
    expect(bloc.state.draft.kycTicket, 't-1');
  });

  test('con ticket, el alta exigente pasa', () async {
    final bloc = build(MemoryAuthRepository(kycRequired: true))
      ..emit(listo(ticket: 't-1'));
    addTearDown(bloc.close);

    bloc.add(const RegisterEvent.submitted());
    await settle();

    expect(bloc.state.createdSession, isNotNull);
  });

  test('sin ticket, el servidor rechaza y se vuelve al paso del rostro',
      () async {
    final bloc = build(MemoryAuthRepository(kycRequired: true))
      ..emit(listo());
    addTearDown(bloc.close);

    bloc.add(const RegisterEvent.submitted());
    await settle();

    expect(bloc.state.createdSession, isNull);
    expect(bloc.state.submitError, AuthError.identityNotVerified);
    expect(bloc.state.step, 2);
    expect(bloc.state.draft.faceStatus, FaceScanStatus.idle);
    expect(bloc.state.draft.kycTicket, isNull);
  });
}
