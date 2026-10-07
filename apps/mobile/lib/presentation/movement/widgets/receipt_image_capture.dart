import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'receipt_card.dart';
import 'receipt_paper.dart';

/// Dibuja la constancia fuera de pantalla y la devuelve como PNG.
Future<Uint8List> captureReceiptPng(
  BuildContext context,
  ReceiptCard card,
) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  await precacheImage(const AssetImage(ReceiptPaper.logoAsset), context);
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -ReceiptPaper.width - 100,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: key,
          child: ReceiptPaper(card: card, forImage: true),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    // Dos cuadros: uno para montar y otro para pintar.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  } finally {
    entry.remove();
  }
}
