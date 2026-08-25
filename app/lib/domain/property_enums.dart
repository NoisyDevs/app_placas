// Enums del dominio y sus etiquetas es-AR. Las etiquetas viven acá (no en
// el resolver ni en la UI) porque las usan ambos: el resolver arma
// `PlacaRenderModel.kicker`/`tipoLabel` con ellas, y el catálogo/formulario
// del wizard las usa para los selectores.

enum Operacion { venta, alquiler }

extension OperacionLabel on Operacion {
  /// Texto de "kicker" para una placa de publicación, ej. "VENTA".
  String get kickerPublicacion => switch (this) {
        Operacion.venta => 'VENTA',
        Operacion.alquiler => 'ALQUILER',
      };
}

enum OperacionBuscada { compra, alquiler }

extension OperacionBuscadaLabel on OperacionBuscada {
  /// Texto de "kicker" para una placa de búsqueda, ej. "BUSCO PARA COMPRAR".
  String get kickerBusqueda => switch (this) {
        OperacionBuscada.compra => 'BUSCO PARA COMPRAR',
        OperacionBuscada.alquiler => 'BUSCO PARA ALQUILAR',
      };
}

enum TipoPropiedad {
  casa,
  departamento,
  ph,
  lote,
  local,
  oficina,
  cochera,
  campo,
}

extension TipoPropiedadLabel on TipoPropiedad {
  String get label => switch (this) {
        TipoPropiedad.casa => 'Casa',
        TipoPropiedad.departamento => 'Departamento',
        TipoPropiedad.ph => 'PH',
        TipoPropiedad.lote => 'Lote',
        TipoPropiedad.local => 'Local',
        TipoPropiedad.oficina => 'Oficina',
        TipoPropiedad.cochera => 'Cochera',
        TipoPropiedad.campo => 'Campo',
      };
}

enum Moneda { usd, ars }

extension MonedaLabel on Moneda {
  String get prefijo => switch (this) {
        Moneda.usd => 'USD',
        Moneda.ars => r'$',
      };
}

/// Formato de exportación. Los valores son el lado corto del canvas lógico
/// en píxeles — ver ARCHITECTURE.md §2, "canvas lógico fijo + escala".
enum PlacaFormat { feed, story }

extension PlacaFormatSize on PlacaFormat {
  int get width => switch (this) {
        PlacaFormat.feed => 1080,
        PlacaFormat.story => 1080,
      };

  int get height => switch (this) {
        PlacaFormat.feed => 1080,
        PlacaFormat.story => 1920,
      };
}

enum PlacaKind { publicacion, busqueda }
