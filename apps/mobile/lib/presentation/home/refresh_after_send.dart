import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';
import 'bloc/account_bloc.dart';

/// Refresca el saldo cuando el usuario vuelve al inicio desde el flujo de
/// envío.
///
/// El flujo son cuatro pantallas apiladas que se cierran con `go(home)`, y un
/// `go` no puede devolver un resultado al `push` que las abrió (la recarga, de
/// una sola pantalla, sí: devuelve `true`). Por eso se observa la ubicación:
/// pasar de `/enviar...` a `/home` dispara [AccountRefreshed]. Salir sin enviar
/// también refresca: es una petición de más, inofensiva.
class RefreshAfterSend extends StatefulWidget {
  const RefreshAfterSend({required this.child, super.key});

  final Widget child;

  @override
  State<RefreshAfterSend> createState() => _RefreshAfterSendState();
}

class _RefreshAfterSendState extends State<RefreshAfterSend> {
  late final ChangeNotifier _provider;
  late final String Function() _location;
  late final AccountBloc _bloc;
  String _last = '';

  @override
  void initState() {
    super.initState();
    final router = GoRouter.of(context);
    _bloc = context.read<AccountBloc>();
    _provider = router.routeInformationProvider;
    _location = () => router.routeInformationProvider.value.uri.path;
    _last = _location();
    _provider.addListener(_onRoute);
  }

  void _onRoute() {
    final now = _location();
    final volvio = _last.startsWith(AppRoutes.enviar) && now == AppRoutes.home;
    _last = now;
    if (volvio) _bloc.add(const AccountEvent.refreshed());
  }

  @override
  void dispose() {
    _provider.removeListener(_onRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
