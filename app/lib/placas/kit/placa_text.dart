import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/widgets.dart';

/// Política "precio" (ARCHITECTURE.md §2, "Overflow de texto"): una sola
/// línea, shrink-to-fit, ELLIPSIS PROHIBIDO — un precio truncado ("USD
/// 250.0…") es peor que uno chico. `style` debe venir completamente
/// resuelto por el template (color, familia tipográfica): el kit no elige
/// ninguno de los dos.
class PlacaHeadline extends StatelessWidget {
  const PlacaHeadline(
    this.text, {
    super.key,
    required this.style,
    this.minFontSize = 10,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style,
      maxLines: 1,
      minFontSize: minFontSize,
      overflowReplacement: Text(text, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
      textAlign: textAlign,
    );
  }
}

/// Política "label" (zona, línea de tipo…): shrink hasta un piso y recién
/// ahí ellipsis, hasta 2 líneas — zonas como "Barrio Parque Leloir,
/// Ituzaingó" son de longitud no acotada.
class PlacaLabel extends StatelessWidget {
  const PlacaLabel(
    this.text, {
    super.key,
    required this.style,
    this.minFontSize = 8,
    this.maxLines = 2,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style,
      maxLines: maxLines,
      minFontSize: minFontSize,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}
