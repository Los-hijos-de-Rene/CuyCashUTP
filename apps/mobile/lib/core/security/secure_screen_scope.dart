import 'package:flutter/widgets.dart';

import 'secure_screen.dart';

/// Envuelve una pantalla que muestra un PIN: marca la ventana como segura
/// mientras está viva y lo deshace al salir.
///
/// Es un envoltorio y no una llamada suelta para que activar y desactivar no
/// puedan separarse: olvidar el `disable` dejaría la app entera sin capturas.
class SecureScreenScope extends StatefulWidget {
  const SecureScreenScope({required this.child, super.key});

  final Widget child;

  @override
  State<SecureScreenScope> createState() => _SecureScreenScopeState();
}

class _SecureScreenScopeState extends State<SecureScreenScope> {
  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
