// Genera los íconos de los flavors `local` y `mock` a partir del logo de
// producción, para distinguir las tres apps instaladas en el mismo teléfono.
//
// Uso (en apps/mobile):
//   dart run tool/flavor_icons.dart     # escribe assets/icons/<flavor>/
//   dart run flutter_launcher_icons     # los lleva a android/app/src/<flavor>/res
//
// Producción no cambia: usa assets/app_icon*.png tal cual (pubspec.yaml).

import 'dart:io';

import 'package:image/image.dart' as img;

/// Fondo y texto de cada flavor. El color se elige para que, sin leer nada,
/// el ícono ya no se confunda con el verde oscuro de producción.
const _flavors = {
  'local': (fondo: 0xFF1F4E8C, etiqueta: 'LOCAL'),
  'mock': (fondo: 0xFF5F5E5A, etiqueta: 'MOCK'),
};

void main() {
  final completo = img.decodePng(File('assets/app_icon.png').readAsBytesSync())!;
  final frente =
      img.decodePng(File('assets/app_icon_foreground.png').readAsBytesSync())!;

  for (final MapEntry(key: flavor, value: estilo) in _flavors.entries) {
    final dir = Directory('assets/icons/$flavor')..createSync(recursive: true);
    final fondo = _color(estilo.fondo);

    // Ícono clásico (Android < 8): el logo sobre el fondo del flavor.
    final clasico = img.Image(width: completo.width, height: completo.height)
      ..clear(fondo);
    img.compositeImage(clasico, frente);
    _etiqueta(clasico, estilo.etiqueta, fondo);
    File('${dir.path}/app_icon.png').writeAsBytesSync(img.encodePng(clasico));

    // Primer plano del ícono adaptativo (Android 8+): el fondo lo pone el
    // color del flavor; aquí van el logo y la etiqueta, dentro de la zona
    // segura (el 66 % central), para que ninguna máscara la recorte.
    final adaptativo = img.Image(
      width: frente.width,
      height: frente.height,
      numChannels: 4,
    );
    img.compositeImage(adaptativo, frente);
    _etiqueta(adaptativo, estilo.etiqueta, fondo);
    File('${dir.path}/app_icon_foreground.png')
        .writeAsBytesSync(img.encodePng(adaptativo));

    stdout.writeln('assets/icons/$flavor/: listo');
  }
}

img.Color _color(int argb) => img.ColorRgba8(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
      (argb >> 24) & 0xFF,
    );

/// Una cinta clara con el nombre del flavor, bajo el logo. El texto se dibuja
/// en pequeño con la fuente de mapa de bits y se amplía: a tamaño de
/// lanzador no se nota, y evita depender de fuentes del sistema.
void _etiqueta(img.Image destino, String texto, img.Color fondo) {
  const anchoCinta = 520;
  const altoCinta = 120;
  final x = (destino.width - anchoCinta) ~/ 2;
  const y = 740;

  img.fillRect(
    destino,
    x1: x,
    y1: y,
    x2: x + anchoCinta,
    y2: y + altoCinta,
    color: img.ColorRgba8(243, 241, 234, 255),
    radius: 24,
  );

  // Texto en un lienzo chico, luego ampliado para que llene la cinta.
  final chico = img.Image(width: 260, height: 60, numChannels: 4);
  img.drawString(chico, texto,
      font: img.arial48, x: 0, y: 4, color: fondo);
  final ancho = _anchoUsado(chico);
  final recorte = img.copyCrop(chico, x: 0, y: 0, width: ancho, height: 60);
  final alto = altoCinta - 30;
  final grande = img.copyResize(
    recorte,
    height: alto,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    destino,
    grande,
    dstX: x + (anchoCinta - grande.width) ~/ 2,
    dstY: y + (altoCinta - grande.height) ~/ 2,
  );
}

/// Hasta qué columna hay tinta: para centrar el texto de verdad.
int _anchoUsado(img.Image imagen) {
  for (var x = imagen.width - 1; x >= 0; x--) {
    for (var y = 0; y < imagen.height; y++) {
      if (imagen.getPixel(x, y).a > 0) return x + 2;
    }
  }
  return imagen.width;
}
