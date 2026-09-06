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
  /// **'Te extrañábamos'**
  String get loginHeadline;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus datos para continuar.'**
  String get loginSubtitle;

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

  /// No description provided for @pinRule6.
  ///
  /// In es, this message translates to:
  /// **'6 dígitos'**
  String get pinRule6;

  /// No description provided for @pinRuleNoSequence.
  ///
  /// In es, this message translates to:
  /// **'Sin secuencias como 123456'**
  String get pinRuleNoSequence;

  /// No description provided for @pinRuleNoBirthdate.
  ///
  /// In es, this message translates to:
  /// **'No uses tu fecha de nacimiento'**
  String get pinRuleNoBirthdate;

  /// No description provided for @biometricTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar acceso biométrico'**
  String get biometricTitle;

  /// No description provided for @biometricSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Entra con tu huella o rostro sin escribir el PIN.'**
  String get biometricSubtitle;

  /// No description provided for @securityNote.
  ///
  /// In es, this message translates to:
  /// **'CuyCash usa un solo factor de verificación por operación.'**
  String get securityNote;

  /// No description provided for @finishRegister.
  ///
  /// In es, this message translates to:
  /// **'Finalizar registro'**
  String get finishRegister;
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
