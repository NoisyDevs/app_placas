import '../../domain/template_descriptor.dart';
import 'placa_template.dart';

/// Registro de templates de TODOS los packs activos. Es lo único que las
/// features del wizard importan de `placas/` para resolver un id a un
/// widget real — así `features/**` nunca necesita importar
/// `placas/packs/remax/**` directamente (regla de separación de marca, ver
/// ARCHITECTURE.md §2 y `test/architecture_test.dart`).
class TemplateRegistry {
  final Map<String, PlacaTemplate> _byId = {};

  void register(PlacaTemplate template) {
    _byId[template.descriptor.id] = template;
  }

  void registerAll(Iterable<PlacaTemplate> templates) {
    for (final t in templates) {
      register(t);
    }
  }

  PlacaTemplate byId(String id) {
    final template = _byId[id];
    if (template == null) {
      throw ArgumentError('Template desconocido: "$id"');
    }
    return template;
  }

  TemplateDescriptor descriptorById(String id) => byId(id).descriptor;

  /// Catálogo completo, en el orden en que se registraron los templates —
  /// es lo que consume la pantalla "Elegí un template".
  List<TemplateDescriptor> get catalog =>
      _byId.values.map((t) => t.descriptor).toList(growable: false);
}
