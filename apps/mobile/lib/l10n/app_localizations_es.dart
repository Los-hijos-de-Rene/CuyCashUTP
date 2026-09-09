// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get successTitle => '¡Tu cuenta está activa!';

  @override
  String get successSubtitle =>
      'Ya puedes empezar a mover tu dinero con CuyCash.';

  @override
  String get successAliasLabel => 'Tu alias en CuyCash';

  @override
  String get successWalletLabel => 'Tu billetera';

  @override
  String get successIdentityVerified => 'Identidad verificada';

  @override
  String get successShareHint => 'Comparte tu alias para que te envíen dinero.';

  @override
  String get goToAccount => 'Ir a mi cuenta';

  @override
  String get shareMyAlias => 'Compartir mi alias';

  @override
  String get aliasCopied => 'Alias copiado';

  @override
  String shareAliasMessage(String alias) {
    return 'Envíame dinero a mi alias de CuyCash: $alias';
  }

  @override
  String get createAccount => 'Crear mi cuenta';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta? Iniciar sesión';

  @override
  String get onboardingTitle1 => 'Tu banco, sin colas ni papeles';

  @override
  String get onboardingBody1 =>
      'Abre tu cuenta en minutos validando tu DNI y tu rostro.';

  @override
  String get onboardingTitle2 => 'Envía y cobra en segundos';

  @override
  String get onboardingBody2 =>
      'Manda dinero a cualquier persona en CuyCash sin comisiones, o cobra mostrando tu código.';

  @override
  String get onboardingTitle3 => 'Recibe desde otras billeteras';

  @override
  String get onboardingBody3 =>
      'El dinero que te envían desde otras apps llega directo a tu billetera CuyCash.';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginHeadline => 'Bienvenido de vuelta';

  @override
  String get loginSubtitle => 'Ingresa tu número de DNI para continuar.';

  @override
  String get loginPinHeadline => 'Ingresa tu PIN';

  @override
  String get loginPinSubtitle => 'PIN de 6 dígitos de tu cuenta.';

  @override
  String loginDniSummary(String dni) {
    return 'DNI $dni';
  }

  @override
  String get changeAction => 'Cambiar';

  @override
  String get loginDniInvalid => 'El DNI debe tener 8 dígitos.';

  @override
  String loginWrongCredentials(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Los datos no son correctos. Te quedan $n intentos.',
      one: 'Los datos no son correctos. Te queda 1 intento.',
    );
    return '$_temp0';
  }

  @override
  String get identifierLabel => 'DNI o Alias';

  @override
  String get pinLabel => 'PIN de seguridad';

  @override
  String get loginCta => 'Ingresar';

  @override
  String get forgotPin => 'Olvidé mi PIN';

  @override
  String get goToRegister => '¿No tienes cuenta? Regístrate';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerHeadline => 'Empecemos por lo básico';

  @override
  String get dniLabel => 'DNI';

  @override
  String get registerCta => 'Continuar';

  @override
  String get goToLogin => '¿Ya tienes cuenta? Iniciar sesión';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get homePlaceholder => 'Tu billetera estará disponible muy pronto.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileIdentifierLabel => 'Tu identificador';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get navHome => 'Inicio';

  @override
  String get navProfile => 'Perfil';

  @override
  String get errorInvalidCredentials => 'DNI/Alias o PIN incorrectos.';

  @override
  String get errorIdentifierTaken => 'Este DNI ya está registrado.';

  @override
  String get errorWeakPin => 'El PIN debe tener 6 dígitos.';

  @override
  String get errorGeneric => 'Ocurrió un error. Intenta de nuevo.';

  @override
  String get registerFlowTitle => 'Crear cuenta';

  @override
  String get identityTitle => 'Verifica tu identidad';

  @override
  String get faceTitle => 'Reconocimiento facial';

  @override
  String get securityTitle => 'Protege tu cuenta';

  @override
  String stepData(int n) {
    return 'Paso $n de 4 · Datos';
  }

  @override
  String stepDocument(int n) {
    return 'Paso $n de 4 · Documento';
  }

  @override
  String stepFace(int n) {
    return 'Paso $n de 4 · Rostro';
  }

  @override
  String stepSecurity(int n) {
    return 'Paso $n de 4 · Seguridad';
  }

  @override
  String get dataHeadline => 'Empecemos por ti';

  @override
  String get dataSubtitle => 'Ingresa tus datos tal como figuran en tu DNI.';

  @override
  String get dniFieldLabel => 'Número de DNI';

  @override
  String get dniHint => '12345678';

  @override
  String get dniHelper => '8 dígitos';

  @override
  String get nombresLabel => 'Nombres';

  @override
  String get nombresHint => 'Ej. Juan Carlos';

  @override
  String get apellidosLabel => 'Apellidos';

  @override
  String get apellidosHint => 'Ej. Pérez García';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailHint => 'ejemplo@correo.com';

  @override
  String get emailHelper =>
      'Aquí te enviaremos tus constancias y el código para recuperar tu PIN.';

  @override
  String errorFixFields(int n) {
    return 'Revisa $n campos para continuar';
  }

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get errorDniLength => 'El DNI debe tener 8 dígitos numéricos.';

  @override
  String get errorEmailInvalid => 'Ingresa un correo válido.';

  @override
  String get identityInfo =>
      'Validaremos tu identidad con una foto de tu DNI y reconocimiento facial.';

  @override
  String get continueCta => 'Continuar';

  @override
  String get termsNote =>
      'Al continuar aceptas los Términos y la Política de Privacidad';

  @override
  String get documentHeadline => 'Escanea tu DNI';

  @override
  String get documentSubtitle =>
      'Coloca el documento sobre una superficie plana, sin reflejos y con buena luz.';

  @override
  String capturesCount(int n) {
    return '$n de 2 capturas';
  }

  @override
  String get dniFront => 'Frente del DNI';

  @override
  String get dniFrontHint => 'Foto y datos personales';

  @override
  String get dniBack => 'Reverso del DNI';

  @override
  String get dniBackHint => 'Código y firma';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get retakePhoto => 'Volver a tomar';

  @override
  String get captured => 'Capturado';

  @override
  String get notReadable => 'No legible';

  @override
  String get documentError => 'No pudimos leer tu DNI';

  @override
  String get documentTip1 => 'Evita reflejos y sombras sobre el documento.';

  @override
  String get documentTip2 =>
      'Apoya el DNI en una superficie plana, sin doblarlo.';

  @override
  String get documentTip3 => 'Encuadra las cuatro esquinas dentro del marco.';

  @override
  String get documentSecure =>
      'Tus documentos se cifran y solo se usan para validar tu identidad.';

  @override
  String get faceHeadline => 'Centra tu rostro en el círculo';

  @override
  String get cameraDenied =>
      'Necesitamos la cámara para verificar tu identidad. Actívala desde los ajustes del teléfono.';

  @override
  String get cameraUnavailable => 'No pudimos usar la cámara de este teléfono.';

  @override
  String get cameraSimulated => 'Cámara simulada (entorno de pruebas)';

  @override
  String get useSampleDocument => 'Usar una foto de ejemplo';

  @override
  String get faceNeedsDocument =>
      'Primero captura el frente de tu DNI: comparamos tu rostro con esa foto.';

  @override
  String get livenessPreparing => 'Preparando la verificación…';

  @override
  String livenessProgress(int done, int total) {
    return 'Paso $done de $total';
  }

  @override
  String get livenessStepArriba => 'Levanta la cabeza, despacio';

  @override
  String get livenessStepAbajo => 'Baja la cabeza, despacio';

  @override
  String get livenessStepIzquierda => 'Gira la cabeza a tu izquierda';

  @override
  String get livenessStepDerecha => 'Gira la cabeza a tu derecha';

  @override
  String get livenessStepParpadeo => 'Parpadea dos veces mirando a la cámara';

  @override
  String get livenessCapture => 'Estoy listo';

  @override
  String get livenessCapturing => 'No te muevas del gesto…';

  @override
  String get livenessEvaluating => 'Verificando…';

  @override
  String get livenessVerifying => 'Confirmando tu identidad…';

  @override
  String get livenessRetry => 'Repetir este paso';

  @override
  String get livenessApproved => 'Identidad verificada';

  @override
  String get livenessRejected =>
      'No pudimos verificar tu identidad. Vuelve a intentarlo con buena luz y el rostro descubierto.';

  @override
  String get livenessExpired => 'El tiempo se agotó. Empecemos de nuevo.';

  @override
  String get livenessRestart => 'Empezar de nuevo';

  @override
  String get errorServiceUnavailable =>
      'No pudimos conectar con el servicio de verificación. Revisa tu conexión.';

  @override
  String get faceInstruction => 'Gira lentamente la cabeza hacia la derecha';

  @override
  String get faceCheckLight => 'Buena iluminación';

  @override
  String get faceCheckUncovered => 'Rostro descubierto';

  @override
  String get faceCheckLiveness => 'Prueba de vida';

  @override
  String get faceInProgress => '(En proceso)';

  @override
  String get faceCaption => 'No cierres la app durante la verificación.';

  @override
  String get faceSimulate => 'Simular verificación';

  @override
  String get pinHeadline => 'Crea tu PIN de seguridad';

  @override
  String get pinSubtitle =>
      'Lo usarás para entrar y para autorizar tus operaciones.';

  @override
  String get pinConfirmHeadline => 'Confírmalo';

  @override
  String get pinConfirmSubtitle => 'Vuelve a escribir los 6 dígitos.';

  @override
  String get pinRule6 => '6 dígitos';

  @override
  String get pinRuleNoRepeats => 'Sin repetir el mismo dígito seis veces';

  @override
  String get pinRuleNoSequence => 'Sin secuencias como 123456';

  @override
  String get biometricTitle => 'Activar acceso biométrico';

  @override
  String get biometricHeadline => '¿Quieres entrar con tu huella?';

  @override
  String get biometricBody =>
      'Podrás abrir la app y autorizar tus operaciones sin escribir el PIN.';

  @override
  String get finishRegister => 'Finalizar registro';

  @override
  String quickAccessGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get quickAccessPrompt => 'Ingresa tu PIN de seguridad';

  @override
  String notYou(String name) {
    return '¿No eres $name?';
  }

  @override
  String get forgotPinAction => 'Olvidé mi PIN';

  @override
  String pinWrongAttempts(int n) {
    return 'PIN incorrecto. Te quedan $n intentos.';
  }

  @override
  String pinWrongHint(String duration) {
    return 'Tras 3 intentos fallidos tu acceso se bloqueará por $duration.';
  }

  @override
  String loginWrongHint(String duration) {
    return 'Tras 3 intentos fallidos bloquearemos el ingreso por $duration.';
  }

  @override
  String durationSeconds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String get blockedTitle => 'Tu acceso está bloqueado';

  @override
  String get blockedSubtitle =>
      'Por tu seguridad bloqueamos el ingreso tras 3 intentos fallidos.';

  @override
  String get blockedCountdownLabel => 'Podrás intentarlo de nuevo en';

  @override
  String get blockedRecoverPin => 'Recuperar mi PIN';

  @override
  String get blockedSupport => 'Escribir a soporte por WhatsApp';

  @override
  String get supportUnavailable =>
      'No pudimos abrir WhatsApp. Escríbenos al +51 954 269 667.';

  @override
  String get switchUserTitle => '¿Salir de esta cuenta?';

  @override
  String switchUserBody(String name) {
    return '$name tendrá que ingresar su DNI y su PIN de seguridad para volver a entrar en este teléfono.';
  }

  @override
  String get switchUserConsequenceBiometric =>
      'Se desactivará el acceso con huella.';

  @override
  String get switchUserConsequenceSession =>
      'Se cerrará la sesión guardada en este dispositivo.';

  @override
  String get switchUserConfirm => 'Salir de esta cuenta';

  @override
  String get cancel => 'Cancelar';

  @override
  String get errorPinUnchanged => 'Tu nuevo PIN debe ser distinto al anterior.';

  @override
  String get otpSubmit => 'Verificar';

  @override
  String get otpRequestNewCode => 'Enviar otro código';

  @override
  String otpResendIn(String time) {
    return 'Enviar otro código en $time';
  }

  @override
  String get otpResendNow => 'Enviar otro código';

  @override
  String get otpSpamHint => 'Revisa tu carpeta de spam.';

  @override
  String get otpChangeEmail => 'Cambiar correo';

  @override
  String otpWrongCode(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Código incorrecto. Te quedan $n intentos.',
      one: 'Código incorrecto. Te queda 1 intento.',
    );
    return '$_temp0';
  }

  @override
  String get otpExpiredMessage =>
      'Este código venció. Los códigos duran 10 minutos.';

  @override
  String get otpAttemptsWarningRecovery =>
      'Tras 3 intentos cancelaremos la recuperación.';

  @override
  String get otpAttemptsWarningDevice =>
      'Tras 3 intentos cancelaremos el ingreso.';

  @override
  String get otpRecoveryTitle => 'Verificar código';

  @override
  String get otpRecoveryHeading => 'Revisa tu correo';

  @override
  String otpRecoverySubtitle(String email) {
    return 'Enviamos un código de 6 dígitos a $email';
  }

  @override
  String get otpDeviceTitle => 'Verificar dispositivo';

  @override
  String get otpDeviceHeading => 'Revisa tu correo';

  @override
  String otpDeviceSubtitle(String email) {
    return 'Detectamos un ingreso desde un teléfono que no reconocemos. Enviamos un código de 6 dígitos a $email';
  }

  @override
  String get otpDeviceNotice =>
      'Al verificar, vincularemos este teléfono a tu cuenta.';

  @override
  String get recoverTitle => 'Recuperar PIN';

  @override
  String get recoverHeadline => '¿Con qué correo te registraste?';

  @override
  String get recoverSubtitle =>
      'Te enviaremos un código de 6 dígitos para que crees un PIN nuevo.';

  @override
  String get recoverCta => 'Enviar código';

  @override
  String get recoverNeutralNotice =>
      'Si el correo está registrado, te enviamos un código';

  @override
  String get resetPinTitle => 'Restablecer PIN';

  @override
  String get resetPinHeadline => 'Crea tu nuevo PIN';

  @override
  String get resetPinSubtitle => '6 dígitos, distinto al que usabas antes.';

  @override
  String get resetPinConfirmHeadline => 'Confirma tu PIN';

  @override
  String get resetPinConfirmSubtitle => 'Vuelve a escribir los 6 dígitos.';

  @override
  String get resetPinSamePin => 'Ese es tu PIN actual. Elige uno distinto.';

  @override
  String get resetPinNotice =>
      'Tu PIN es personal. Nadie de CuyCash te lo pedirá nunca.';

  @override
  String get resetPinMismatch => 'No coincide con el PIN que elegiste.';

  @override
  String get resetPinExitTitle => '¿Salir sin cambiar tu PIN?';

  @override
  String get resetPinExitBody => 'Tendrás que pedir un código nuevo';

  @override
  String get resetPinExitConfirm => 'Salir';

  @override
  String get pinUpdatedHeadline => 'PIN actualizado';

  @override
  String get pinUpdatedBody =>
      'Ya puedes ingresar con tu nuevo PIN de seguridad.';

  @override
  String get pinUpdatedSessionsNotice =>
      'Cerramos la sesión en los demás dispositivos por seguridad.';

  @override
  String get pinUpdatedCta => 'Ingresar con mi nuevo PIN';

  @override
  String get cancelledEmailNotice => 'Enviamos un aviso al correo registrado.';

  @override
  String get cancelledLoginHeadline => 'Cancelamos el ingreso';

  @override
  String get cancelledLoginBody =>
      'Ingresaste 3 códigos incorrectos, así que detuvimos la vinculación de este teléfono.';

  @override
  String get cancelledLoginReassurance =>
      'Nadie entró a tu cuenta y tu dinero está intacto.';

  @override
  String get cancelledLoginPrimary => 'Volver a iniciar sesión';

  @override
  String get cancelledRecoveryHeadline => 'Cancelamos la recuperación';

  @override
  String get cancelledRecoveryBody =>
      'Ingresaste 3 códigos incorrectos, así que detuvimos el cambio de tu PIN.';

  @override
  String get cancelledRecoveryReassurance =>
      'Tu PIN actual no cambió y tu cuenta sigue segura.';

  @override
  String get cancelledRecoveryPrimary => 'Volver al inicio';

  @override
  String get cancelledRecoverySecondary => 'Intentar de nuevo';

  @override
  String get homeGreetingMorning => 'Buenos días,';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes,';

  @override
  String get homeGreetingEvening => 'Buenas noches,';

  @override
  String get homeNotifications => 'Notificaciones';

  @override
  String get homeDemoBadge => 'Datos de demostración';

  @override
  String get homeBalanceLabel => 'Saldo disponible';

  @override
  String get homeBalanceHidden => 'S/ ••••••';

  @override
  String get homeShowBalance => 'Mostrar saldo';

  @override
  String get homeHideBalance => 'Ocultar saldo';

  @override
  String homeWalletMask(String last4) {
    return 'Billetera •••• $last4';
  }

  @override
  String get homeActionSend => 'Enviar';

  @override
  String get homeActionCharge => 'Cobrar';

  @override
  String get homeActionTopUp => 'Recargar';

  @override
  String get homeActionWithdraw => 'Retirar';

  @override
  String get homeBotName => 'WasiBot';

  @override
  String get homeBotInsight =>
      'Este mes llevas S/ 340.00 en gastos, 12 % menos que en agosto.';

  @override
  String get homeMovementsTitle => 'Últimos movimientos';

  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String get homeMovementCompleted => 'Completada';

  @override
  String get homeToday => 'Hoy';

  @override
  String get homeYesterday => 'Ayer';

  @override
  String homeDateTime(String day, String time) {
    return '$day · $time';
  }

  @override
  String get comingSoon => 'Disponible en una próxima versión.';

  @override
  String get profileHeadlineFallback => 'Tu cuenta';

  @override
  String get profileAliasLabel => 'Tu alias';

  @override
  String get profileDniLabel => 'DNI';

  @override
  String get profileVerified => 'Identidad verificada';

  @override
  String get profileSectionAccount => 'Cuenta';

  @override
  String get profileSectionSecurity => 'Seguridad';

  @override
  String get profileSectionSupport => 'Ayuda';

  @override
  String get profileItemPersonalData => 'Datos personales';

  @override
  String get profileItemAlias => 'Editar mi alias';

  @override
  String get profileItemChangePin => 'Cambiar mi PIN';

  @override
  String get profileItemBiometrics => 'Acceso biométrico';

  @override
  String get profileItemDevices => 'Dispositivos vinculados';

  @override
  String get profileItemHelp => 'Centro de ayuda';

  @override
  String get profileItemTerms => 'Términos y privacidad';
}
