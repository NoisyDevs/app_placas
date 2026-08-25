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

/// T4 · Bold dark — fiel a `Placa.dc.html` sección "T4 · BOLD DARK": toda
/// la placa sobre azul noche, foto en caja redondeada, precio enorme.
class BoldTemplate extends PlacaTemplate {
  const BoldTemplate({required this.kind});

  final PlacaKind kind;

  @override
  TemplateDescriptor get descriptor => TemplateDescriptor(
        id: kind == PlacaKind.publicacion ? 'remax.bold_v1' : 'remax.bold_v1.busqueda',
        packId: 'remax',
        nombre: 'Bold',
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
    return Container(
      color: RemaxBrand.navy,
      padding: EdgeInsets.all(cqw(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BrandLogo(brand: RemaxBrand.theme, height: cqw(6), light: true),
              const Spacer(),
              Text(
                model.kicker,
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  fontSize: cqw(2.8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: RemaxBrand.red,
                ),
              ),
            ],
          ),
          SizedBox(height: cqw(3)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cqw(2)),
              child: RemaxPhotoArea(model: model, iconColor: const Color(0xFF6B7EA1)),
            ),
          ),
          SizedBox(height: cqw(3.4)),
          Text('${model.zona} · ${model.tipoLabel}', style: TextStyle(fontSize: cqw(3.3), color: const Color(0xFFAEB6C9))),
          SizedBox(height: cqw(0.6)),
          PlacaHeadline(
            model.precioLine ?? 'Consultar',
            style: TextStyle(fontSize: cqw(11), fontWeight: FontWeight.w800, letterSpacing: -0.5, color: RemaxBrand.white),
          ),
          SizedBox(height: cqw(2.6)),
          FeatureChipsRow(
            chips: model.chips,
            spacing: cqw(1.6),
            runSpacing: cqw(1.6),
            chipBuilder: (chip) => Container(
              padding: EdgeInsets.symmetric(horizontal: cqw(2.4), vertical: cqw(0.9)),
              decoration: BoxDecoration(
                border: Border.all(color: RemaxBrand.white.withValues(alpha: 0.25), width: cqw(0.4)),
                borderRadius: BorderRadius.circular(cqw(6)),
              ),
              child: Text(chip.label, style: TextStyle(fontSize: cqw(2.9), fontWeight: FontWeight.w600, color: RemaxBrand.white)),
            ),
          ),
          SizedBox(height: cqw(3.4)),
          Container(
            padding: EdgeInsets.only(top: cqw(3)),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: RemaxBrand.white.withValues(alpha: 0.15), width: cqw(0.4)))),
            child: ContactStrip(
              contact: model.contacto,
              matricula: model.matricula,
              avatarColor: RemaxBrand.red,
              avatarTextColor: RemaxBrand.white,
              avatarRadius: cqw(4.25),
              nameStyle: TextStyle(fontSize: cqw(3.3), fontWeight: FontWeight.w700, color: RemaxBrand.white),
              whatsappStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.6), color: RemaxBrand.whatsappGreen),
              matriculaStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.3), color: const Color(0xFFAEB6C9)),
            ),
          ),
        ],
      ),
    );
  }
}
