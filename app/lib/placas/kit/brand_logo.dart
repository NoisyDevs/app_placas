import 'package:flutter/widgets.dart';

import 'brand_theme.dart';

/// Envoltorio de integridad del logo (CLAUDE.md — "RE/MAX logo integrity":
/// colores oficiales, nunca recortado/estirado). No expone ningún
/// parámetro de `fit`: es estructuralmente imposible pedirle `cover` o
/// `fill` — el único camino es `BoxFit.contain` dentro de un clearspace
/// mínimo, así la integridad no depende de que nadie se acuerde de
/// respetarla.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.brand,
    required this.height,
    this.light = false,
    this.clearspace = 0,
  });

  final BrandTheme brand;
  final double height;
  final bool light;
  final double clearspace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(clearspace),
      child: SizedBox(
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          child: brand.logo(context, light: light),
        ),
      ),
    );
  }
}
