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
  String get loginSubtitle => 'Ingresa con tu DNI y tu PIN de seguridad.';

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
  String get pinRule6 => '6 dígitos';

  @override
  String get pinRuleNoSequence => 'Sin secuencias como 123456';

  @override
  String get pinRuleNoBirthdate => 'No uses tu fecha de nacimiento';

  @override
  String get biometricTitle => 'Activar acceso biométrico';

  @override
  String get biometricSubtitle =>
      'Entra con tu huella o rostro sin escribir el PIN.';

  @override
  String get securityNote =>
      'CuyCash usa un solo factor de verificación por operación.';

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
  String get pinWrongHint =>
      'Tras 3 intentos fallidos tu acceso se bloqueará por 15 minutos.';

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
}
