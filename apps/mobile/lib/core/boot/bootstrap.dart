import 'dart:async';

import 'package:flutter/material.dart';

/// Entrypoint genérico: inicializa bindings y monta el árbol dentro de una zona
/// guardada. Cada `main_<flavor>` le pasa el builder de su `AppRoot`.
Future<void> bootstrap(Future<Widget> Function() builder) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(await builder());
  }, (error, stack) {
    debugPrint('[bootstrap] error no capturado: $error');
  });
}
