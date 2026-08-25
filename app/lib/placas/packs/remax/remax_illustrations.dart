import '../../../domain/property_enums.dart';

/// Ilustración de placeholder por tipo de propiedad, para templates de
/// búsqueda (`TemplateDescriptor.illustrations` — ver ARCHITECTURE.md §3).
/// Los 8 `TipoPropiedad` están cubiertos: el resolver tira `StateError` si
/// falta alguno. Las claves son símbolos internos, no rutas de archivo
/// reales todavía — ver `remax_photo.dart`.
const Map<TipoPropiedad, String> remaxIllustrations = {
  TipoPropiedad.casa: 'remax/illustration/casa',
  TipoPropiedad.departamento: 'remax/illustration/departamento',
  TipoPropiedad.ph: 'remax/illustration/ph',
  TipoPropiedad.lote: 'remax/illustration/lote',
  TipoPropiedad.local: 'remax/illustration/local',
  TipoPropiedad.oficina: 'remax/illustration/oficina',
  TipoPropiedad.cochera: 'remax/illustration/cochera',
  TipoPropiedad.campo: 'remax/illustration/campo',
};
