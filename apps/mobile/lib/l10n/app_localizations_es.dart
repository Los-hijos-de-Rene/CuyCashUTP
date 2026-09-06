// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get loginHeadline => 'Te extrañábamos';

  @override
  String get loginSubtitle => 'Ingresa tus datos para continuar.';

  @override
  String get identifierLabel => 'DNI o Alias';

  @override
  String get pinLabel => 'PIN de seguridad';

  @override
  String get loginCta => 'Ingresar';

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
  String get errorWeakPin => 'El PIN debe tener 4 dígitos.';

  @override
  String get errorGeneric => 'Ocurrió un error. Intenta de nuevo.';
}
