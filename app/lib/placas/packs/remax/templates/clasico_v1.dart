import 'package:flutter/material.dart';

import '../../../../domain/placa_render_model.dart';
import '../../../../domain/property_enums.dart';
import '../../../../domain/template_descriptor.dart';
import '../../../kit/brand_logo.dart';
import '../../../kit/contact_strip.dart';
import '../../../kit/feature_chips.dart';
import '../../../kit/placa_template.dart';
import '../../../kit/placa_text.dart';
import '../remax_brand.dart';
import '../remax_illustrations.dart';
import '../remax_photo.dart';

/// T1 · Clásico — fiel a `Placa.dc.html` sección "T1 · CLÁSICO": header
/// blanco (logo + tipo de propiedad), foto con badge de operación,
/// precio + características, franja de contacto azul noche.
class ClasicoTemplate extends PlacaTemplate {
  const ClasicoTemplate({required this.kind});

  final PlacaKind kind;

  @override
  TemplateDescriptor get descriptor => TemplateDescriptor(
        id: kind == PlacaKind.publicacion ? 'remax.clasico_v1' : 'remax.clasico_v1.busqueda',
        packId: 'remax',
        nombre: 'Clásico',
        kind: kind,
        formats: const {PlacaFormat.feed, PlacaFormat.story},
        // Catálogo usa preview en vivo (ver features/wizard/templates), no
        // una imagen estática — Fase 7 si hace falta un thumb pre-render.
        thumbAsset: '',
        photoSlots: kind == PlacaKind.publicacion ? 1 : 0,
        maxFeatureChips: 5,
        requiresMatricula: true,
        illustrations: kind == PlacaKind.busqueda ? remaxIllustrations : const {},
      );

  @override
  Widget build(BuildContext context, PlacaRenderModel model, PlacaFormat format) {
    return ColoredBox(
      color: RemaxBrand.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cqw(4), vertical: cqw(3.5)),
            child: Row(
              children: [
                BrandLogo(brand: RemaxBrand.theme, height: cqw(6.5)),
                const Spacer(),
                Text(
                  model.tipoLabel.toUpperCase(),
                  style: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.9), letterSpacing: 1.6, color: const Color(0xFF8A90A0)),
                ),
              ],
            ),
          ),
          Container(height: cqw(0.5), color: const Color(0xFFEEF0F3)),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RemaxPhotoArea(model: model),
                Positioned(
                  top: cqw(4),
                  left: cqw(4),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: cqw(3), vertical: cqw(1.4)),
                    decoration: BoxDecoration(color: RemaxBrand.red, borderRadius: BorderRadius.circular(cqw(1))),
                    child: Text(
                      model.kicker,
                      style: TextStyle(
                        fontFamily: 'Space Mono',
                        fontSize: cqw(3),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: RemaxBrand.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(cqw(4), cqw(4), cqw(4), cqw(3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PlacaLabel(model.zona, style: TextStyle(fontSize: cqw(3.4), color: const Color(0xFF5A6070))),
                SizedBox(height: cqw(0.6)),
                PlacaHeadline(
                  model.precioLine ?? 'Consultar',
                  style: TextStyle(fontSize: cqw(9), fontWeight: FontWeight.w800, letterSpacing: -0.5, color: RemaxBrand.red),
                ),
                SizedBox(height: cqw(3)),
                FeatureChipsRow(
                  chips: model.chips,
                  spacing: cqw(2.4),
                  runSpacing: cqw(1.2),
                  chipBuilder: (chip) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: cqw(1.2), color: RemaxBrand.blue),
                      SizedBox(width: cqw(1)),
                      Text(chip.label, style: TextStyle(fontSize: cqw(3.2), fontWeight: FontWeight.w600, color: RemaxBrand.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: RemaxBrand.navy,
            padding: EdgeInsets.symmetric(horizontal: cqw(4), vertical: cqw(3)),
            child: ContactStrip(
              contact: model.contacto,
              matricula: model.matricula,
              avatarColor: RemaxBrand.red,
              avatarTextColor: RemaxBrand.white,
              avatarRadius: cqw(4.5),
              nameStyle: TextStyle(fontSize: cqw(3.4), fontWeight: FontWeight.w700, color: RemaxBrand.white),
              whatsappStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.7), color: RemaxBrand.whatsappGreen),
              matriculaStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.4), color: const Color(0xFFAEB6C9)),
            ),
          ),
        ],
      ),
    );
  }
}
