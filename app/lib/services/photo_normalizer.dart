import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// Normaliza la orientación EXIF de una foto elegida (ARCHITECTURE.md §9.4):
/// no confiamos en que `Image.memory` respete el tag en todas las plataformas.
///
/// Es un no-op seguro: si los bytes no son un JPEG decodificable, o la
/// orientación falta o es 1, devuelve la MISMA instancia sin tocar. Nunca
/// lanza; ante cualquier error devuelve los bytes originales.
Uint8List normalizePhotoOrientationSync(Uint8List bytes) {
  try {
    final decoder = img.JpegDecoder();
    if (!decoder.isValidFile(bytes)) return bytes;
    // El orientation se lee del EXIF crudo: `decode` ya aplica la rotación y
    // limpia el tag, así que no se puede leer después de decodificar.
    final orientation = img.decodeJpgExif(bytes)?.imageIfd.orientation;
    if (orientation == null || orientation == 1) return bytes;

    final decoded = decoder.decode(bytes);
    if (decoded == null) return bytes;

    // Idempotente: si el decoder ya horneó la rotación, no hace nada más.
    final baked = img.bakeOrientation(decoded);
    baked.exif.imageIfd.orientation = null;
    return Uint8List.fromList(img.encodeJpg(baked, quality: 90));
  } catch (_) {
    return bytes;
  }
}

/// Versión asíncrona: corre en un isolate en mobile y inline en web.
Future<Uint8List> normalizePhotoOrientation(Uint8List bytes) {
  return compute(normalizePhotoOrientationSync, bytes);
}
