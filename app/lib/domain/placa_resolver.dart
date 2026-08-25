import 'agent_profile.dart';
import 'formatters.dart';
import 'placa_render_model.dart';
import 'placa_spec.dart';
import 'property_data.dart';
import 'property_enums.dart';
import 'search_data.dart';
import 'template_descriptor.dart';

/// El corazón del motor de templates (ARCHITECTURE.md §2, regla 2): toda la
/// lógica de negocio de una placa vive ACÁ, en Dart puro, antes de que
/// cualquier widget de Flutter la vea. Si algo puede resolverse en tiempo
/// de datos (qué mostrar, qué ocultar, cómo formatear), se resuelve acá y
/// nunca en el árbol de widgets.
///
/// Reglas que esta función encierra en un solo lugar, para que ningún
/// template las tenga que repetir ni se pueda olvidar de una:
///  - campos vacíos de [Caracteristicas] nunca llegan al template: se
///    convierten en una lista de 0..N chips (ver [buildFeatureChips]).
///  - el contacto apagado y la matrícula requerida son independientes por
///    construcción: `contacto` y `matricula` se calculan por separado, así
///    que "matrícula sobrevive aunque el contacto esté oculto" no depende
///    de que nadie se acuerde de escribir ese caso en el template.
///  - una búsqueda nunca tiene fotos: siempre resuelve a exactamente una
///    ilustración de placeholder tomada del propio template/pack.
PlacaRenderModel resolvePlaca({
  required PlacaSpec spec,
  required AgentProfile profile,
  required TemplateDescriptor template,
  required PlacaFormat format,
}) {
  if (spec.templateId != template.id) {
    throw ArgumentError(
      'PlacaSpec pide el template "${spec.templateId}" pero se pasó "${template.id}"',
    );
  }
  if (!template.formats.contains(format)) {
    throw ArgumentError('El template "${template.id}" no soporta el formato $format');
  }
  if (spec.content.kind != template.kind) {
    throw ArgumentError(
      'El template "${template.id}" es de tipo ${template.kind}, '
      'pero la placa es de tipo ${spec.content.kind}',
    );
  }

  final content = spec.content;
  return switch (content) {
    PublicacionContent(:final data) => _resolvePublicacion(
        data: data,
        profile: profile,
        template: template,
        format: format,
        includeContact: spec.includeContact,
      ),
    BusquedaContent(:final data) => _resolveBusqueda(
        data: data,
        profile: profile,
        template: template,
        format: format,
        includeContact: spec.includeContact,
      ),
  };
}

PlacaRenderModel _resolvePublicacion({
  required PropertyData data,
  required AgentProfile profile,
  required TemplateDescriptor template,
  required PlacaFormat format,
  required bool includeContact,
}) {
  final images = data.fotos.take(template.photoSlots).map(PlacaFoto.new).toList(growable: false);

  return PlacaRenderModel(
    format: format,
    kind: PlacaKind.publicacion,
    kicker: data.operacion.kickerPublicacion,
    tipoLabel: data.tipo.label,
    zona: data.zona,
    precioLine: formatPrecio(data.precio),
    chips: buildFeatureChips(data.caracteristicas, maxChips: template.maxFeatureChips),
    images: images,
    contacto: includeContact ? _contactBlockFrom(profile) : null,
    matricula: template.requiresMatricula ? profile.matricula : null,
  );
}

PlacaRenderModel _resolveBusqueda({
  required SearchData data,
  required AgentProfile profile,
  required TemplateDescriptor template,
  required PlacaFormat format,
  required bool includeContact,
}) {
  final illustrationPath = template.illustrations[data.tipo];
  if (illustrationPath == null) {
    throw StateError(
      'El template "${template.id}" no tiene ilustración para ${data.tipo}. '
      'Los templates de búsqueda deben cubrir todos los TipoPropiedad.',
    );
  }

  final presupuesto = data.presupuesto;

  return PlacaRenderModel(
    format: format,
    kind: PlacaKind.busqueda,
    kicker: data.operacion.kickerBusqueda,
    tipoLabel: data.tipo.label,
    zona: data.zona,
    precioLine: presupuesto == null ? null : formatRangoPresupuesto(presupuesto),
    chips: buildFeatureChips(data.deseadas, maxChips: template.maxFeatureChips),
    images: [PlacaIlustracion(illustrationPath)],
    contacto: includeContact ? _contactBlockFrom(profile) : null,
    matricula: template.requiresMatricula ? profile.matricula : null,
  );
}

ContactBlock _contactBlockFrom(AgentProfile profile) => ContactBlock(
      nombre: profile.nombre,
      whatsapp: profile.whatsapp,
      redSocial: profile.redSocial,
      fotoPath: profile.fotoPath,
    );
