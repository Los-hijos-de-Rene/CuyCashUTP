import 'dart:async';

import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Aviso de "estamos verificando tu PIN", para colocar bajo las casillas.
///
/// El PIN se envía solo al marcar el sexto dígito: no hay botón que se quede
/// hundido ni teclado que se cierre, así que sin este aviso la pantalla se
/// queda idéntica mientras viaja la petición y el salto a la siguiente llega
/// sin anunciarse. Quien la usa no sabe si su último dígito se registró.
///
/// La segunda línea aparece sola cuando la espera se alarga. Existe porque el
/// backend puede estar suspendido —planes gratuitos apagan el servicio sin
/// tráfico— y el primer ingreso del día tarda cerca de un minuto: una rueda
/// girando todo ese rato se lee como que la app se colgó, y la diferencia
/// entre "no responde" y "está tardando" es justo lo que evita que el usuario
/// mate la app y lo intente otra vez.
class PinSubmittingNotice extends StatefulWidget {
  const PinSubmittingNotice({
    required this.label,
    this.patienceLabel,
    this.patienceAfter = const Duration(seconds: 4),
    super.key,
  });

  /// Primera línea, visible desde el inicio.
  final String label;

  /// Segunda línea, para esperas largas. Sin ella no aparece nada extra.
  final String? patienceLabel;

  final Duration patienceAfter;

  @override
  State<PinSubmittingNotice> createState() => _PinSubmittingNoticeState();
}

class _PinSubmittingNoticeState extends State<PinSubmittingNotice> {
  Timer? _timer;
  bool _paciencia = false;

  @override
  void initState() {
    super.initState();
    if (widget.patienceLabel != null) {
      _timer = Timer(widget.patienceAfter, () {
        if (mounted) setState(() => _paciencia = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patienceLabel = widget.patienceLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CuyCashColors.primaryContainer,
              ),
            ),
            const SizedBox(width: CuyCashSpacing.stackSm),
            Expanded(
              child: Text(
                widget.label,
                style: CuyCashTypography.labelSm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CuyCashColors.primaryContainer,
                ),
              ),
            ),
          ],
        ),
        if (_paciencia && patienceLabel != null) ...[
          const SizedBox(height: CuyCashSpacing.stackXs),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              patienceLabel,
              style: CuyCashTypography.labelSm,
            ),
          ),
        ],
      ],
    );
  }
}
