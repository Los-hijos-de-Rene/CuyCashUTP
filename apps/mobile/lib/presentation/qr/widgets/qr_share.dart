import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Comparte como IMAGEN PNG lo que pinta el `RepaintBoundary` de [tarjeta].
///
/// Una imagen, no el texto del token: es lo que se puede escanear desde otra
/// pantalla o subir desde la galería, y el token no es algo que el usuario
/// deba ver ni copiar. [texto] acompaña la imagen y no lleva el token.
///
/// Devuelve `false` si no se pudo preparar o compartir la imagen.
Future<bool> compartirTarjetaQr({
  required GlobalKey tarjeta,
  required String texto,
  required String archivo,
  Rect? origen,
}) async {
  final render = tarjeta.currentContext?.findRenderObject();
  if (render is! RenderRepaintBoundary) return false;
  try {
    // x3: nítida en cualquier pantalla y legible si WhatsApp la comprime.
    final imagen = await render.toImage(pixelRatio: 3);
    final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    if (png == null) return false;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png')],
        // El nombre de `XFile.fromData` se ignora en casi todas las
        // plataformas; este es el que se usa.
        fileNameOverrides: [archivo],
        text: texto,
        // En iPad la hoja de compartir necesita un ancla.
        sharePositionOrigin: origen,
      ),
    );
    return true;
  } on Object {
    return false;
  }
}

/// Rectángulo de [context] en pantalla: el ancla de la hoja de compartir.
Rect? origenDeCompartir(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
