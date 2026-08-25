import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' show GlobalKey;

import '../../domain/property_enums.dart';

/// Se lanza cuando la captura no puede completarse: la key no apunta a un
/// `RepaintBoundary` montado y pintado, o la codificación a PNG falla.
///
/// La causa más común (documentada en ARCHITECTURE.md §9, trampa 2) es
/// envolver el `PlacaCanvas` en un `Offstage: true` — ese patrón nunca
/// pinta, así que `RenderRepaintBoundary.toImage()` produce un frame vacío
/// o un tamaño cero. El `RepaintBoundary` que se le pasa a
/// [capturePlacaPng] tiene que ser el mismo que el usuario está viendo en
/// pantalla en ese momento.
class PlacaExportException implements Exception {
  PlacaExportException(this.message);

  final String message;

  @override
  String toString() => 'PlacaExportException: $message';
}

/// Captura el `RepaintBoundary` VISIBLE (identificado por [boundaryKey]) que
/// envuelve un `PlacaCanvas`, y devuelve un PNG a la resolución real del
/// canvas lógico del [format] — 1080×1080 (feed) o 1080×1920 (story) — sin
/// importar el tamaño con el que el preview se esté mostrando en pantalla.
///
/// `PlacaCanvas` (ver `placas/kit/placa_canvas.dart`) escala su canvas
/// lógico fijo con un `FittedBox` para que quepa en el espacio disponible
/// (chico en el wizard, más grande en desktop). El `pixelRatio` de acá es
/// exactamente lo que compensa esa escala — así el preview a 340pt de un
/// teléfono y el mismo preview a 700pt en desktop emiten los mismos
/// 1080px reales. Esto es lo que hace que "el preview SEA el output" sea
/// cierto por construcción (ARCHITECTURE.md §2, regla 3), no por
/// disciplina de que alguien no desalinee un factor de escala a mano.
Future<Uint8List> capturePlacaPng({
  required GlobalKey boundaryKey,
  required PlacaFormat format,
}) async {
  // Si la captura se dispara en el mismo tick en que cambió algo del
  // contenido (p. ej. justo después de un `setState`), el RenderObject
  // puede no haber terminado de pintar ese frame todavía. Esperar al fin
  // del frame actual evita una captura parcial/vieja.
  await SchedulerBinding.instance.endOfFrame;

  final renderObject = boundaryKey.currentContext?.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw PlacaExportException(
      'No se encontró un RepaintBoundary pintado para exportar. Verificá '
      'que la key apunte a un widget visible y montado — nunca a uno '
      'dentro de un Offstage: true (ver ARCHITECTURE.md §9).',
    );
  }

  if (!renderObject.hasSize) {
    throw PlacaExportException(
      'El RepaintBoundary todavía no se pintó — ¿está oculto o recién '
      'montado?',
    );
  }
  final displayedWidth = renderObject.size.width;
  if (displayedWidth <= 0) {
    throw PlacaExportException('El RepaintBoundary tiene tamaño cero.');
  }

  // El FittedBox de PlacaCanvas escala el canvas lógico fijo
  // (`format.width`×`format.height`) para que entre en el layout actual.
  // pixelRatio deshace esa escala: `capturedWidth = displayedWidth *
  // pixelRatio == format.width`. El alto sale correcto solo porque el
  // widget que se está capturando respeta la relación de aspecto exacta
  // del formato (1:1 o 9:16) — PlacaCanvas la fuerza con su SizedBox
  // interno, así que no hace falta (ni conviene) calcular un pixelRatio
  // distinto por eje.
  final pixelRatio = format.width / displayedWidth;

  final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
  try {
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw PlacaExportException('No se pudo codificar la placa capturada a PNG.');
    }
    return byteData.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
