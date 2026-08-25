import 'property_enums.dart';

/// Topes de caracteres por campo, publicados por el template y consumidos
/// por el FORMULARIO del wizard (contador en vivo, "Zona (máx. 34)") — la
/// primera de las cuatro capas de defensa contra overflow de texto (ver
/// ARCHITECTURE.md §2). El widget del template además reduce con
/// shrink-to-fit como segunda capa; esto no reemplaza eso, lo antecede.
class TemplateLimits {
  const TemplateLimits({
    this.zonaMaxChars = 40,
    this.tipoLabelMaxChars = 24,
  });

  final int zonaMaxChars;
  final int tipoLabelMaxChars;
}

/// Descriptor puro de un template. Es lo único que ven el catálogo y el
/// formulario — nunca el widget de Flutter real, que solo se obtiene vía
/// `TemplateRegistry.byId()` en la capa `placas/` (ver ARCHITECTURE.md §2,
/// regla 1). Vive en tiempo de compilación como `const`, no en una tabla:
/// una tabla permitiría que el código y la data no coincidan en cuántos
/// slots de foto tiene un template.
class TemplateDescriptor {
  const TemplateDescriptor({
    required this.id,
    required this.packId,
    required this.nombre,
    required this.kind,
    required this.formats,
    required this.thumbAsset,
    this.photoSlots = 1,
    this.minPhotos = 0,
    this.maxFeatureChips = 4,
    this.requiresMatricula = false,
    this.limits = const TemplateLimits(),
    this.illustrations = const {},
  })  : assert(photoSlots >= minPhotos),
        assert(kind != PlacaKind.busqueda || photoSlots == 0,
            'Un template de búsqueda no tiene slots de foto: usa illustrations');
  // Nota: "formats no puede estar vacío" también debería valer acá, pero
  // Dart no admite `Set.isNotEmpty` como expresión constante dentro del
  // initializer list de un constructor const (a diferencia de las
  // comparaciones de int/enum de arriba, que sí lo son) — y este
  // constructor tiene que seguir siendo const porque cada template se
  // define como `const TemplateDescriptor(...)`. Queda como invariante
  // documentada, no verificada en compile-time.

  /// Ej. "remax.hero_v1" — namespaced por pack para que dos brand packs
  /// nunca choquen de id.
  final String id;
  final String packId;
  final String nombre;
  final PlacaKind kind;
  final Set<PlacaFormat> formats;
  final String thumbAsset;

  final int photoSlots;
  final int minPhotos;
  final int maxFeatureChips;

  /// Historia 1.2 / 2.6: legal, no estilística — si es `true`, la matrícula
  /// se estampa aunque `PlacaSpec.includeContact` esté en `false`.
  final bool requiresMatricula;

  final TemplateLimits limits;

  /// Solo aplica a templates `kind == busqueda`: qué ilustración usar según
  /// [TipoPropiedad]. Vive acá (dato del template/pack) y no hardcodeada en
  /// el resolver, porque la ilustración es contenido de marca — otro pack
  /// puede traer un set totalmente distinto. Ver "Preguntas abiertas" del
  /// doc de requerimientos sobre el origen/licencia de estas imágenes.
  final Map<TipoPropiedad, String> illustrations;
}
