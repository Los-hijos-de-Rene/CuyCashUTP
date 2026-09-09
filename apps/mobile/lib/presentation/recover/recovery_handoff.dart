/// Lo que la pantalla del código le pasa a la de restablecer PIN.
///
/// Viajan juntos porque el backend exige los dos: el correo identifica la
/// cuenta y el ticket acredita que se pasó por el código. Mandar solo el correo
/// permitiría llegar a cambiar el PIN sin haberlo verificado.
class RecoveryHandoff {
  const RecoveryHandoff({required this.email, required this.otpTicket});

  final String email;
  final String otpTicket;
}
