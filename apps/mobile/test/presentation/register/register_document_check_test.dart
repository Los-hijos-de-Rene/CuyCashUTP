import 'dart:typed_data';

import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/kyc/domain/document_check.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'register_test_support.dart';

void main() {
  final foto = Uint8List.fromList([1, 2, 3]);

  RegisterBloc build({String? documentDni}) => RegisterBloc(
    AuthActions(MemoryAuthRepository()),
    biometric: biometricParaTests(),
    kyc: kycParaTests(documentDni: documentDni),
  );

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<RegisterBloc> conDni(String dni, {String? documentDni}) async {
    final bloc = build(documentDni: documentDni)
      ..add(RegisterEvent.fieldChanged(RegisterField.dni, dni));
    await settle();
    return bloc;
  }

  test('una foto se revisa al tomarla y, si sirve, queda capturada', () async {
    final bloc = await conDni('12345678');
    addTearDown(bloc.close);

    bloc.add(RegisterEvent.captured(DocSide.front, foto));
    await settle();

    expect(bloc.state.draft.dniFront, CaptureStatus.captured);
    expect(bloc.state.draft.dniFrontIssue, isNull);
  });

  test('el reverso con el mismo DNI que se escribió, pasa', () async {
    final bloc = await conDni('12345678', documentDni: '12345678');
    addTearDown(bloc.close);

    bloc.add(RegisterEvent.captured(DocSide.back, foto));
    await settle();

    expect(bloc.state.draft.dniBack, CaptureStatus.captured);
  });

  test(
    'el reverso de OTRO DNI se rechaza con el motivo y no deja avanzar',
    () async {
      final bloc = await conDni('12345678', documentDni: '87654321');
      addTearDown(bloc.close);

      bloc
        ..add(RegisterEvent.captured(DocSide.front, foto))
        ..add(RegisterEvent.captured(DocSide.back, foto));
      await settle();

      expect(bloc.state.draft.dniBack, CaptureStatus.unreadable);
      expect(bloc.state.draft.dniBackIssue, DocumentIssue.dniMismatch);
      expect(bloc.state.copyWith(step: 1).canAdvance, isFalse);
    },
  );

  test('un frente de OTRO DNI se rechaza aunque el reverso coincida', () async {
    // El ataque: frente propio (su cara) + reverso del DNI de otra persona.
    // El simulado imprime en ambas caras [documentDni].
    final bloc = await conDni('12345678', documentDni: '87654321');
    addTearDown(bloc.close);

    bloc.add(RegisterEvent.captured(DocSide.front, foto));
    await settle();

    expect(bloc.state.draft.dniFront, CaptureStatus.unreadable);
    expect(bloc.state.draft.dniFrontIssue, DocumentIssue.frontDniMismatch);
  });

  test('una foto vacía del frente se rechaza como ilegible', () async {
    final bloc = await conDni('12345678');
    addTearDown(bloc.close);

    bloc.add(RegisterEvent.captured(DocSide.front, Uint8List(0)));
    await settle();

    expect(bloc.state.draft.dniFront, CaptureStatus.unreadable);
    expect(bloc.state.draft.dniFrontIssue, isNotNull);
  });

  test('mientras se revisa no se puede avanzar', () async {
    final bloc = await conDni('12345678');
    addTearDown(bloc.close);

    final vistos = <RegisterState>[];
    final sub = bloc.stream.listen(vistos.add);
    addTearDown(sub.cancel);

    bloc.add(RegisterEvent.captured(DocSide.front, foto));
    await settle();

    final revisando = vistos.where(
      (s) => s.draft.dniFront == CaptureStatus.checking,
    );
    expect(revisando, isNotEmpty, reason: 'pasa por "revisando"');
    expect(revisando.every((s) => !s.copyWith(step: 1).canAdvance), isTrue);
  });
}
