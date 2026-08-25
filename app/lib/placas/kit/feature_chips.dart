import 'package:flutter/widgets.dart';

import '../../domain/placa_render_model.dart';

/// Un chip de característica ya resuelto a texto por el resolver ("3
/// ambientes", "Cochera"). El kit solo decide el layout (`Wrap`); el
/// template decide el look (color, borde, tipografía) vía [decoration] y
/// [textStyle] — nunca hardcodeados acá.
class PlacaChip extends StatelessWidget {
  const PlacaChip({
    super.key,
    required this.label,
    required this.textStyle,
    required this.decoration,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String label;
  final TextStyle textStyle;
  final BoxDecoration decoration;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: decoration,
      child: Text(label, style: textStyle),
    );
  }
}

/// Fila de chips que absorbe overflow con `Wrap` a una segunda línea, en
/// vez de reducir texto (esa es la política de [PlacaChip], no la de esta
/// fila) — ver ARCHITECTURE.md §2. El resolver ya recortó la cantidad de
/// chips vía `TemplateDescriptor.maxFeatureChips`.
class FeatureChipsRow extends StatelessWidget {
  const FeatureChipsRow({
    super.key,
    required this.chips,
    required this.chipBuilder,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
  });

  final List<FeatureChip> chips;
  final Widget Function(FeatureChip chip) chipBuilder;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: [for (final chip in chips) chipBuilder(chip)],
    );
  }
}
