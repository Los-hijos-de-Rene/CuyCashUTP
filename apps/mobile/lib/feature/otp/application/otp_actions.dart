import 'package:core_kernel/core_kernel.dart';
import '../domain/otp_challenge.dart';
import '../domain/otp_failure.dart';
import '../domain/otp_repository.dart';

/// Operaciones finas del OTP (delegación directa sobre el `OtpRepository`). El
/// bloc la consume por constructor; nunca toca el repo directo.
class OtpActions {
  const OtpActions(this._repo);

  final OtpRepository _repo;

  FutureResult<OtpFailure, OtpChallenge> request(String identifier) =>
      _repo.request(identifier);

  FutureResult<OtpFailure, String> verify({
    required String challengeId,
    required String code,
  }) =>
      _repo.verify(challengeId: challengeId, code: code);

  FutureResult<OtpFailure, OtpChallenge> resend(String challengeId) =>
      _repo.resend(challengeId);
}
