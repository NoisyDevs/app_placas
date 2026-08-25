import '../../../domain/property_enums.dart';
import '../../kit/placa_template.dart';
import 'templates/bold_v1.dart';
import 'templates/clasico_v1.dart';
import 'templates/editorial_v1.dart';
import 'templates/franja_v1.dart';
import 'templates/minimal_v1.dart';

/// El único pack de marca del MVP (CLAUDE.md: RE/MAX es el primer pack de
/// templates, no el theme de la app). Agregar una marca nueva más adelante
/// = una carpeta nueva bajo `packs/` + una lista como esta, registrada en
/// `lib/placas/registry.dart` (ARCHITECTURE.md §2).
///
/// Cada uno de los 5 diseños se registra dos veces (una por `PlacaKind`)
/// porque `TemplateDescriptor` está atado a un solo `kind` — ver el
/// `assert` en `template_descriptor.dart`. Visualmente comparten el mismo
/// layout; lo único que cambia es `photoSlots`/`illustrations`, que
/// resuelve el propio resolver.
List<PlacaTemplate> remaxTemplates() => [
      for (final kind in PlacaKind.values) ...[
        ClasicoTemplate(kind: kind),
        MinimalTemplate(kind: kind),
        FranjaTemplate(kind: kind),
        BoldTemplate(kind: kind),
        EditorialTemplate(kind: kind),
      ],
    ];
