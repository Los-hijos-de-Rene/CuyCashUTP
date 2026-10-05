import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @successTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Tu cuenta está activa!'**
  String get successTitle;

  /// No description provided for @successSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ya puedes empezar a mover tu dinero con CuyCash.'**
  String get successSubtitle;

  /// No description provided for @successAliasLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu alias en CuyCash'**
  String get successAliasLabel;

  /// No description provided for @successWalletLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu billetera'**
  String get successWalletLabel;

  /// No description provided for @successIdentityVerified.
  ///
  /// In es, this message translates to:
  /// **'Identidad verificada'**
  String get successIdentityVerified;

  /// No description provided for @successShareHint.
  ///
  /// In es, this message translates to:
  /// **'Comparte tu alias para que te envíen dinero.'**
  String get successShareHint;

  /// No description provided for @goToAccount.
  ///
  /// In es, this message translates to:
  /// **'Ir a mi cuenta'**
  String get goToAccount;

  /// No description provided for @shareMyAlias.
  ///
  /// In es, this message translates to:
  /// **'Compartir mi alias'**
  String get shareMyAlias;

  /// No description provided for @aliasCopied.
  ///
  /// In es, this message translates to:
  /// **'Alias copiado'**
  String get aliasCopied;

  /// No description provided for @shareAliasMessage.
  ///
  /// In es, this message translates to:
  /// **'Envíame dinero a mi alias de CuyCash: {alias}'**
  String shareAliasMessage(String alias);

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear mi cuenta'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Iniciar sesión'**
  String get alreadyHaveAccount;

  /// No description provided for @onboardingTitle1.
  ///
  /// In es, this message translates to:
  /// **'Tu banco, sin colas ni papeles'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In es, this message translates to:
  /// **'Abre tu cuenta en minutos validando tu DNI y tu rostro.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In es, this message translates to:
  /// **'Envía y cobra en segundos'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In es, this message translates to:
  /// **'Manda dinero a cualquier persona en CuyCash sin comisiones, o cobra mostrando tu código.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In es, this message translates to:
  /// **'Recibe desde otras billeteras'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In es, this message translates to:
  /// **'El dinero que te envían desde otras apps llega directo a tu billetera CuyCash.'**
  String get onboardingBody3;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @loginHeadline.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de vuelta'**
  String get loginHeadline;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu número de DNI para continuar.'**
  String get loginSubtitle;

  /// No description provided for @loginPinHeadline.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu PIN'**
  String get loginPinHeadline;

  /// No description provided for @loginPinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'PIN de 6 dígitos de tu cuenta.'**
  String get loginPinSubtitle;

  /// No description provided for @loginDniSummary.
  ///
  /// In es, this message translates to:
  /// **'DNI {dni}'**
  String loginDniSummary(String dni);

  /// No description provided for @changeAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get changeAction;

  /// No description provided for @loginDniInvalid.
  ///
  /// In es, this message translates to:
  /// **'El DNI debe tener 8 dígitos.'**
  String get loginDniInvalid;

  /// No description provided for @loginWrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Los datos no son correctos. Te queda 1 intento.} other{Los datos no son correctos. Te quedan {n} intentos.}}'**
  String loginWrongCredentials(int n);

  /// No description provided for @identifierLabel.
  ///
  /// In es, this message translates to:
  /// **'DNI o Alias'**
  String get identifierLabel;

  /// No description provided for @pinLabel.
  ///
  /// In es, this message translates to:
  /// **'PIN de seguridad'**
  String get pinLabel;

  /// No description provided for @loginCta.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get loginCta;

  /// No description provided for @forgotPin.
  ///
  /// In es, this message translates to:
  /// **'Olvidé mi PIN'**
  String get forgotPin;

  /// No description provided for @goToRegister.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get goToRegister;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @registerHeadline.
  ///
  /// In es, this message translates to:
  /// **'Empecemos por lo básico'**
  String get registerHeadline;

  /// No description provided for @dniLabel.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get dniLabel;

  /// No description provided for @registerCta.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get registerCta;

  /// No description provided for @goToLogin.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Iniciar sesión'**
  String get goToLogin;

  /// No description provided for @homeTitle.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get homeTitle;

  /// No description provided for @homePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Tu billetera estará disponible muy pronto.'**
  String get homePlaceholder;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileIdentifierLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu identificador'**
  String get profileIdentifierLabel;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'DNI/Alias o PIN incorrectos.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorIdentifierTaken.
  ///
  /// In es, this message translates to:
  /// **'Este DNI ya está registrado.'**
  String get errorIdentifierTaken;

  /// No description provided for @errorWeakPin.
  ///
  /// In es, this message translates to:
  /// **'El PIN debe tener 6 dígitos.'**
  String get errorWeakPin;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error. Intenta de nuevo.'**
  String get errorGeneric;

  /// No description provided for @registerFlowTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerFlowTitle;

  /// No description provided for @identityTitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu identidad'**
  String get identityTitle;

  /// No description provided for @faceTitle.
  ///
  /// In es, this message translates to:
  /// **'Reconocimiento facial'**
  String get faceTitle;

  /// No description provided for @securityTitle.
  ///
  /// In es, this message translates to:
  /// **'Protege tu cuenta'**
  String get securityTitle;

  /// No description provided for @stepData.
  ///
  /// In es, this message translates to:
  /// **'Paso {n} de 4 · Datos'**
  String stepData(int n);

  /// No description provided for @stepDocument.
  ///
  /// In es, this message translates to:
  /// **'Paso {n} de 4 · Documento'**
  String stepDocument(int n);

  /// No description provided for @stepFace.
  ///
  /// In es, this message translates to:
  /// **'Paso {n} de 4 · Rostro'**
  String stepFace(int n);

  /// No description provided for @stepSecurity.
  ///
  /// In es, this message translates to:
  /// **'Paso {n} de 4 · Seguridad'**
  String stepSecurity(int n);

  /// No description provided for @dataHeadline.
  ///
  /// In es, this message translates to:
  /// **'Empecemos por ti'**
  String get dataHeadline;

  /// No description provided for @dataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus datos tal como figuran en tu DNI.'**
  String get dataSubtitle;

  /// No description provided for @dniFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de DNI'**
  String get dniFieldLabel;

  /// No description provided for @dniHint.
  ///
  /// In es, this message translates to:
  /// **'12345678'**
  String get dniHint;

  /// No description provided for @dniHelper.
  ///
  /// In es, this message translates to:
  /// **'8 dígitos'**
  String get dniHelper;

  /// No description provided for @nombresLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombres'**
  String get nombresLabel;

  /// No description provided for @nombresHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Juan Carlos'**
  String get nombresHint;

  /// No description provided for @apellidosLabel.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get apellidosLabel;

  /// No description provided for @apellidosHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Pérez García'**
  String get apellidosHint;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In es, this message translates to:
  /// **'ejemplo@correo.com'**
  String get emailHint;

  /// No description provided for @emailHelper.
  ///
  /// In es, this message translates to:
  /// **'Aquí te enviaremos tus constancias y el código para recuperar tu PIN.'**
  String get emailHelper;

  /// No description provided for @errorFixFields.
  ///
  /// In es, this message translates to:
  /// **'Revisa {n} campos para continuar'**
  String errorFixFields(int n);

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio.'**
  String get fieldRequired;

  /// No description provided for @errorDniLength.
  ///
  /// In es, this message translates to:
  /// **'El DNI debe tener 8 dígitos numéricos.'**
  String get errorDniLength;

  /// No description provided for @errorEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido.'**
  String get errorEmailInvalid;

  /// No description provided for @identityInfo.
  ///
  /// In es, this message translates to:
  /// **'Validaremos tu identidad con una foto de tu DNI y reconocimiento facial.'**
  String get identityInfo;

  /// No description provided for @continueCta.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueCta;

  /// No description provided for @termsNote.
  ///
  /// In es, this message translates to:
  /// **'Al continuar aceptas los Términos y la Política de Privacidad'**
  String get termsNote;

  /// No description provided for @documentHeadline.
  ///
  /// In es, this message translates to:
  /// **'Escanea tu DNI'**
  String get documentHeadline;

  /// No description provided for @documentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Coloca el documento sobre una superficie plana, sin reflejos y con buena luz.'**
  String get documentSubtitle;

  /// No description provided for @capturesCount.
  ///
  /// In es, this message translates to:
  /// **'{n} de 2 capturas'**
  String capturesCount(int n);

  /// No description provided for @dniFront.
  ///
  /// In es, this message translates to:
  /// **'Frente del DNI'**
  String get dniFront;

  /// No description provided for @dniFrontHint.
  ///
  /// In es, this message translates to:
  /// **'Foto y datos personales'**
  String get dniFrontHint;

  /// No description provided for @dniBack.
  ///
  /// In es, this message translates to:
  /// **'Reverso del DNI'**
  String get dniBack;

  /// No description provided for @dniBackHint.
  ///
  /// In es, this message translates to:
  /// **'Código y firma'**
  String get dniBackHint;

  /// No description provided for @takePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get takePhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Volver a tomar'**
  String get retakePhoto;

  /// No description provided for @captured.
  ///
  /// In es, this message translates to:
  /// **'Capturado'**
  String get captured;

  /// No description provided for @notReadable.
  ///
  /// In es, this message translates to:
  /// **'No legible'**
  String get notReadable;

  /// No description provided for @documentError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer tu DNI'**
  String get documentError;

  /// No description provided for @documentTip1.
  ///
  /// In es, this message translates to:
  /// **'Evita reflejos y sombras sobre el documento.'**
  String get documentTip1;

  /// No description provided for @documentTip2.
  ///
  /// In es, this message translates to:
  /// **'Apoya el DNI en una superficie plana, sin doblarlo.'**
  String get documentTip2;

  /// No description provided for @documentTip3.
  ///
  /// In es, this message translates to:
  /// **'Encuadra las cuatro esquinas dentro del marco.'**
  String get documentTip3;

  /// No description provided for @documentSecure.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos se cifran y solo se usan para validar tu identidad.'**
  String get documentSecure;

  /// No description provided for @faceHeadline.
  ///
  /// In es, this message translates to:
  /// **'Centra tu rostro en el círculo'**
  String get faceHeadline;

  /// No description provided for @cameraDenied.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos la cámara para verificar tu identidad. Actívala desde los ajustes del teléfono.'**
  String get cameraDenied;

  /// No description provided for @cameraUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos usar la cámara de este teléfono.'**
  String get cameraUnavailable;

  /// No description provided for @cameraSimulated.
  ///
  /// In es, this message translates to:
  /// **'Cámara simulada (entorno de pruebas)'**
  String get cameraSimulated;

  /// No description provided for @useSampleDocument.
  ///
  /// In es, this message translates to:
  /// **'Usar una foto de ejemplo'**
  String get useSampleDocument;

  /// No description provided for @faceNeedsDocument.
  ///
  /// In es, this message translates to:
  /// **'Primero captura el frente de tu DNI: comparamos tu rostro con esa foto.'**
  String get faceNeedsDocument;

  /// No description provided for @livenessPreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando la verificación…'**
  String get livenessPreparing;

  /// No description provided for @livenessProgress.
  ///
  /// In es, this message translates to:
  /// **'Paso {done} de {total}'**
  String livenessProgress(int done, int total);

  /// No description provided for @livenessStepArriba.
  ///
  /// In es, this message translates to:
  /// **'Levanta la cabeza, despacio'**
  String get livenessStepArriba;

  /// No description provided for @livenessStepAbajo.
  ///
  /// In es, this message translates to:
  /// **'Baja la cabeza, despacio'**
  String get livenessStepAbajo;

  /// No description provided for @livenessStepIzquierda.
  ///
  /// In es, this message translates to:
  /// **'Gira la cabeza a tu izquierda'**
  String get livenessStepIzquierda;

  /// No description provided for @livenessStepDerecha.
  ///
  /// In es, this message translates to:
  /// **'Gira la cabeza a tu derecha'**
  String get livenessStepDerecha;

  /// No description provided for @livenessStepParpadeo.
  ///
  /// In es, this message translates to:
  /// **'Parpadea dos veces mirando a la cámara'**
  String get livenessStepParpadeo;

  /// No description provided for @livenessCapture.
  ///
  /// In es, this message translates to:
  /// **'Estoy listo'**
  String get livenessCapture;

  /// No description provided for @livenessCapturing.
  ///
  /// In es, this message translates to:
  /// **'No te muevas del gesto…'**
  String get livenessCapturing;

  /// No description provided for @livenessEvaluating.
  ///
  /// In es, this message translates to:
  /// **'Verificando…'**
  String get livenessEvaluating;

  /// No description provided for @livenessVerifying.
  ///
  /// In es, this message translates to:
  /// **'Confirmando tu identidad…'**
  String get livenessVerifying;

  /// No description provided for @livenessRetry.
  ///
  /// In es, this message translates to:
  /// **'Repetir este paso'**
  String get livenessRetry;

  /// No description provided for @livenessApproved.
  ///
  /// In es, this message translates to:
  /// **'Identidad verificada'**
  String get livenessApproved;

  /// No description provided for @livenessRejected.
  ///
  /// In es, this message translates to:
  /// **'No pudimos verificar tu identidad. Vuelve a intentarlo con buena luz y el rostro descubierto.'**
  String get livenessRejected;

  /// No description provided for @livenessExpired.
  ///
  /// In es, this message translates to:
  /// **'El tiempo se agotó. Empecemos de nuevo.'**
  String get livenessExpired;

  /// No description provided for @livenessRestart.
  ///
  /// In es, this message translates to:
  /// **'Empezar de nuevo'**
  String get livenessRestart;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conectar con el servicio de verificación. Revisa tu conexión.'**
  String get errorServiceUnavailable;

  /// No description provided for @faceInstruction.
  ///
  /// In es, this message translates to:
  /// **'Gira lentamente la cabeza hacia la derecha'**
  String get faceInstruction;

  /// No description provided for @faceCheckLight.
  ///
  /// In es, this message translates to:
  /// **'Buena iluminación'**
  String get faceCheckLight;

  /// No description provided for @faceCheckUncovered.
  ///
  /// In es, this message translates to:
  /// **'Rostro descubierto'**
  String get faceCheckUncovered;

  /// No description provided for @faceCheckLiveness.
  ///
  /// In es, this message translates to:
  /// **'Prueba de vida'**
  String get faceCheckLiveness;

  /// No description provided for @faceInProgress.
  ///
  /// In es, this message translates to:
  /// **'(En proceso)'**
  String get faceInProgress;

  /// No description provided for @faceCaption.
  ///
  /// In es, this message translates to:
  /// **'No cierres la app durante la verificación.'**
  String get faceCaption;

  /// No description provided for @faceSimulate.
  ///
  /// In es, this message translates to:
  /// **'Simular verificación'**
  String get faceSimulate;

  /// No description provided for @pinHeadline.
  ///
  /// In es, this message translates to:
  /// **'Crea tu PIN de seguridad'**
  String get pinHeadline;

  /// No description provided for @pinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo usarás para entrar y para autorizar tus operaciones.'**
  String get pinSubtitle;

  /// No description provided for @pinConfirmHeadline.
  ///
  /// In es, this message translates to:
  /// **'Confírmalo'**
  String get pinConfirmHeadline;

  /// No description provided for @pinConfirmSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a escribir los 6 dígitos.'**
  String get pinConfirmSubtitle;

  /// No description provided for @pinRule6.
  ///
  /// In es, this message translates to:
  /// **'6 dígitos'**
  String get pinRule6;

  /// No description provided for @pinRuleNoRepeats.
  ///
  /// In es, this message translates to:
  /// **'Sin repetir el mismo dígito seis veces'**
  String get pinRuleNoRepeats;

  /// No description provided for @pinRuleNoSequence.
  ///
  /// In es, this message translates to:
  /// **'Sin secuencias como 123456'**
  String get pinRuleNoSequence;

  /// No description provided for @biometricTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar acceso biométrico'**
  String get biometricTitle;

  /// No description provided for @biometricHeadline.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres entrar con tu huella?'**
  String get biometricHeadline;

  /// No description provided for @biometricBody.
  ///
  /// In es, this message translates to:
  /// **'Podrás abrir la app y autorizar tus operaciones sin escribir el PIN.'**
  String get biometricBody;

  /// No description provided for @finishRegister.
  ///
  /// In es, this message translates to:
  /// **'Finalizar registro'**
  String get finishRegister;

  /// No description provided for @quickAccessGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String quickAccessGreeting(String name);

  /// No description provided for @quickAccessPrompt.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu PIN de seguridad'**
  String get quickAccessPrompt;

  /// No description provided for @notYou.
  ///
  /// In es, this message translates to:
  /// **'¿No eres {name}?'**
  String notYou(String name);

  /// No description provided for @forgotPinAction.
  ///
  /// In es, this message translates to:
  /// **'Olvidé mi PIN'**
  String get forgotPinAction;

  /// No description provided for @pinWrongAttempts.
  ///
  /// In es, this message translates to:
  /// **'PIN incorrecto. Te quedan {n} intentos.'**
  String pinWrongAttempts(int n);

  /// No description provided for @pinWrongHint.
  ///
  /// In es, this message translates to:
  /// **'Tras 3 intentos fallidos tu acceso se bloqueará por {duration}.'**
  String pinWrongHint(String duration);

  /// No description provided for @loginWrongHint.
  ///
  /// In es, this message translates to:
  /// **'Tras 3 intentos fallidos bloquearemos el ingreso por {duration}.'**
  String loginWrongHint(String duration);

  /// No description provided for @pinVerifying.
  ///
  /// In es, this message translates to:
  /// **'Verificando tu PIN…'**
  String get pinVerifying;

  /// No description provided for @pinVerifyingSlow.
  ///
  /// In es, this message translates to:
  /// **'Estamos reconectando con el servidor. Puede tardar unos segundos más.'**
  String get pinVerifyingSlow;

  /// No description provided for @durationSeconds.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 segundo} other{{n} segundos}}'**
  String durationSeconds(int n);

  /// No description provided for @durationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 minuto} other{{n} minutos}}'**
  String durationMinutes(int n);

  /// No description provided for @durationHours.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 hora} other{{n} horas}}'**
  String durationHours(int n);

  /// No description provided for @blockedTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu acceso está bloqueado'**
  String get blockedTitle;

  /// No description provided for @blockedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Por tu seguridad bloqueamos el ingreso tras 3 intentos fallidos.'**
  String get blockedSubtitle;

  /// No description provided for @blockedCountdownLabel.
  ///
  /// In es, this message translates to:
  /// **'Podrás intentarlo de nuevo en'**
  String get blockedCountdownLabel;

  /// No description provided for @blockedRecoverPin.
  ///
  /// In es, this message translates to:
  /// **'Recuperar mi PIN'**
  String get blockedRecoverPin;

  /// No description provided for @blockedSupport.
  ///
  /// In es, this message translates to:
  /// **'Escribir a soporte por WhatsApp'**
  String get blockedSupport;

  /// No description provided for @supportUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir WhatsApp. Escríbenos al +51 954 269 667.'**
  String get supportUnavailable;

  /// No description provided for @switchUserTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir de esta cuenta?'**
  String get switchUserTitle;

  /// No description provided for @switchUserBody.
  ///
  /// In es, this message translates to:
  /// **'{name} tendrá que ingresar su DNI y su PIN de seguridad para volver a entrar en este teléfono.'**
  String switchUserBody(String name);

  /// No description provided for @switchUserConsequenceBiometric.
  ///
  /// In es, this message translates to:
  /// **'Se desactivará el acceso con huella.'**
  String get switchUserConsequenceBiometric;

  /// No description provided for @switchUserConsequenceSession.
  ///
  /// In es, this message translates to:
  /// **'Se cerrará la sesión guardada en este dispositivo.'**
  String get switchUserConsequenceSession;

  /// No description provided for @switchUserConfirm.
  ///
  /// In es, this message translates to:
  /// **'Salir de esta cuenta'**
  String get switchUserConfirm;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @errorPinUnchanged.
  ///
  /// In es, this message translates to:
  /// **'Tu nuevo PIN debe ser distinto al anterior.'**
  String get errorPinUnchanged;

  /// No description provided for @otpSubmit.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get otpSubmit;

  /// No description provided for @otpRequestNewCode.
  ///
  /// In es, this message translates to:
  /// **'Enviar otro código'**
  String get otpRequestNewCode;

  /// No description provided for @otpResendIn.
  ///
  /// In es, this message translates to:
  /// **'Enviar otro código en {time}'**
  String otpResendIn(String time);

  /// No description provided for @otpResendNow.
  ///
  /// In es, this message translates to:
  /// **'Enviar otro código'**
  String get otpResendNow;

  /// No description provided for @otpSpamHint.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu carpeta de spam.'**
  String get otpSpamHint;

  /// No description provided for @otpChangeEmail.
  ///
  /// In es, this message translates to:
  /// **'Cambiar correo'**
  String get otpChangeEmail;

  /// No description provided for @otpWrongCode.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Código incorrecto. Te queda 1 intento.} other{Código incorrecto. Te quedan {n} intentos.}}'**
  String otpWrongCode(int n);

  /// No description provided for @otpExpiredMessage.
  ///
  /// In es, this message translates to:
  /// **'Este código venció. Los códigos duran 10 minutos.'**
  String get otpExpiredMessage;

  /// No description provided for @otpAttemptsWarningRecovery.
  ///
  /// In es, this message translates to:
  /// **'Tras 3 intentos cancelaremos la recuperación.'**
  String get otpAttemptsWarningRecovery;

  /// No description provided for @otpAttemptsWarningDevice.
  ///
  /// In es, this message translates to:
  /// **'Tras 3 intentos cancelaremos el ingreso.'**
  String get otpAttemptsWarningDevice;

  /// No description provided for @otpRecoveryTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificar código'**
  String get otpRecoveryTitle;

  /// No description provided for @otpRecoveryHeading.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get otpRecoveryHeading;

  /// No description provided for @otpRecoverySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un código de 6 dígitos a {email}'**
  String otpRecoverySubtitle(String email);

  /// No description provided for @otpDeviceTitle.
  ///
  /// In es, this message translates to:
  /// **'Verificar dispositivo'**
  String get otpDeviceTitle;

  /// No description provided for @otpDeviceHeading.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get otpDeviceHeading;

  /// No description provided for @otpDeviceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Detectamos un ingreso desde un teléfono que no reconocemos. Enviamos un código de 6 dígitos a {email}'**
  String otpDeviceSubtitle(String email);

  /// No description provided for @otpDeviceNotice.
  ///
  /// In es, this message translates to:
  /// **'Al verificar, vincularemos este teléfono a tu cuenta.'**
  String get otpDeviceNotice;

  /// No description provided for @recoverTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar PIN'**
  String get recoverTitle;

  /// No description provided for @recoverHeadline.
  ///
  /// In es, this message translates to:
  /// **'¿Con qué correo te registraste?'**
  String get recoverHeadline;

  /// No description provided for @recoverSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un código de 6 dígitos para que crees un PIN nuevo.'**
  String get recoverSubtitle;

  /// No description provided for @recoverCta.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get recoverCta;

  /// No description provided for @recoverNeutralNotice.
  ///
  /// In es, this message translates to:
  /// **'Si el correo está registrado, te enviamos un código'**
  String get recoverNeutralNotice;

  /// No description provided for @resetPinTitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecer PIN'**
  String get resetPinTitle;

  /// No description provided for @resetPinHeadline.
  ///
  /// In es, this message translates to:
  /// **'Crea tu nuevo PIN'**
  String get resetPinHeadline;

  /// No description provided for @resetPinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'6 dígitos, distinto al que usabas antes.'**
  String get resetPinSubtitle;

  /// No description provided for @resetPinConfirmHeadline.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu PIN'**
  String get resetPinConfirmHeadline;

  /// No description provided for @resetPinConfirmSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a escribir los 6 dígitos.'**
  String get resetPinConfirmSubtitle;

  /// No description provided for @resetPinSamePin.
  ///
  /// In es, this message translates to:
  /// **'Ese es tu PIN actual. Elige uno distinto.'**
  String get resetPinSamePin;

  /// No description provided for @resetPinNotice.
  ///
  /// In es, this message translates to:
  /// **'Tu PIN es personal. Nadie de CuyCash te lo pedirá nunca.'**
  String get resetPinNotice;

  /// No description provided for @resetPinMismatch.
  ///
  /// In es, this message translates to:
  /// **'No coincide con el PIN que elegiste.'**
  String get resetPinMismatch;

  /// No description provided for @resetPinExitTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir sin cambiar tu PIN?'**
  String get resetPinExitTitle;

  /// No description provided for @resetPinExitBody.
  ///
  /// In es, this message translates to:
  /// **'Tendrás que pedir un código nuevo'**
  String get resetPinExitBody;

  /// No description provided for @resetPinExitConfirm.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get resetPinExitConfirm;

  /// No description provided for @pinUpdatedHeadline.
  ///
  /// In es, this message translates to:
  /// **'PIN actualizado'**
  String get pinUpdatedHeadline;

  /// No description provided for @pinUpdatedBody.
  ///
  /// In es, this message translates to:
  /// **'Ya puedes ingresar con tu nuevo PIN de seguridad.'**
  String get pinUpdatedBody;

  /// No description provided for @pinUpdatedSessionsNotice.
  ///
  /// In es, this message translates to:
  /// **'Cerramos la sesión en los demás dispositivos por seguridad.'**
  String get pinUpdatedSessionsNotice;

  /// No description provided for @pinUpdatedCta.
  ///
  /// In es, this message translates to:
  /// **'Ingresar con mi nuevo PIN'**
  String get pinUpdatedCta;

  /// No description provided for @cancelledEmailNotice.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un aviso al correo registrado.'**
  String get cancelledEmailNotice;

  /// No description provided for @cancelledLoginHeadline.
  ///
  /// In es, this message translates to:
  /// **'Cancelamos el ingreso'**
  String get cancelledLoginHeadline;

  /// No description provided for @cancelledLoginBody.
  ///
  /// In es, this message translates to:
  /// **'Ingresaste 3 códigos incorrectos, así que detuvimos la vinculación de este teléfono.'**
  String get cancelledLoginBody;

  /// No description provided for @cancelledLoginReassurance.
  ///
  /// In es, this message translates to:
  /// **'Nadie entró a tu cuenta y tu dinero está intacto.'**
  String get cancelledLoginReassurance;

  /// No description provided for @cancelledLoginPrimary.
  ///
  /// In es, this message translates to:
  /// **'Volver a iniciar sesión'**
  String get cancelledLoginPrimary;

  /// No description provided for @cancelledRecoveryHeadline.
  ///
  /// In es, this message translates to:
  /// **'Cancelamos la recuperación'**
  String get cancelledRecoveryHeadline;

  /// No description provided for @cancelledRecoveryBody.
  ///
  /// In es, this message translates to:
  /// **'Ingresaste 3 códigos incorrectos, así que detuvimos el cambio de tu PIN.'**
  String get cancelledRecoveryBody;

  /// No description provided for @cancelledRecoveryReassurance.
  ///
  /// In es, this message translates to:
  /// **'Tu PIN actual no cambió y tu cuenta sigue segura.'**
  String get cancelledRecoveryReassurance;

  /// No description provided for @cancelledRecoveryPrimary.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get cancelledRecoveryPrimary;

  /// No description provided for @cancelledRecoverySecondary.
  ///
  /// In es, this message translates to:
  /// **'Intentar de nuevo'**
  String get cancelledRecoverySecondary;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días,'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes,'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches,'**
  String get homeGreetingEvening;

  /// No description provided for @homeNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get homeNotifications;

  /// No description provided for @homeBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo disponible'**
  String get homeBalanceLabel;

  /// No description provided for @homeBalanceHidden.
  ///
  /// In es, this message translates to:
  /// **'S/ ••••••'**
  String get homeBalanceHidden;

  /// No description provided for @homeShowBalance.
  ///
  /// In es, this message translates to:
  /// **'Mostrar saldo'**
  String get homeShowBalance;

  /// No description provided for @homeHideBalance.
  ///
  /// In es, this message translates to:
  /// **'Ocultar saldo'**
  String get homeHideBalance;

  /// No description provided for @homeWalletMask.
  ///
  /// In es, this message translates to:
  /// **'Billetera {masked}'**
  String homeWalletMask(String masked);

  /// No description provided for @homeActionSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get homeActionSend;

  /// No description provided for @homeActionCharge.
  ///
  /// In es, this message translates to:
  /// **'Cobrar'**
  String get homeActionCharge;

  /// No description provided for @homeActionTopUp.
  ///
  /// In es, this message translates to:
  /// **'Recargar'**
  String get homeActionTopUp;

  /// No description provided for @homeActionWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get homeActionWithdraw;

  /// No description provided for @homeBotName.
  ///
  /// In es, this message translates to:
  /// **'WasiBot'**
  String get homeBotName;

  /// No description provided for @homeBotInsight.
  ///
  /// In es, this message translates to:
  /// **'Este mes llevas S/ 340.00 en gastos, 12 % menos que en agosto.'**
  String get homeBotInsight;

  /// No description provided for @homeMovementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Últimos movimientos'**
  String get homeMovementsTitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get homeSeeAll;

  /// No description provided for @homeMovementCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get homeMovementCompleted;

  /// No description provided for @homeToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get homeToday;

  /// No description provided for @homeYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get homeYesterday;

  /// No description provided for @homeDateTime.
  ///
  /// In es, this message translates to:
  /// **'{day} · {time}'**
  String homeDateTime(String day, String time);

  /// No description provided for @homeLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu cuenta'**
  String get homeLoading;

  /// No description provided for @homeErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.'**
  String get homeErrorNetwork;

  /// No description provided for @homeErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu cuenta. Inténtalo de nuevo.'**
  String get homeErrorGeneric;

  /// No description provided for @homeRefreshFailed.
  ///
  /// In es, this message translates to:
  /// **'No pudimos actualizar. Estás viendo datos anteriores.'**
  String get homeRefreshFailed;

  /// No description provided for @homeRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get homeRetry;

  /// No description provided for @homeMovementsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes movimientos'**
  String get homeMovementsEmpty;

  /// No description provided for @homeMovementFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimiento'**
  String get homeMovementFallbackTitle;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Disponible en una próxima versión.'**
  String get comingSoon;

  /// No description provided for @profileHeadlineFallback.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta'**
  String get profileHeadlineFallback;

  /// No description provided for @profileAliasLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu alias'**
  String get profileAliasLabel;

  /// No description provided for @profileDniLabel.
  ///
  /// In es, this message translates to:
  /// **'DNI'**
  String get profileDniLabel;

  /// No description provided for @profileVerified.
  ///
  /// In es, this message translates to:
  /// **'Identidad verificada'**
  String get profileVerified;

  /// No description provided for @profileSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get profileSectionSecurity;

  /// No description provided for @profileSectionSupport.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get profileSectionSupport;

  /// No description provided for @profileItemPersonalData.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get profileItemPersonalData;

  /// No description provided for @profileItemAlias.
  ///
  /// In es, this message translates to:
  /// **'Editar mi alias'**
  String get profileItemAlias;

  /// No description provided for @profileItemChangePin.
  ///
  /// In es, this message translates to:
  /// **'Cambiar mi PIN'**
  String get profileItemChangePin;

  /// No description provided for @profileItemBiometrics.
  ///
  /// In es, this message translates to:
  /// **'Acceso biométrico'**
  String get profileItemBiometrics;

  /// No description provided for @profileItemDevices.
  ///
  /// In es, this message translates to:
  /// **'Dispositivos vinculados'**
  String get profileItemDevices;

  /// No description provided for @profileItemHelp.
  ///
  /// In es, this message translates to:
  /// **'Centro de ayuda'**
  String get profileItemHelp;

  /// No description provided for @profileItemTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos y privacidad'**
  String get profileItemTerms;

  /// No description provided for @transferRecipientTitle.
  ///
  /// In es, this message translates to:
  /// **'Enviar dinero'**
  String get transferRecipientTitle;

  /// No description provided for @transferRecipientHeadline.
  ///
  /// In es, this message translates to:
  /// **'¿A quién le envías?'**
  String get transferRecipientHeadline;

  /// No description provided for @transferRecipientSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el DNI de la persona. Debe ser cliente de CuyCash.'**
  String get transferRecipientSubtitle;

  /// No description provided for @transferDniLabel.
  ///
  /// In es, this message translates to:
  /// **'DNI del destinatario'**
  String get transferDniLabel;

  /// No description provided for @transferSearching.
  ///
  /// In es, this message translates to:
  /// **'Buscando…'**
  String get transferSearching;

  /// No description provided for @transferRecipientAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta {masked}'**
  String transferRecipientAccount(String masked);

  /// No description provided for @transferContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get transferContinue;

  /// No description provided for @transferAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto del envío'**
  String get transferAmountTitle;

  /// No description provided for @transferAmountHeadline.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto quieres enviar?'**
  String get transferAmountHeadline;

  /// No description provided for @transferAmountTo.
  ///
  /// In es, this message translates to:
  /// **'Para {name}'**
  String transferAmountTo(String name);

  /// No description provided for @transferAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto en soles'**
  String get transferAmountLabel;

  /// No description provided for @transferAmountHint.
  ///
  /// In es, this message translates to:
  /// **'0.00'**
  String get transferAmountHint;

  /// No description provided for @transferAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible: {amount}'**
  String transferAvailable(String amount);

  /// No description provided for @transferMotivoLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get transferMotivoLabel;

  /// No description provided for @transferMotivoHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Almuerzo'**
  String get transferMotivoHint;

  /// No description provided for @transferAmountNoThousands.
  ///
  /// In es, this message translates to:
  /// **'Escribe el monto sin comas de miles. Ejemplo: 1250.50'**
  String get transferAmountNoThousands;

  /// No description provided for @transferAmountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un monto válido, como 50 o 50.50.'**
  String get transferAmountInvalid;

  /// No description provided for @transferAmountZero.
  ///
  /// In es, this message translates to:
  /// **'El monto debe ser mayor a S/ 0.00.'**
  String get transferAmountZero;

  /// No description provided for @transferAmountOverMax.
  ///
  /// In es, this message translates to:
  /// **'El máximo por envío es {max}.'**
  String transferAmountOverMax(String max);

  /// No description provided for @transferAmountOverBalance.
  ///
  /// In es, this message translates to:
  /// **'Supera tu saldo disponible ({balance}).'**
  String transferAmountOverBalance(String balance);

  /// No description provided for @transferConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar envío'**
  String get transferConfirmTitle;

  /// No description provided for @transferConfirmHeadline.
  ///
  /// In es, this message translates to:
  /// **'Confirma con tu PIN'**
  String get transferConfirmHeadline;

  /// No description provided for @transferConfirmSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos y escribe tu PIN de 6 dígitos.'**
  String get transferConfirmSubtitle;

  /// No description provided for @transferSummaryTo.
  ///
  /// In es, this message translates to:
  /// **'Para'**
  String get transferSummaryTo;

  /// No description provided for @transferSummaryAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get transferSummaryAmount;

  /// No description provided for @transferSummaryFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get transferSummaryFrom;

  /// No description provided for @transferSummaryMotivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get transferSummaryMotivo;

  /// No description provided for @transferConfirmCta.
  ///
  /// In es, this message translates to:
  /// **'Confirmar transferencia'**
  String get transferConfirmCta;

  /// No description provided for @transferRetryCta.
  ///
  /// In es, this message translates to:
  /// **'Reintentar envío'**
  String get transferRetryCta;

  /// No description provided for @transferBackHomeCta.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get transferBackHomeCta;

  /// No description provided for @transferLeaveTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir sin confirmar?'**
  String get transferLeaveTitle;

  /// No description provided for @transferLeaveBody.
  ///
  /// In es, this message translates to:
  /// **'Tu envío pudo haberse realizado. Revísalo en tus movimientos antes de intentarlo otra vez.'**
  String get transferLeaveBody;

  /// No description provided for @transferLeaveConfirm.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get transferLeaveConfirm;

  /// No description provided for @transferRecoveredNotice.
  ///
  /// In es, this message translates to:
  /// **'Ya habías intentado enviar esto y no llegamos a saber si salió. Si reintentas, no se cobrará dos veces.'**
  String get transferRecoveredNotice;

  /// No description provided for @transferErrorInsufficientFunds.
  ///
  /// In es, this message translates to:
  /// **'No te alcanza el saldo disponible.'**
  String get transferErrorInsufficientFunds;

  /// No description provided for @transferErrorWrongPin.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{PIN incorrecto. Te queda 1 intento.} other{PIN incorrecto. Te quedan {n} intentos.}}'**
  String transferErrorWrongPin(int n);

  /// No description provided for @transferErrorLocked.
  ///
  /// In es, this message translates to:
  /// **'Cuenta bloqueada hasta las {time}.'**
  String transferErrorLocked(String time);

  /// No description provided for @transferErrorRecipientNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos a nadie con ese DNI en CuyCash.'**
  String get transferErrorRecipientNotFound;

  /// No description provided for @transferErrorSelfTransfer.
  ///
  /// In es, this message translates to:
  /// **'No puedes enviarte dinero a ti mismo.'**
  String get transferErrorSelfTransfer;

  /// No description provided for @transferErrorSearchRateLimited.
  ///
  /// In es, this message translates to:
  /// **'Demasiadas búsquedas. Espera un momento.'**
  String get transferErrorSearchRateLimited;

  /// No description provided for @transferErrorSearchUnexpected.
  ///
  /// In es, this message translates to:
  /// **'No pudimos buscar al destinatario. Inténtalo de nuevo.'**
  String get transferErrorSearchUnexpected;

  /// No description provided for @transferErrorSubmitRateLimited.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu envío. Espera un momento y reintenta: si ya salió, no se cobrará dos veces.'**
  String get transferErrorSubmitRateLimited;

  /// No description provided for @transferErrorAmountOutOfRange.
  ///
  /// In es, this message translates to:
  /// **'El monto debe estar entre S/ 0.01 y {max}.'**
  String transferErrorAmountOutOfRange(String max);

  /// No description provided for @transferErrorAccountBlocked.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no está activa, así que no puedes enviar dinero por ahora.'**
  String get transferErrorAccountBlocked;

  /// No description provided for @transferErrorKeyReused.
  ///
  /// In es, this message translates to:
  /// **'Este envío ya se había iniciado con otros datos. Vuelve al inicio y empieza uno nuevo.'**
  String get transferErrorKeyReused;

  /// No description provided for @transferErrorAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos tu cuenta. Vuelve al inicio e inténtalo de nuevo.'**
  String get transferErrorAccountNotFound;

  /// No description provided for @transferErrorUnauthenticated.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión venció. Ingresa de nuevo para continuar.'**
  String get transferErrorUnauthenticated;

  /// No description provided for @transferErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu envío. Pudo haberse realizado: reintenta y, si ya salió, no se cobrará dos veces.'**
  String get transferErrorNetwork;

  /// No description provided for @transferErrorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal y no pudimos confirmar tu envío. Reintenta y, si ya salió, no se cobrará dos veces.'**
  String get transferErrorUnexpected;

  /// No description provided for @transferReceiptTitle.
  ///
  /// In es, this message translates to:
  /// **'Constancia'**
  String get transferReceiptTitle;

  /// No description provided for @transferReceiptHeadline.
  ///
  /// In es, this message translates to:
  /// **'¡Envío realizado!'**
  String get transferReceiptHeadline;

  /// No description provided for @transferReceiptTo.
  ///
  /// In es, this message translates to:
  /// **'Enviado a'**
  String get transferReceiptTo;

  /// No description provided for @transferReceiptDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get transferReceiptDate;

  /// No description provided for @transferReceiptId.
  ///
  /// In es, this message translates to:
  /// **'N.º de operación'**
  String get transferReceiptId;

  /// No description provided for @transferReceiptReused.
  ///
  /// In es, this message translates to:
  /// **'Este envío ya estaba registrado. No se cobró otra vez.'**
  String get transferReceiptReused;

  /// No description provided for @transferReceiptHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get transferReceiptHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
