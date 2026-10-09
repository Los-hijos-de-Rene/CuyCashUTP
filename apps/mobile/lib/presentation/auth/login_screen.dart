import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/secure_screen_scope.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../lockout/blocked_args.dart';
import '../lockout/lockout_duration_text.dart';
import 'auth_error_text.dart';
import 'bloc/auth_bloc.dart';

/// Los dos pasos del login. Existen porque cada campo quiere un teclado
/// distinto y no pueden convivir: el DNI usa el del sistema (número largo, no
/// secreto, se pega o se autocompleta) y el PIN el nuestro (secreto permanente,
/// no debe pasar por Gboard). Juntos, además, no caben con el teclado abierto.
enum _LoginStep { dni, pin }

/// Login en dos pasos: DNI y luego PIN. Ninguno tiene botón — el octavo dígito
/// del DNI avanza y el sexto del PIN envía.
///
/// El paso 2 es deliberadamente igual al acceso rápido: es la pantalla que el
/// usuario verá todos los días, y conviene que meter el PIN se aprenda una sola
/// vez. El paso 1 desaparece de ese teléfono tras el primer ingreso.
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.initialDni, super.key});

  /// DNI con el que se retoma tras un bloqueo. Si viene completo, la pantalla
  /// abre directamente en el paso del PIN.
  final String? initialDni;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _dni = TextEditingController();

  _LoginStep _step = _LoginStep.dni;
  String _pin = '';
  bool _dniInvalid = false;

  /// Longitud del DNI en la última notificación. El avance mira la TRANSICIÓN
  /// a ocho dígitos, no el hecho de medir ocho: si no, volver al paso 1 con el
  /// DNI ya completo rebota al paso 2 en cuanto el teclado reconecta y el
  /// controller vuelve a notificar el mismo texto, sin dejar editarlo.
  int _lastDniLength = 0;

  @override
  void initState() {
    super.initState();
    // El texto se fija ANTES de escuchar: si no, el DNI retomado contaría como
    // recién completado y dispararía el avance durante el initState.
    _dni.text = widget.initialDni ?? '';
    _lastDniLength = _dni.text.length;
    if (_dni.text.length == 8) _step = _LoginStep.pin;
    _dni.addListener(_onDniChanged);
  }

  @override
  void dispose() {
    _dni.dispose();
    super.dispose();
  }

  /// El octavo dígito avanza solo: no hay botón que tocar.
  void _onDniChanged() {
    final length = _dni.text.length;
    final completado = _lastDniLength < 8 && length == 8;
    _lastDniLength = length;
    setState(() => _dniInvalid = false);
    if (completado && _step == _LoginStep.dni) _goToPin();
  }

  void _goToPin() => setState(() {
        _step = _LoginStep.pin;
        _pin = '';
      });

  /// Volver al paso 1 CONSERVA el DNI: corregir un dígito no debería costar
  /// escribirlo entero. Se sincroniza la longitud para que el DNI que ya está
  /// escrito no cuente como recién completado.
  ///
  /// El error del intento anterior se descarta: puede que el DNI cambie, y
  /// sus intentos restantes no serían los del nuevo.
  void _goToDni() {
    context.read<AuthBloc>().add(const AuthEvent.formReset());
    setState(() {
      _step = _LoginStep.dni;
      _pin = '';
      _lastDniLength = _dni.text.length;
    });
  }

  void _onDigit(int digit) {
    if (_pin.length >= 6) return;
    setState(() => _pin = '$_pin$digit');
    if (_pin.length == 6) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  /// El PIN se envía solo al marcar el sexto dígito, así que durante la espera
  /// no hay botón hundido ni teclado que se cierre: la pantalla queda idéntica
  /// y el salto a verificar dispositivo llega sin anunciarse. Mientras viaja la
  /// petición se muestra el aviso y se apaga el teclado, para que lo que está
  /// en pantalla siga siendo lo que se está comprobando.
  bool _enviando(AuthUnauthenticated state) =>
      state.status == FormStatus.submitting;

  void _submit() {
    context.read<AuthBloc>().add(AuthEvent.loginSubmitted(
          identifier: _dni.text.trim(),
          pin: _pin,
        ));
  }

  /// El DNI solo puede quedar corto (el campo ya filtra a dígitos), y sin botón
  /// el único momento en que el usuario "insiste" es el enter del teclado.
  void _onDniSubmitted() {
    if (_dni.text.length == 8) {
      _goToPin();
    } else {
      setState(() => _dniInvalid = true);
    }
  }

  void _onBack() {
    if (_step == _LoginStep.pin) {
      _goToDni();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state case AuthUnauthenticated(:final pendingDeviceSession?)) {
      context.push(AppRoutes.ingresarDispositivo, extra: pendingDeviceSession);
      return;
    }
    if (state case AuthUnauthenticated(:final lockedUntil?)) {
      setState(() => _pin = '');
      context.go(
        AppRoutes.blocked,
        extra: BlockedArgs(
          origin: BlockedOrigin.login,
          lockedUntil: lockedUntil,
          resumeDni: _dni.text.trim(),
        ),
      );
      return;
    }
    // Tras un intento fallido las casillas quedan vacías para reintentar.
    if (state is AuthUnauthenticated && state.error != null) {
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enPin = _step == _LoginStep.pin;
    return SecureScreenScope(
      child: PopScope(
        // En el paso 2 el gesto del sistema hace lo mismo que la flecha.
        canPop: !enPin,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.loginTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _onBack,
            ),
          ),
          body: SafeArea(
            child: BlocConsumer<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  current is AuthUnauthenticated &&
                  (current.pendingDeviceSession != null ||
                      current.lockedUntil != null ||
                      current.error != null),
              listener: _onAuthState,
              builder: (context, state) {
                final unauth = state is AuthUnauthenticated
                    ? state
                    : const AuthUnauthenticated();
                return Column(
                  children: [
                    Expanded(
                      child: enPin
                          ? _PinStep(
                              dni: _dni.text,
                              pin: _pin,
                              state: unauth,
                              onChangeDni: _goToDni,
                            )
                          : _DniStep(
                              controller: _dni,
                              errorText:
                                  _dniInvalid ? l10n.loginDniInvalid : null,
                              onSubmitted: _onDniSubmitted,
                            ),
                    ),
                    // Teclado propio: el PIN no pasa por el del sistema.
                    if (enPin)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: CuyCashSpacing.stackLg),
                        child: PinKeypad(
                          onDigit: _onDigit,
                          onBackspace: _onBackspace,
                          enabled: !_enviando(unauth),
                        ),
                      ),
                    GhostButton(
                      label: l10n.goToRegister,
                      onPressed: () => context.go(AppRoutes.registro),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Paso 1 · DNI con el teclado del sistema.
class _DniStep extends StatelessWidget {
  const _DniStep({
    required this.controller,
    required this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      children: [
        Text(l10n.loginHeadline, style: CuyCashTypography.headlineSm),
        // Sin subtítulo: la etiqueta del campo ya dice qué escribir.
        const SizedBox(height: CuyCashSpacing.stackXl),
        CuyCashTextField(
          label: l10n.dniFieldLabel,
          hint: l10n.dniHint,
          controller: controller,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          maxLength: 8,
          errorText: errorText,
          autofocus: true,
          onSubmitted: (_) => onSubmitted(),
        ),
      ],
    );
  }
}

/// Paso 2 · PIN con teclado propio. Mismo gesto que el acceso rápido.
class _PinStep extends StatelessWidget {
  const _PinStep({
    required this.dni,
    required this.pin,
    required this.state,
    required this.onChangeDni,
  });

  final String dni;
  final String pin;
  final AuthUnauthenticated state;
  final VoidCallback onChangeDni;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = state.error;
    return ListView(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      children: [
        Text(l10n.loginPinHeadline, style: CuyCashTypography.headlineSm),
        // Sin subtítulo: las seis casillas ya dicen cuántos dígitos son.
        const SizedBox(height: CuyCashSpacing.stackMd),
        // El DNI a la vista con su atajo para corregirlo: como el mensaje de
        // error es genérico a propósito, el usuario honesto necesita poder
        // comprobar por sí mismo que escribió bien el número.
        Row(
          children: [
            Expanded(
              child: Text(l10n.loginDniSummary(dni),
                  style: CuyCashTypography.labelSm),
            ),
            GestureDetector(
              onTap: onChangeDni,
              child: Text(
                l10n.changeAction,
                style: CuyCashTypography.labelSm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CuyCashColors.primaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        PinBoxes(pin: pin, hasError: error != null),
        if (state.status == FormStatus.submitting) ...[
          const SizedBox(height: CuyCashSpacing.stackSm),
          PinSubmittingNotice(
            label: l10n.pinVerifying,
            patienceLabel: l10n.pinVerifyingSlow,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: CuyCashSpacing.stackSm),
          _ErrorLine(
            // NUNCA "PIN incorrecto": distinguir un DNI inexistente de un PIN
            // equivocado permitiría enumerar cuentas probando DNIs, que son
            // semipúblicos.
            text: error == AuthError.invalidCredentials
                ? l10n.loginWrongCredentials(state.attemptsLeft)
                : authErrorText(l10n, error),
          ),
          if (state.nextLockout case final next?
              when error == AuthError.invalidCredentials) ...[
            const SizedBox(height: CuyCashSpacing.stackXs),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                l10n.loginWrongHint(lockoutDurationText(l10n, next)),
                style: CuyCashTypography.labelSm,
              ),
            ),
          ],
        ],
        const SizedBox(height: CuyCashSpacing.stackSm),
        Align(
          alignment: Alignment.centerRight,
          child: GhostButton(
            label: l10n.forgotPin,
            onPressed: () => context.push(AppRoutes.recuperar),
          ),
        ),
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 16, color: CuyCashColors.error),
        const SizedBox(width: CuyCashSpacing.stackSm),
        Expanded(
          child: Text(
            text,
            style: CuyCashTypography.labelSm.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CuyCashColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
