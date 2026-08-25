import 'package:flutter/widgets.dart';

/// Paleta + logo de UN pack de marca, inyectada al kit desde afuera. El kit
/// (`lib/placas/kit/**`) nunca declara colores ni logos propios — los
/// recibe acá. Ver ARCHITECTURE.md §2 "Separación de marca, forzada
/// mecánicamente": `test/architecture_test.dart` falla si aparece un color
/// o un miembro de la clase `Colors` escrito a mano bajo `lib/placas/kit/**`.
///
/// No es una paleta "de 3 colores": cada template de un pack puede tener su
/// propia composición (fondo claro, fondo oscuro, franja de color) — por
/// eso expone varios roles en vez de un solo `primary`/`secondary`.
@immutable
class BrandTheme {
  const BrandTheme({
    required this.primary,
    required this.secondary,
    required this.ink,
    required this.onDark,
    required this.surfaceLight,
    required this.surfaceCream,
    required this.surfaceDark,
    required this.highlight,
    required this.placeholderBg,
    required this.placeholderFg,
    required this.logo,
  });

  /// Color de marca #1 (ej. el rojo de un logo bicolor).
  final Color primary;

  /// Color de marca #2 (ej. el azul de un logo bicolor).
  final Color secondary;

  /// Texto/borde sobre fondos claros neutros (no es "negro" a secas: cada
  /// pack define su propio negro/tinta).
  final Color ink;

  /// Texto sobre fondos oscuros de marca.
  final Color onDark;

  final Color surfaceLight;
  final Color surfaceCream;
  final Color surfaceDark;

  /// Acento usado para resaltar datos de contacto sobre fondo oscuro (ej.
  /// el verde de WhatsApp en las franjas de contacto RE/MAX).
  final Color highlight;

  final Color placeholderBg;
  final Color placeholderFg;

  /// Construye el isotipo/wordmark de la marca. `light: true` pide la
  /// variante para fondo oscuro (texto claro); `light: false` la variante a
  /// color sobre fondo claro. Ver [BrandLogo] para el envoltorio que
  /// garantiza `BoxFit.contain`.
  final Widget Function(BuildContext context, {required bool light}) logo;
}
