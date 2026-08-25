import 'package:flutter/widgets.dart';

import '../../domain/property_enums.dart';

/// Canvas lógico fijo + escala (ARCHITECTURE.md §2, regla 3): cada template
/// se dibuja siempre sobre 1080×1080 (feed) o 1080×1920 (story) — ningún
/// valor de diseño dentro de un template es responsive. `PlacaCanvas` solo
/// escala ese canvas fijo con `FittedBox` para que quepa en el espacio
/// disponible (preview chico en el wizard, grande en desktop); el
/// exportador (`placas/export/`) captura el mismo widget con un
/// `pixelRatio` que compensa la escala para emitir siempre 1080px reales.
class PlacaCanvas extends StatelessWidget {
  const PlacaCanvas({super.key, required this.format, required this.child});

  final PlacaFormat format;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: format.width.toDouble(),
        height: format.height.toDouble(),
        child: child,
      ),
    );
  }
}
