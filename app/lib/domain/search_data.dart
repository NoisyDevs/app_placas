import 'caracteristicas.dart';
import 'property_enums.dart';

/// Rango de presupuesto de una búsqueda. Opcional en sí mismo (Historia
/// 2.5: "rango de presupuesto (opcional)"), y cada punta también es
/// opcional para permitir rangos abiertos ("hasta USD 150.000", "desde
/// USD 80.000"). Al menos una punta tiene que estar presente: si no hay
/// ninguna, no se crea el objeto (el campo `presupuesto` de [SearchData]
/// queda `null`).
class RangoPresupuesto {
  const RangoPresupuesto({
    required this.moneda,
    this.desde,
    this.hasta,
  })  : assert(desde != null || hasta != null,
            'Si no hay desde ni hasta, no se debe crear un RangoPresupuesto'),
        assert(desde == null || hasta == null || desde <= hasta,
            'desde no puede ser mayor que hasta');

  final Moneda moneda;
  final num? desde;
  final num? hasta;
}

/// Datos de una placa de "búsqueda" ("busco para un cliente"). Igual que
/// [PropertyData], es one-shot: no persiste.
class SearchData {
  const SearchData({
    required this.operacion,
    required this.tipo,
    required this.zona,
    this.presupuesto,
    this.deseadas = const Caracteristicas(),
  });

  final OperacionBuscada operacion;
  final TipoPropiedad tipo;
  final String zona;
  final RangoPresupuesto? presupuesto;
  final Caracteristicas deseadas;
}
