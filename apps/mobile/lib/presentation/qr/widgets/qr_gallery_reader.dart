import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Qué salió de buscar un QR en una imagen de la galería.
sealed class QrGalleryResult {
  const QrGalleryResult();
}

/// El usuario cerró el selector sin elegir nada: no es un error.
final class QrGalleryCancelled extends QrGalleryResult {
  const QrGalleryCancelled();
}

/// La imagen no tiene un QR legible.
final class QrGalleryNotFound extends QrGalleryResult {
  const QrGalleryNotFound();
}

final class QrGalleryFound extends QrGalleryResult {
  const QrGalleryFound(this.codigo);

  final String codigo;
}

/// Lee un QR de una imagen de la galería: el caso de quien recibe el QR de
/// cobro por WhatsApp en el mismo teléfono con el que va a pagar y no puede
/// apuntarle con la cámara.
///
/// En Android 13+ usa el selector de fotos del sistema, que no pide permiso.
/// Lo decodifica ML Kit (vía `mobile_scanner`), igual que la cámara.
Future<QrGalleryResult> leerQrDeGaleria() async {
  final imagen = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (imagen == null) return const QrGalleryCancelled();
  final controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  try {
    final captura = await controller.analyzeImage(
      imagen.path,
      formats: const [BarcodeFormat.qrCode],
    );
    final valor = captura?.barcodes.firstOrNull?.rawValue;
    if (valor == null || valor.isEmpty) return const QrGalleryNotFound();
    return QrGalleryFound(valor);
  } on Exception {
    // MobileScannerException si la imagen no se puede leer: para el usuario es
    // lo mismo que no encontrar un QR.
    return const QrGalleryNotFound();
  } finally {
    await controller.dispose();
  }
}
