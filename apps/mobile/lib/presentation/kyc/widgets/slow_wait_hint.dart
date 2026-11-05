import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Aviso que aparece solo si la espera se alarga.
///
/// El servicio de verificación arranca en frío (~1 min en el plan gratuito):
/// un spinner mudo parece una app colgada. Pasado [after], explica qué pasa.
/// Antes de eso no ocupa lugar ni distrae. Se monta al empezar la espera y se
/// desmonta al terminar, así que el contador arranca y se cancela solo.
class SlowWaitHint extends StatefulWidget {
  const SlowWaitHint({
    required this.message,
    required this.color,
    this.after = const Duration(seconds: 8),
    super.key,
  });

  final String message;
  final Color color;
  final Duration after;

  @override
  State<SlowWaitHint> createState() => _SlowWaitHintState();
}

class _SlowWaitHintState extends State<SlowWaitHint> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.after, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Text(
        widget.message,
        textAlign: TextAlign.center,
        style: CuyCashTypography.labelSm.copyWith(color: widget.color),
      ),
    );
  }
}
