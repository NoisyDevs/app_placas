import 'kit/template_registry.dart';
import 'packs/remax/remax_pack.dart';

/// Bootstrap del catálogo de templates activos. `features/**` importa
/// SOLO este archivo (nunca `packs/remax/**` directamente) para resolver
/// ids a widgets — ver ARCHITECTURE.md §2, regla 1, y la regla de
/// separación de marca en `test/architecture_test.dart` ("nada bajo
/// lib/app/** o lib/features/** puede importar lib/placas/packs/**").
///
/// MVP: `activePack = remaxTemplates()`. Sumar una marca nueva más
/// adelante es agregar su propia lista acá (o reemplazar esta línea por
/// una selección en runtime si el producto lo necesita).
final TemplateRegistry templateRegistry = TemplateRegistry()..registerAll(remaxTemplates());
