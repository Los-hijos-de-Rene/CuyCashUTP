import 'package:cuycash/feature/kyc/application/kyc_actions.dart';
import 'package:cuycash/feature/kyc/infrastructure/memory_kyc_repository.dart';
import 'package:cuycash/feature/biometric/infrastructure/memory_biometric_gate.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/security/application/enable_biometric_use_case.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';

/// Caso de uso de la huella con dobles en memoria, para construir el
/// `RegisterBloc` en los tests que no miran la huella.
EnableBiometricUseCase biometricParaTests() => EnableBiometricUseCase(
  repo: MemorySecurityRepository(
    MemorySecurityState.demo(clock: DateTime.now),
    clock: DateTime.now,
  ),
  gate: MemoryBiometricGate(),
  store: MemoryDeviceStore(),
);

/// KYC en memoria para el wizard. [documentDni] simula el DNI impreso en el
/// reverso; null = el que declare el usuario (el cotejo pasa).
KycActions kycParaTests({String? documentDni}) => KycActions(
      MemoryKycRepository(clock: DateTime.now, documentDni: documentDni),
    );
