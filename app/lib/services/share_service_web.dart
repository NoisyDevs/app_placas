import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'share_service_types.dart';

/// Implementación web de `services/share_service.dart` (ARCHITECTURE.md
/// §7): descarga explícita por default (anchor + blob), y ofrece compartir
/// solo cuando el navegador expone la Web Share API. Usa `package:web` +
/// `dart:js_interop` — nunca `dart:html`, deprecado en el Dart de este
/// proyecto (3.13). Nunca se importa directo — siempre vía
/// `share_service.dart`.

/// Descarga [bytes] (un PNG) como archivo, vía un `<a download>` sintético
/// + blob URL. Es el "guardar" de la web: no hay galería del sistema a la
/// que escribir.
Future<PlacaShareResult> savePlaca(Uint8List bytes, {required String fileName}) async {
  try {
    _downloadBytes(bytes, fileName);
    return const PlacaShareResult.success('Descargada.');
  } catch (e) {
    return PlacaShareResult.failure('No pudimos descargar la imagen: $e');
  }
}

/// Si el navegador expone `navigator.share` con soporte para archivos,
/// abre el panel de compartir nativo del sistema operativo/navegador. Si
/// no, cae en la misma descarga explícita que [savePlaca] — es un
/// fallback útil, no un error.
Future<PlacaShareResult> sharePlaca(Uint8List bytes, {required String fileName}) async {
  final file = web.File(
    <JSAny>[bytes.toJS].toJS,
    fileName,
    web.FilePropertyBag(type: 'image/png'),
  );
  final data = web.ShareData(files: <web.File>[file].toJS);

  try {
    final navigator = web.window.navigator;
    // `canShare`/`share` existen en el binding siempre (vienen del WebIDL
    // completo), pero el navegador puede no implementarlos en runtime —
    // invocarlos ahí tira un TypeError de JS, que cae en el catch de abajo
    // y hace el mismo fallback a descarga.
    if (!navigator.canShare(data)) {
      return await savePlaca(bytes, fileName: fileName);
    }
    await navigator.share(data).toDart;
    return const PlacaShareResult.success();
  } catch (e) {
    // El usuario cancelando el panel también llega acá (AbortError) — no
    // es un error real, así que no vale la pena distinguirlo del caso
    // "el navegador no soporta esto": en ambos casos ya hicimos algo
    // razonable (descarga) o el usuario decidió no compartir.
    return await savePlaca(bytes, fileName: fileName);
  }
}

/// Solo informativo para la UI (mostrar u ocultar el tile de "Compartir"
/// directo): chequea la presencia de la Web Share API sin invocarla.
bool get supportsNativeShare => _hasNavigatorShare();

bool _hasNavigatorShare() {
  try {
    // `hasProperty` (dart:js_interop_unsafe) solo chequea existencia, sin
    // invocar nada — a diferencia de llamar `canShare()`, que si el
    // navegador no la implementa tira un TypeError de JS.
    return web.window.navigator.hasProperty('share'.toJS).toDart;
  } catch (_) {
    return false;
  }
}

void _downloadBytes(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
