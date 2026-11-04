import 'dart:async';

import 'package:flutter/material.dart';

/// Vigila la inactividad del usuario y avisa una sola vez cuando se agota
/// [timeout].
///
/// - Cada toque (o arrastre) reinicia la cuenta.
/// - Si la app pasa a segundo plano, el temporizador se detiene y al volver se
///   compara el tiempo transcurrido: si superó [timeout], avisa sin esperar.
/// - Con [enabled] en `false` no cuenta (login, acceso rápido, registro).
class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    required this.timeout,
    required this.onTimeout,
    required this.child,
    this.enabled = true,
    this.clock,
    super.key,
  });

  final Duration timeout;
  final VoidCallback onTimeout;
  final Widget child;
  final bool enabled;

  /// Reloj inyectable para las pruebas de ciclo de vida.
  final DateTime Function()? clock;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _backgroundedAt;
  bool _fired = false;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  @override
  void didUpdateWidget(InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.timeout != widget.timeout) {
      _restart();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _fired = false;
    if (!widget.enabled) return;
    _timer = Timer(widget.timeout, _fire);
  }

  void _fire() {
    if (!mounted || !widget.enabled || _fired) return;
    _fired = true;
    widget.onTimeout();
  }

  void _onInteraction(PointerEvent event) {
    if (!widget.enabled) return;
    _restart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // `inactive` también llega al abrir una hoja del sistema: se guarda el
        // primer instante y no se pisa con los estados siguientes.
        _backgroundedAt ??= _now;
        _timer?.cancel();
      case AppLifecycleState.resumed:
        final desde = _backgroundedAt;
        _backgroundedAt = null;
        if (desde != null && _now.difference(desde) >= widget.timeout) {
          _fire();
        } else {
          _restart();
        }
      case AppLifecycleState.detached:
        _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onInteraction,
      onPointerMove: _onInteraction,
      child: widget.child,
    );
  }
}
