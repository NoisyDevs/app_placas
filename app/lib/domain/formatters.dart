import 'package:intl/intl.dart';

import 'caracteristicas.dart';
import 'placa_render_model.dart';
import 'precio.dart';
import 'property_enums.dart';
import 'search_data.dart';

final NumberFormat _numeroEsAr = NumberFormat.decimalPattern('es_AR');

String _formatMonto(num monto) => _numeroEsAr.format(monto);

/// "USD 250.000" | "Consultar". Nunca `null`: en una publicación siempre
/// hay algo que mostrar en el bloque de precio.
String formatPrecio(Precio precio) {
  return switch (precio) {
    PrecioConsultar() => 'Consultar',
    PrecioMonto(:final monto, :final moneda) => '${moneda.prefijo} ${_formatMonto(monto)}',
  };
}

/// "USD 150.000 a 200.000" | "Desde USD 80.000" | "Hasta USD 150.000".
/// Soporta rangos abiertos porque [RangoPresupuesto] permite una sola punta.
String formatRangoPresupuesto(RangoPresupuesto rango) {
  final prefijo = rango.moneda.prefijo;
  final desde = rango.desde;
  final hasta = rango.hasta;

  if (desde != null && hasta != null) {
    return '$prefijo ${_formatMonto(desde)} a ${_formatMonto(hasta)}';
  }
  if (desde != null) {
    return 'Desde $prefijo ${_formatMonto(desde)}';
  }
  return 'Hasta $prefijo ${_formatMonto(hasta!)}';
}

String _pluralize(int n, String singular, String plural) => '$n ${n == 1 ? singular : plural}';

/// Convierte [Caracteristicas] en chips ya resueltos a texto y recortados a
/// `maxChips` — ver ARCHITECTURE.md §2: el resolver decide QUÉ se muestra,
/// el template (`PlacaChip` + `Wrap`) solo decide CÓMO entra en el layout.
List<FeatureChip> buildFeatureChips(Caracteristicas c, {required int maxChips}) {
  final chips = <FeatureChip>[
    if (c.ambientes != null) FeatureChip(_pluralize(c.ambientes!, 'ambiente', 'ambientes')),
    if (c.dormitorios != null) FeatureChip(_pluralize(c.dormitorios!, 'dormitorio', 'dormitorios')),
    if (c.banos != null) FeatureChip(_pluralize(c.banos!, 'baño', 'baños')),
    if (c.superficieM2 != null) FeatureChip('${_formatMonto(c.superficieM2!)} m²'),
    if (c.cochera == true) const FeatureChip('Cochera'),
  ];

  if (chips.length <= maxChips) return chips;
  return chips.sublist(0, maxChips);
}
