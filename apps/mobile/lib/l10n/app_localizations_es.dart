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
  String get identifierLabel => 'DNI';

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
  String get errorInvalidCredentials => 'DNI o PIN incorrectos.';

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
  String get livenessStepArriba => 'Levanta la cabeza, despacio';

  @override
  String get livenessStepAbajo => 'Baja la cabeza, despacio';

  @override
  String get livenessStepIzquierda => 'Gira la cabeza a tu izquierda';

  @override
  String get livenessStepDerecha => 'Gira la cabeza a tu derecha';

  @override
  String get livenessStepParpadeo => 'Parpadea despacio, mirando a la cámara';

  @override
  String get livenessGuideNoFace => 'Ubica tu rostro dentro del óvalo';

  @override
  String get livenessGuideMultipleFaces => 'Solo debe verse tu rostro';

  @override
  String get livenessGuideTooFar => 'Acércate un poco';

  @override
  String get livenessGuideTooClose => 'Aléjate un poco';

  @override
  String get livenessGuideOffCenter => 'Centra tu rostro en el óvalo';

  @override
  String get livenessGuideNotFrontal => 'Mira de frente a la cámara';

  @override
  String get livenessGuideEyesClosed => 'Mantén los ojos abiertos';

  @override
  String get livenessHoldStill => 'Quédate así, sin moverte…';

  @override
  String get livenessBackToCenter => 'Bien. Vuelve a mirar al frente';

  @override
  String get livenessStepSlow => 'Haz el gesto un poco más marcado';

  @override
  String livenessStepOf(int done, int total) {
    return 'Gesto $done de $total';
  }

  @override
  String get livenessVerifying => 'Confirmando tu identidad…';

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
  String get registerBiometricLater =>
      'No pudimos activar tu huella. Puedes hacerlo desde tu perfil, en Acceso biométrico.';

  @override
  String get registerBiometricReason =>
      'Confirma tu huella o rostro para entrar más rápido a CuyCash';

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
  String get quickAccessBiometricReason =>
      'Confirma que eres tú para entrar a CuyCash';

  @override
  String get quickAccessBiometricRevoked =>
      'Tu acceso con huella ya no es válido. Entra con tu PIN y vuelve a activarlo desde tu perfil.';

  @override
  String get quickAccessBiometricFailed =>
      'No pudimos entrar con tu huella. Inténtalo de nuevo o usa tu PIN.';

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
  String get pinVerifying => 'Verificando tu PIN…';

  @override
  String get pinVerifyingSlow =>
      'Estamos reconectando con el servidor. Puede tardar unos segundos más.';

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
  String get homeBalanceLabel => 'Saldo disponible';

  @override
  String homeBalanceHidden(String simbolo) {
    return '$simbolo ••••••';
  }

  @override
  String get homeShowBalance => 'Mostrar saldo';

  @override
  String get homeHideBalance => 'Ocultar saldo';

  @override
  String homeWalletMask(String masked) {
    return 'Billetera $masked';
  }

  @override
  String get accountTypeAhorroLong => 'Cuenta de ahorros';

  @override
  String get accountTypeCorrienteLong => 'Cuenta corriente';

  @override
  String get accountTypeSueldoLong => 'Cuenta sueldo';

  @override
  String get accountTypeAhorroShort => 'Ahorros';

  @override
  String get accountTypeCorrienteShort => 'Corriente';

  @override
  String get accountTypeSueldoShort => 'Sueldo';

  @override
  String get currencyPenName => 'Soles';

  @override
  String get currencyUsdName => 'Dólares';

  @override
  String homeAccountPage(int actual, int total) {
    return 'Cuenta $actual de $total';
  }

  @override
  String get homeRenameTooltip => 'Cambiar el nombre de la cuenta';

  @override
  String get homeOpenAccountCta => 'Abrir cuenta';

  @override
  String get renameAccountTitle => 'Nombre de la cuenta';

  @override
  String get renameAccountHint => 'Ej. Viaje';

  @override
  String get renameAccountSave => 'Guardar';

  @override
  String get renameAccountClear => 'Quitar nombre';

  @override
  String get renameAccountError =>
      'No pudimos guardar el nombre. Inténtalo de nuevo.';

  @override
  String get renameAccountTooLong => 'Usa hasta 30 caracteres.';

  @override
  String get homeActionSend => 'Transferir';

  @override
  String get homeActionCharge => 'Cobrar';

  @override
  String get homeActionTopUp => 'Depósito simulado';

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
  String get homeSeeMore => 'Ver más';

  @override
  String get homeMovementsAllAccounts => 'De todas tus cuentas';

  @override
  String get homeMenuTooltip => 'Más opciones';

  @override
  String get homeOpenAccountCard => 'Abrir otra cuenta';

  @override
  String get homeOpenAccountCardHint => 'Ahorros, corriente o sueldo';

  @override
  String homeAccountOpenSemantics(String cuenta) {
    return 'Ver los movimientos de $cuenta';
  }

  @override
  String get movementsTitle => 'Movimientos';

  @override
  String get movementsLoadMoreFailed =>
      'No pudimos cargar más movimientos. Desliza para reintentar.';

  @override
  String get movementBetweenOwn => 'Entre tus cuentas';

  @override
  String movementOwnRoute(String origen, String destino) {
    return '$origen → $destino';
  }

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
  String get homeLoading => 'Cargando tu cuenta';

  @override
  String get homeErrorNetwork =>
      'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get homeErrorGeneric =>
      'No pudimos cargar tu cuenta. Inténtalo de nuevo.';

  @override
  String get homeRefreshFailed =>
      'No pudimos actualizar. Estás viendo datos anteriores.';

  @override
  String get homeRetry => 'Reintentar';

  @override
  String get homeMovementsEmpty => 'Aún no tienes movimientos';

  @override
  String get homeMovementFallbackTitle => 'Movimiento';

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
  String get aliasTitle => 'Editar mi alias';

  @override
  String get aliasLabel => 'Tu alias';

  @override
  String get aliasHelp =>
      'De 3 a 20 letras, números, punto o guion bajo, con al menos una letra. Es único: compártelo para que te envíen dinero sin dar tu DNI.';

  @override
  String get aliasInvalid =>
      'Usa de 3 a 20 letras sin tildes, números, punto o guion bajo, con al menos una letra.';

  @override
  String get aliasTaken => 'Ese alias ya lo usa otra persona. Prueba con otro.';

  @override
  String get aliasSave => 'Guardar';

  @override
  String get aliasSaved => 'Listo, tu alias cambió.';

  @override
  String get aliasNetwork =>
      'No pudimos guardar tu alias. Revisa tu conexión e inténtalo de nuevo.';

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

  @override
  String get transferRecipientTitle => 'Enviar dinero';

  @override
  String get transferRecipientHeadline => '¿A quién le envías?';

  @override
  String get transferRecipientSubtitle =>
      'Escribe el DNI o el alias de la persona. Debe ser cliente de CuyCash.';

  @override
  String get transferDniLabel => 'DNI o alias del destinatario';

  @override
  String get transferRecipientHint => '12345678 o @alias';

  @override
  String get transferSearchAction => 'Buscar';

  @override
  String get transferSearching => 'Buscando…';

  @override
  String transferRecipientAccount(String masked) {
    return 'Cuenta $masked';
  }

  @override
  String transferRecipientAccountLine(
    String tipo,
    String simbolo,
    String masked,
  ) {
    return '$tipo · $simbolo · $masked';
  }

  @override
  String get transferRecipientChooseAccount => 'Elige la cuenta que recibe';

  @override
  String transferRecipientOnlyReceives(String simbolo) {
    return 'Solo recibe $simbolo';
  }

  @override
  String transferRecipientNoEligible(String simbolo) {
    return 'No tiene cuentas en $simbolo para recibir desde esta cuenta.';
  }

  @override
  String transferRecipientNoOwnEligible(String simbolo) {
    return 'No tienes otra cuenta en $simbolo.';
  }

  @override
  String transferFrequentOtherCurrency(String simbolo) {
    return 'Ese frecuente recibe en $simbolo. Envía desde una cuenta en $simbolo.';
  }

  @override
  String get transferFrequentIsOrigin =>
      'Ese frecuente es la cuenta desde la que envías. Elige otra.';

  @override
  String transferRecipientAccountSemantics(String linea) {
    return 'Enviar a $linea';
  }

  @override
  String transferRecipientAccountDisabledSemantics(
    String linea,
    String motivo,
  ) {
    return '$linea. $motivo';
  }

  @override
  String get transferContinue => 'Continuar';

  @override
  String get transferAmountTitle => 'Monto del envío';

  @override
  String get transferAmountHeadline => '¿Cuánto quieres enviar?';

  @override
  String transferAmountTo(String name) {
    return 'Para $name';
  }

  @override
  String get transferAmountLabel => 'Monto';

  @override
  String get transferAmountHint => '0.00';

  @override
  String transferAvailable(String amount) {
    return 'Disponible: $amount';
  }

  @override
  String get transferMotivoLabel => 'Motivo (opcional)';

  @override
  String get transferMotivoHint => 'Ej. Almuerzo';

  @override
  String get transferAmountNoThousands =>
      'Escribe el monto sin comas de miles. Ejemplo: 1250.50';

  @override
  String get transferAmountInvalid =>
      'Escribe un monto válido, como 50 o 50.50.';

  @override
  String transferAmountZero(String cero) {
    return 'El monto debe ser mayor a $cero.';
  }

  @override
  String transferAmountOverMax(String max) {
    return 'El máximo por envío es $max.';
  }

  @override
  String transferAmountOverBalance(String balance) {
    return 'Supera tu saldo disponible ($balance).';
  }

  @override
  String get transferConfirmTitle => 'Confirmar envío';

  @override
  String get transferConfirmHeadline => 'Confirma con tu PIN';

  @override
  String get transferConfirmSubtitle =>
      'Revisa los datos y escribe tu PIN de 6 dígitos.';

  @override
  String get transferSummaryTo => 'Para';

  @override
  String get transferSummaryAmount => 'Monto';

  @override
  String get transferSummaryFrom => 'Desde';

  @override
  String get transferSummaryMotivo => 'Motivo';

  @override
  String get transferConfirmCta => 'Confirmar transferencia';

  @override
  String get transferRetryCta => 'Reintentar envío';

  @override
  String get transferBackHomeCta => 'Volver al inicio';

  @override
  String get transferKeyUnsavedWarning =>
      'No pudimos recordar este intento. Revisa tus movimientos antes de reintentar.';

  @override
  String get transferPendingElsewhereNotice =>
      'Tienes un envío sin resolver. Revisa tus movimientos antes de confirmar este.';

  @override
  String get transferLeaveTitle => '¿Salir sin confirmar?';

  @override
  String get transferLeaveBody =>
      'Tu envío pudo haberse realizado. Revísalo en tus movimientos antes de intentarlo otra vez.';

  @override
  String get transferLeaveConfirm => 'Salir';

  @override
  String get transferRecoveredNotice =>
      'Ya habías intentado enviar esto y no llegamos a saber si salió. Si reintentas, no se cobrará dos veces.';

  @override
  String get transferErrorInsufficientFunds =>
      'No te alcanza el saldo disponible.';

  @override
  String transferErrorWrongPin(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'PIN incorrecto. Te quedan $n intentos.',
      one: 'PIN incorrecto. Te queda 1 intento.',
    );
    return '$_temp0';
  }

  @override
  String transferErrorLocked(String time) {
    return 'Cuenta bloqueada hasta las $time.';
  }

  @override
  String get transferErrorRecipientNotFound =>
      'No encontramos a nadie con ese DNI o alias en CuyCash.';

  @override
  String get transferErrorCurrencyMismatch =>
      'Solo puedes enviar entre cuentas de la misma moneda.';

  @override
  String get transferErrorSameAccount =>
      'Elige una cuenta distinta a la de origen.';

  @override
  String get transferErrorSearchRateLimited =>
      'Demasiadas búsquedas. Espera un momento.';

  @override
  String get transferErrorSearchUnexpected =>
      'No pudimos buscar al destinatario. Inténtalo de nuevo.';

  @override
  String get transferErrorSubmitRateLimited =>
      'No pudimos confirmar tu envío. Espera un momento y reintenta: si ya salió, no se cobrará dos veces.';

  @override
  String transferErrorAmountOutOfRange(String min, String max) {
    return 'El monto debe estar entre $min y $max.';
  }

  @override
  String get transferErrorAccountBlocked =>
      'Tu cuenta no está activa, así que no puedes enviar dinero por ahora.';

  @override
  String get transferErrorKeyReused =>
      'Este envío ya se había iniciado con otros datos. Vuelve al inicio y empieza uno nuevo.';

  @override
  String get transferErrorAccountNotFound =>
      'No encontramos tu cuenta. Vuelve al inicio e inténtalo de nuevo.';

  @override
  String get transferErrorUnauthenticated =>
      'Tu sesión venció. Ingresa de nuevo para continuar.';

  @override
  String get transferErrorNetwork =>
      'No pudimos confirmar tu envío. Pudo haberse realizado: reintenta y, si ya salió, no se cobrará dos veces.';

  @override
  String get transferErrorUnexpected =>
      'Algo salió mal y no pudimos confirmar tu envío. Reintenta y, si ya salió, no se cobrará dos veces.';

  @override
  String get transferReceiptTitle => 'Constancia';

  @override
  String get transferReceiptHeadline => '¡Envío realizado!';

  @override
  String get transferReceiptTo => 'Enviado a';

  @override
  String get transferReceiptDate => 'Fecha';

  @override
  String get transferReceiptId => 'N.º de operación';

  @override
  String get transferReceiptReused =>
      'Este envío ya estaba registrado. No se cobró otra vez.';

  @override
  String get transferReceiptHome => 'Volver al inicio';

  @override
  String get transferFrequentsTitle => 'Frecuentes';

  @override
  String transferFrequentSemantics(String name, String cuenta) {
    return 'Enviar a $name, $cuenta';
  }

  @override
  String transferFrequentSemanticsNoAccount(String name) {
    return 'Enviar a $name';
  }

  @override
  String get transferSaveFrequentTitle => 'Guardar como frecuente';

  @override
  String get transferSaveFrequentHint =>
      'Si el envío sale bien, podrás elegirlo la próxima vez sin escribir el DNI.';

  @override
  String get transferFrequentNicknameLabel => '¿Cómo lo llamas? (opcional)';

  @override
  String get transferFrequentNotSaved =>
      'El envío se realizó, pero no pudimos guardar a esta persona como frecuente.';

  @override
  String get movementDetailTitle => 'Detalle del movimiento';

  @override
  String get movementDetailNotFound => 'No encontramos este movimiento.';

  @override
  String get movementDetailError =>
      'No pudimos cargar el movimiento. Inténtalo de nuevo.';

  @override
  String get movementDetailCounterparty => 'Con';

  @override
  String get movementDetailReceivedFrom => 'Recibido de';

  @override
  String get movementDetailDestinationAccount => 'Cuenta destino';

  @override
  String get movementDetailSourceAccount => 'Cuenta origen';

  @override
  String get movementDetailReason => 'Motivo';

  @override
  String get movementDetailStatus => 'Estado';

  @override
  String get movementDetailBalanceAfter => 'Saldo posterior';

  @override
  String get movementStatusConfirmed => 'Confirmada';

  @override
  String get movementStatusPending => 'Pendiente';

  @override
  String get movementStatusReverted => 'Revertida';

  @override
  String get movementHeadlineSent => 'Enviaste';

  @override
  String get movementHeadlineReceived => 'Recibiste';

  @override
  String get movementHeadlineTopUp => 'Depósito simulado';

  @override
  String get movementHeadlineOther => 'Movimiento';

  @override
  String get movementShare => 'Compartir constancia';

  @override
  String get movementShareHeader => 'Constancia de CuyCash';

  @override
  String get movementShareFailed =>
      'No pudimos compartir la constancia. Inténtalo de nuevo.';

  @override
  String get topUpTitle => 'Depósito simulado';

  @override
  String get topUpDemoNotice =>
      'Por ahora puedes sumar saldo de prueba desde aquí. Pronto podrás depositar como en cualquier banco: en un agente o ventanilla, o transfiriendo desde otra cuenta.';

  @override
  String get topUpHeadline => '¿Cuánto quieres depositar?';

  @override
  String topUpAmountOverMax(String max) {
    return 'El máximo por depósito es $max.';
  }

  @override
  String get topUpCta => 'Depositar';

  @override
  String get topUpRetryCta => 'Reintentar depósito';

  @override
  String get topUpSummaryTo => 'Se acredita en';

  @override
  String get topUpPendingElsewhereNotice =>
      'Tienes una operación sin resolver. Revisa tus movimientos antes de depositar.';

  @override
  String get topUpRecoveredNotice =>
      'Ya habías intentado depositar este monto y no llegamos a saber si se acreditó. Si reintentas, no se sumará dos veces.';

  @override
  String get topUpLeaveTitle => '¿Salir sin confirmar?';

  @override
  String get topUpLeaveBody =>
      'Tu depósito pudo haberse realizado. Revísalo en tus movimientos antes de intentarlo otra vez.';

  @override
  String get topUpErrorRateLimited =>
      'No pudimos confirmar tu depósito. Espera un momento y reintenta: si ya se acreditó, no se sumará dos veces.';

  @override
  String get topUpErrorAccountBlocked =>
      'Tu cuenta no está activa, así que no puedes depositar por ahora.';

  @override
  String get topUpErrorKeyReused =>
      'Este depósito ya se había iniciado con otro monto. Vuelve al inicio y empieza uno nuevo.';

  @override
  String get topUpErrorNetwork =>
      'No pudimos confirmar tu depósito. Pudo haberse realizado: reintenta y, si ya se acreditó, no se sumará dos veces.';

  @override
  String get topUpErrorUnexpected =>
      'Algo salió mal y no pudimos confirmar tu depósito. Reintenta y, si ya se acreditó, no se sumará dos veces.';

  @override
  String get topUpDoneHeadline => '¡Depósito realizado!';

  @override
  String get topUpDoneReused =>
      'Este depósito ya estaba registrado. No se sumó otra vez.';

  @override
  String get personalDataTitle => 'Datos personales';

  @override
  String get personalDataNames => 'Nombres';

  @override
  String get personalDataSurnames => 'Apellidos';

  @override
  String get personalDataEmail => 'Correo';

  @override
  String get personalDataAlias => 'Alias';

  @override
  String get personalDataSince => 'Cliente desde';

  @override
  String get personalDataVerified => 'Identidad verificada';

  @override
  String get personalDataReadOnly =>
      'Estos datos vienen de tu verificación de identidad. Si alguno no es correcto, escríbenos por WhatsApp.';

  @override
  String get personalDataError => 'No pudimos cargar tus datos.';

  @override
  String get changePinTitle => 'Cambiar mi PIN';

  @override
  String get changePinCurrentHeadline => 'Ingresa tu PIN actual';

  @override
  String get changePinCurrentSubtitle =>
      'Lo usamos para confirmar que eres tú.';

  @override
  String get changePinNewHeadline => 'Crea tu nuevo PIN';

  @override
  String get changePinNewSubtitle =>
      'Elige 6 dígitos que no uses en otro lado.';

  @override
  String get changePinConfirmHeadline => 'Confirma tu nuevo PIN';

  @override
  String get changePinConfirmSubtitle => 'Escríbelo otra vez.';

  @override
  String changePinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN actual incorrecto. Te quedan $count intentos.',
      one: 'PIN actual incorrecto. Te queda 1 intento.',
    );
    return '$_temp0';
  }

  @override
  String get changePinUnknown =>
      'No sabemos si tu PIN cambió. Intenta entrar con el nuevo o con el anterior.';

  @override
  String get changePinDoneTitle => 'Tu PIN cambió';

  @override
  String changePinDoneOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cerramos tu sesión en $count dispositivos.',
      one: 'Cerramos tu sesión en 1 dispositivo.',
      zero: 'Desde ahora entra con tu nuevo PIN.',
    );
    return '$_temp0';
  }

  @override
  String get changePinDoneCta => 'Listo';

  @override
  String get devicesTitle => 'Dispositivos vinculados';

  @override
  String get devicesThisPhone => 'Este teléfono';

  @override
  String get devicesUnknownModel => 'Dispositivo sin nombre';

  @override
  String devicesLinkedOn(String date) {
    return 'Vinculado el $date';
  }

  @override
  String devicesLastUse(String date) {
    return 'Último uso: $date';
  }

  @override
  String get devicesBiometric => 'Con huella activa';

  @override
  String get devicesUnlink => 'Desvincular';

  @override
  String get devicesUnlinkTitle => '¿Desvincular este dispositivo?';

  @override
  String get devicesUnlinkBody =>
      'Cerraremos su sesión y, para volver a entrar desde ahí, pediremos un código a tu correo.';

  @override
  String get devicesUnlinked => 'Listo, ese dispositivo ya no tiene acceso.';

  @override
  String get devicesCannotUnlinkCurrent =>
      'Para salir de este teléfono, cierra sesión.';

  @override
  String get devicesError => 'No pudimos cargar tus dispositivos.';

  @override
  String get devicesHelp =>
      'Si no reconoces alguno, desvincúlalo y cambia tu PIN.';

  @override
  String get biometricSettingsTitle => 'Acceso biométrico';

  @override
  String get biometricSettingsSwitch => 'Entrar con huella o rostro';

  @override
  String get biometricSettingsBody =>
      'Entra a CuyCash sin escribir tu PIN. Tu PIN sigue funcionando siempre.';

  @override
  String get biometricSettingsUnavailable =>
      'Este teléfono no tiene huella ni rostro registrados. Configúralos en los ajustes del sistema y vuelve aquí.';

  @override
  String get biometricSettingsPinHeadline => 'Confirma con tu PIN';

  @override
  String get biometricSettingsPinSubtitle =>
      'Después te pediremos tu huella o tu rostro.';

  @override
  String get biometricSettingsReason =>
      'Confirma que eres tú para activar el acceso biométrico';

  @override
  String biometricSettingsWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN incorrecto. Te quedan $count intentos.',
      one: 'PIN incorrecto. Te queda 1 intento.',
    );
    return '$_temp0';
  }

  @override
  String get biometricSettingsEnabled =>
      'Listo, ya puedes entrar con tu huella o rostro.';

  @override
  String get openAccountTitle => 'Abrir cuenta';

  @override
  String get openAccountHeadline => '¿Qué cuenta quieres abrir?';

  @override
  String get openAccountTypeLabel => 'Tipo de cuenta';

  @override
  String get openAccountCurrencyLabel => 'Moneda';

  @override
  String get openAccountNameLabel => 'Nombre (opcional)';

  @override
  String get openAccountNameHint => 'Ej. Viaje';

  @override
  String get openAccountSalaryOnlyPen => 'La cuenta sueldo es solo en soles.';

  @override
  String get openAccountSalaryTaken => 'Ya tienes una cuenta sueldo.';

  @override
  String get openAccountContinue => 'Continuar';

  @override
  String get openAccountPinHeadline => 'Confirma con tu PIN';

  @override
  String openAccountPinSubtitle(String cuenta, String moneda) {
    return 'Vas a abrir: $cuenta en $moneda';
  }

  @override
  String get openAccountCta => 'Abrir cuenta';

  @override
  String get openAccountRetryCta => 'Reintentar';

  @override
  String get openAccountErrorLimit => 'Ya tienes 5 cuentas, el máximo.';

  @override
  String get openAccountErrorSalary => 'Ya tienes una cuenta sueldo.';

  @override
  String get openAccountErrorCurrency => 'La cuenta sueldo es solo en soles.';

  @override
  String get openAccountErrorName =>
      'El nombre puede tener hasta 30 caracteres.';

  @override
  String get openAccountErrorKeyReused =>
      'Esa apertura ya se pidió con otros datos. Vuelve a empezar.';

  @override
  String get openAccountErrorNetwork =>
      'No pudimos confirmar si se abrió. Reintenta: no se abrirá dos veces.';

  @override
  String get openAccountErrorUnexpected =>
      'No pudimos confirmar si se abrió. Reintenta: no se abrirá dos veces.';

  @override
  String get openAccountLeaveTitle => '¿Salir sin confirmar?';

  @override
  String get openAccountLeaveBody =>
      'Tu cuenta pudo haberse abierto. Revisa tus cuentas en el inicio antes de intentarlo otra vez.';
}
