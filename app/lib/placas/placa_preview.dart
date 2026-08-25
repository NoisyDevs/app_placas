import 'package:flutter/widgets.dart';

import '../domain/agent_profile.dart';
import '../domain/placa_resolver.dart';
import '../domain/placa_spec.dart';
import '../domain/property_enums.dart';
import 'kit/placa_canvas.dart';
import 'registry.dart';

/// Orquestador reusable: arma un `PlacaSpec`, lo resuelve con
/// `resolvePlaca()` (Dart puro) y pinta el template resultante escalado en
/// un `PlacaCanvas`. Es el único punto de contacto que las pantallas del
/// wizard necesitan — nunca llaman a `resolvePlaca()` ni a
/// `TemplateRegistry` directamente, así que tampoco necesitan importar
/// `placas/packs/remax/**` (ver `placas/registry.dart`).
class PlacaPreview extends StatelessWidget {
  const PlacaPreview({
    super.key,
    required this.templateId,
    required this.content,
    required this.agent,
    required this.format,
    this.includeContact = true,
  });

  final String templateId;
  final PlacaContent content;
  final AgentProfile agent;
  final PlacaFormat format;
  final bool includeContact;

  @override
  Widget build(BuildContext context) {
    final template = templateRegistry.byId(templateId);
    final spec = PlacaSpec(
      content: content,
      templateId: templateId,
      formats: {format},
      includeContact: includeContact,
    );
    final model = resolvePlaca(
      spec: spec,
      profile: agent,
      template: template.descriptor,
      format: format,
    );
    return PlacaCanvas(format: format, child: template.build(context, model, format));
  }
}
