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

/// T3 · Franja — fiel a `Placa.dc.html` sección "T3 · FRANJA AZUL": header
/// azul RE/MAX, foto, precio en franja blanca, contacto en franja roja.
class FranjaTemplate extends PlacaTemplate {
  const FranjaTemplate({required this.kind});

  final PlacaKind kind;

  @override
  TemplateDescriptor get descriptor => TemplateDescriptor(
        id: kind == PlacaKind.publicacion ? 'remax.franja_v1' : 'remax.franja_v1.busqueda',
        packId: 'remax',
        nombre: 'Franja',
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
    return ColoredBox(
      color: RemaxBrand.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: RemaxBrand.blue,
            padding: EdgeInsets.symmetric(horizontal: cqw(4), vertical: cqw(3.4)),
            child: Row(
              children: [
                BrandLogo(brand: RemaxBrand.theme, height: cqw(6), light: true),
                const Spacer(),
                Text(
                  model.kicker,
                  style: TextStyle(
                    fontFamily: 'Space Mono',
                    fontSize: cqw(2.9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: RemaxBrand.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: RemaxPhotoArea(model: model)),
          Padding(
            padding: EdgeInsets.all(cqw(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${model.zona} · ${model.tipoLabel}',
                  style: TextStyle(fontSize: cqw(3.3), color: const Color(0xFF5A6070)),
                ),
                SizedBox(height: cqw(0.6)),
                PlacaHeadline(
                  model.precioLine ?? 'Consultar',
                  style: TextStyle(fontSize: cqw(8.5), fontWeight: FontWeight.w800, letterSpacing: -0.5, color: RemaxBrand.blue),
                ),
                SizedBox(height: cqw(3)),
                FeatureChipsRow(
                  chips: model.chips,
                  spacing: cqw(1.6),
                  runSpacing: cqw(1.6),
                  chipBuilder: (chip) => Container(
                    padding: EdgeInsets.symmetric(horizontal: cqw(2.4), vertical: cqw(1)),
                    decoration: BoxDecoration(color: const Color(0xFFEEF1F7), borderRadius: BorderRadius.circular(cqw(1))),
                    child: Text(chip.label, style: TextStyle(fontSize: cqw(2.9), fontWeight: FontWeight.w700, color: RemaxBrand.blue)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: RemaxBrand.red,
            padding: EdgeInsets.symmetric(horizontal: cqw(4), vertical: cqw(3)),
            child: ContactStrip(
              contact: model.contacto,
              matricula: model.matricula,
              avatarColor: RemaxBrand.white,
              avatarTextColor: RemaxBrand.red,
              avatarRadius: cqw(4.5),
              nameStyle: TextStyle(fontSize: cqw(3.4), fontWeight: FontWeight.w700, color: RemaxBrand.white),
              whatsappStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.7), color: RemaxBrand.white),
              matriculaStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.4), color: RemaxBrand.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
