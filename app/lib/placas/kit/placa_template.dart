import 'package:flutter/widgets.dart';

import '../../domain/placa_render_model.dart';
import '../../domain/property_enums.dart';
import '../../domain/template_descriptor.dart';

/// Contrato que implementa cada template de cada pack. La app nunca ve
/// píxeles fuera de esto: el catálogo/formulario razonan sobre
/// [TemplateDescriptor] (dato puro) y solo `TemplateRegistry.byId()`
/// entrega el widget real (ARCHITECTURE.md §2, regla 1).
abstract class PlacaTemplate {
  const PlacaTemplate();

  TemplateDescriptor get descriptor;

  /// [model] ya viene resuelto por `resolvePlaca()` — este widget no debe
  /// tomar ninguna decisión de negocio, solo de layout (regla 2).
  Widget build(BuildContext context, PlacaRenderModel model, PlacaFormat format);
}
