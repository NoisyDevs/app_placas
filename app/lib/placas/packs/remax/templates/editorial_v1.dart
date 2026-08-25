import 'package:flutter/material.dart';

import '../../../../domain/placa_render_model.dart';
import '../../../../domain/property_enums.dart';
import '../../../../domain/template_descriptor.dart';
import '../../../kit/brand_logo.dart';
import '../../../kit/placa_template.dart';
import '../../../kit/placa_text.dart';
import '../remax_brand.dart';
import '../remax_illustrations.dart';
import '../remax_photo.dart';

/// T5 · Editorial — fiel a `Placa.dc.html` sección "T5 · EDITORIAL": fondo
/// crema, todo centrado, bordes negros como en una revista.
///
/// El bloque de contacto acá es texto centrado ("nombre / whatsapp ·
/// matrícula"), distinto de las franjas con avatar de los otros 4
/// templates — se compone a mano en vez de reusar `ContactStrip` porque el
/// layout del mockup difiere lo suficiente (una sola línea centrada, sin
/// avatar circular).
class EditorialTemplate extends PlacaTemplate {
  const EditorialTemplate({required this.kind});

  final PlacaKind kind;

  @override
  TemplateDescriptor get descriptor => TemplateDescriptor(
        id: kind == PlacaKind.publicacion ? 'remax.editorial_v1' : 'remax.editorial_v1.busqueda',
        packId: 'remax',
        nombre: 'Editorial',
        kind: kind,
        formats: const {PlacaFormat.feed, PlacaFormat.story},
        thumbAsset: '',
        photoSlots: kind == PlacaKind.publicacion ? 1 : 0,
        maxFeatureChips: 5,
        requiresMatricula: true,
        illustrations: kind == PlacaKind.busqueda ? remaxIllustrations : const {},
      );

  @override
  Widget build(BuildContext context, PlacaRenderModel model, PlacaFormat format) {
    final contact = model.contacto;
    final matricula = model.matricula;

    return Container(
      color: RemaxBrand.cream,
      padding: EdgeInsets.all(cqw(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: cqw(3)),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: RemaxBrand.ink, width: cqw(0.5)))),
            child: Row(
              children: [
                BrandLogo(brand: RemaxBrand.theme, height: cqw(6)),
                const Spacer(),
                Text(
                  '${model.kicker} · ${model.tipoLabel}'.toUpperCase(),
                  style: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.7), letterSpacing: 1.8, color: RemaxBrand.ink),
                ),
              ],
            ),
          ),
          SizedBox(height: cqw(3.4)),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: RemaxBrand.ink, width: cqw(0.5))),
              child: RemaxPhotoArea(model: model, iconColor: const Color(0xFFB3AB9C)),
            ),
          ),
          SizedBox(height: cqw(3.4)),
          Column(
            children: [
              Text(model.zona, style: TextStyle(fontSize: cqw(3.2), color: const Color(0xFF5A5648)), textAlign: TextAlign.center),
              SizedBox(height: cqw(0.6)),
              PlacaHeadline(
                model.precioLine ?? 'Consultar',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'DM Serif Display', fontSize: cqw(11), color: RemaxBrand.ink),
              ),
              SizedBox(height: cqw(2)),
              Text(
                model.chips.map((c) => c.label).join(' · '),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.8), letterSpacing: 0.6, color: RemaxBrand.ink),
              ),
            ],
          ),
          SizedBox(height: cqw(3.4)),
          Container(
            padding: EdgeInsets.only(top: cqw(3)),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: RemaxBrand.ink, width: cqw(0.5)))),
            child: contact == null
                ? Text(
                    matricula == null ? '' : '$matricula · consultá con tu agente',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.6), letterSpacing: 0.6, color: RemaxBrand.ink),
                  )
                : Text(
                    matricula == null
                        ? '${contact.nombre} · ${contact.whatsapp}'
                        : '${contact.nombre} · ${contact.whatsapp} · $matricula',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: cqw(3.2), fontWeight: FontWeight.w700, color: RemaxBrand.ink),
                  ),
          ),
        ],
      ),
    );
  }
}
