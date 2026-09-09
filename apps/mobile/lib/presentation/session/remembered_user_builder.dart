import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feature/device/application/device_actions.dart';
import '../../feature/device/domain/remembered_user.dart';
import '../auth/bloc/auth_bloc.dart';

/// Resuelve "quién es el usuario de esta sesión" para las pantallas que solo
/// necesitan mostrarlo (Inicio y Perfil).
///
/// El nombre completo y el alias los devuelve el servicio al autenticar y
/// `AppRoot` los guarda en el almacén del dispositivo; la sesión en memoria
/// solo garantiza el identificador. Por eso se lee del almacén (async) y, para
/// no parpadear con un spinner, se pinta primero lo que la sesión ya sabe.
class RememberedUserBuilder extends StatefulWidget {
  const RememberedUserBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, RememberedUser user) builder;

  @override
  State<RememberedUserBuilder> createState() => _RememberedUserBuilderState();
}

class _RememberedUserBuilderState extends State<RememberedUserBuilder> {
  RememberedUser? _stored;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await context.read<DeviceActions>().readUser();
    if (!mounted || user == null) return;
    setState(() => _stored = user);
  }

  /// Lo mínimo que se puede afirmar sin tocar el almacén.
  RememberedUser _fromSession() {
    final state = context.read<AuthBloc>().state;
    final session = state is AuthAuthenticated ? state.session : null;
    final dni = session?.identifier ?? '';
    return RememberedUser(
      dni: dni,
      fullName: session?.fullName ?? '',
      alias: session?.alias ?? '',
    );
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _stored ?? _fromSession());
}
