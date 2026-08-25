import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'share_service_types.dart';

/// Implementación mobile de `services/share_service.dart` (ARCHITECTURE.md
/// §7): guarda en la galería con `gal` y comparte con el share sheet nativo
/// con `share_plus`. Nunca se importa directo — siempre vía
/// `share_service.dart`, que elige esta implementación o
/// `share_service_web.dart` con conditional export.

/// Guarda [bytes] (un PNG) en la galería del dispositivo.
Future<PlacaShareResult> savePlaca(Uint8List bytes, {required String fileName}) async {
  try {
    if (!await Gal.hasAccess(toAlbum: true)) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        return const PlacaShareResult.failure('Necesitamos permiso para guardar en tu galería.');
      }
    }
    await Gal.putImageBytes(bytes, name: fileName, album: 'Placas');
    return const PlacaShareResult.success('Guardada en tu galería.');
  } on GalException catch (e) {
    return PlacaShareResult.failure(e.type.message);
  } catch (e) {
    return PlacaShareResult.failure('No pudimos guardar la imagen: $e');
  }
}

/// Abre el share sheet nativo del sistema operativo con [bytes] (un PNG)
/// adjunto — el agente elige ahí a qué app enviarlo (WhatsApp, Instagram,
/// etc.). No hay forma confiable y multiplataforma de saltar directo a una
/// app puntual con una imagen adjunta sin pasar por este panel.
Future<PlacaShareResult> sharePlaca(Uint8List bytes, {required String fileName}) async {
  try {
    // `XFile.fromData(...).name` es ignorado por `cross_file` en mobile —
    // `fileNameOverrides` es lo que efectivamente nombra el archivo
    // compartido ahí (ver el docstring de `Share.shareXFiles` en share_plus).
    final file = XFile.fromData(bytes, mimeType: 'image/png', name: fileName);
    final result = await SharePlus.instance.share(
      ShareParams(files: [file], fileNameOverrides: [fileName]),
    );
    // `dismissed` = el usuario cerró el panel sin elegir nada: no es un
    // error de la app, no hay nada que mostrar como falla.
    if (result.status == ShareResultStatus.unavailable) {
      return const PlacaShareResult.failure('Compartir no está disponible en este dispositivo.');
    }
    return const PlacaShareResult.success();
  } catch (e) {
    return PlacaShareResult.failure('No pudimos abrir el panel de compartir: $e');
  }
}

/// Mobile siempre tiene share sheet nativo.
bool get supportsNativeShare => true;
