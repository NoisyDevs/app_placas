/// Fachada de guardado/compartir con diferencias de plataforma resueltas
/// vía conditional export (ARCHITECTURE.md §7), nunca con ramas `if
/// (kIsWeb)` desperdigadas por las features:
///
/// - Mobile (`share_service_io.dart`): guarda en la galería con `gal` y
///   comparte con el share sheet nativo (`share_plus`).
/// - Web (`share_service_web.dart`): descarga explícita por default
///   (anchor + blob), y ofrece compartir solo si el navegador expone la
///   Web Share API.
///
/// Las dos implementaciones exponen la misma API pública:
/// `Future<PlacaShareResult> savePlaca(Uint8List, {required String fileName})`,
/// `Future<PlacaShareResult> sharePlaca(Uint8List, {required String fileName})`
/// y `bool get supportsNativeShare`.
library;

export 'share_service_types.dart';
export 'share_service_io.dart' if (dart.library.js_interop) 'share_service_web.dart';
