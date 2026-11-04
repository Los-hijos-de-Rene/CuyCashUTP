import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/kyc/application/kyc_actions.dart';
import 'package:cuycash/feature/kyc/infrastructure/memory_kyc_repository.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/presentation/kyc/widgets/slow_wait_hint.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('abrir el registro precalienta el KYC una vez', () async {
    final estado = MemorySecurityState.demo(clock: DateTime.now);
    final kyc = MemoryKycRepository(clock: DateTime.now);
    final bloc = RegisterBloc(
      AuthActions(MemoryAuthRepository(security: estado)),
      biometric: EnableBiometricUseCase(
        repo: MemorySecurityRepository(estado, clock: DateTime.now),
        gate: MemoryBiometricGate(),
        store: MemoryDeviceStore(),
      ),
      kyc: KycActions(kyc),
    );
    addTearDown(bloc.close);

    expect(kyc.warmUpCalls, 1);
  });

  testWidgets('el aviso de espera larga solo aparece pasado el plazo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SlowWaitHint(message: 'Despertando', color: Colors.black),
      ),
    );

    expect(find.text('Despertando'), findsNothing);
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('Despertando'), findsOneWidget);
  });
}
