import 'dart:typed_data';

import 'caracteristicas.dart';
import 'precio.dart';
import 'property_enums.dart';

/// Datos de una placa de "publicación" (propiedad concreta). ONE-SHOT por
/// diseño: no tiene `id`, no tiene `agentId`, no tiene repositorio ni
/// serializador de persistencia — no hay tabla en Postgres para esto (ver
/// ARCHITECTURE.md §3). Se usa para renderizar y se descarta.
///
/// Para agregar cartera persistente más adelante (fuera del MVP), la
/// identidad de persistencia debe ENVOLVER este value object —
/// `SavedProperty { id, agentId, PropertyData data, createdAt }` — en vez
/// de que `PropertyData` le crezca un id. Eso es lo que evita un rework.
class PropertyData {
  const PropertyData({
    required this.operacion,
    required this.tipo,
    required this.precio,
    required this.zona,
    required this.caracteristicas,
    this.fotos = const [],
  });

  final Operacion operacion;
  final TipoPropiedad tipo;
  final Precio precio;

  /// Zona/barrio, NUNCA la dirección exacta (Historia 2.1).
  final String zona;

  final Caracteristicas caracteristicas;

  /// Bytes en memoria, nunca una URL ni una ruta en disco: las fotos de
  /// propiedad no se suben a ningún backend y no se persisten. Esto es lo
  /// que hace cierto por construcción que son "efímeras" (ver
  /// ARCHITECTURE.md §0, regla dura).
  final List<Uint8List> fotos;
}
