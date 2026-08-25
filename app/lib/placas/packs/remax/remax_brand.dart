import 'package:flutter/material.dart';

import '../../kit/brand_theme.dart';

/// Colores oficiales RE/MAX como const — el ÚNICO lugar donde existen (ver
/// ARCHITECTURE.md §2, "Separación de marca, forzada mecánicamente").
/// Ningún archivo bajo `lib/app/**`, `lib/features/**` o `lib/placas/kit/**`
/// debe importar este archivo ni declarar estos valores.
abstract final class RemaxBrand {
  static const red = Color(0xFFE4002B);
  static const blue = Color(0xFF003DA5);
  static const navy = Color(0xFF0B1B3A);
  static const cream = Color(0xFFF7F5F0);
  static const ink = Color(0xFF12141A);
  static const white = Color(0xFFFFFFFF);
  static const whatsappGreen = Color(0xFF9FE870);
  static const placeholderBg = Color(0xFFE8EAEE);
  static const placeholderFg = Color(0xFFAAB0BB);

  static final theme = BrandTheme(
    primary: red,
    secondary: blue,
    ink: ink,
    onDark: white,
    surfaceLight: white,
    surfaceCream: cream,
    surfaceDark: navy,
    highlight: whatsappGreen,
    placeholderBg: placeholderBg,
    placeholderFg: placeholderFg,
    logo: _remaxLogo,
  );

  static Widget _remaxLogo(BuildContext context, {required bool light}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Column(
              children: [
                Expanded(child: ColoredBox(color: red)),
                Expanded(child: ColoredBox(color: white)),
                Expanded(child: ColoredBox(color: blue)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (light)
          const Text('RE/MAX', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: white))
        else
          RichText(
            text: const TextSpan(
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              children: [
                TextSpan(text: 'RE', style: TextStyle(color: blue)),
                TextSpan(text: '/MAX', style: TextStyle(color: red)),
              ],
            ),
          ),
      ],
    );
  }
}

/// El canvas lógico de una placa es siempre 1080px de ancho (feed 1080x1080,
/// story 1080x1920 — ver ARCHITECTURE.md §2, regla 3), así que `1cqw` del
/// mockup original (1% del ancho del contenedor) es siempre `10.8px`
/// lógicos, sin importar el formato. Los templates de este pack están
/// medidos en cqw contra `Placa.dc.html` y convertidos con este factor.
double cqw(double value) => value * 10.8;
