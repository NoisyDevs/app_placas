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

/// T2 · Minimal — fiel a `Placa.dc.html` sección "T2 · MINIMAL": foto a
/// pantalla completa con degradé, todo el contenido flota sobre ella.
class MinimalTemplate extends PlacaTemplate {
  const MinimalTemplate({required this.kind});

  final PlacaKind kind;

  @override
  TemplateDescriptor get descriptor => TemplateDescriptor(
        id: kind == PlacaKind.publicacion ? 'remax.minimal_v1' : 'remax.minimal_v1.busqueda',
        packId: 'remax',
        nombre: 'Minimal',
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
    return Stack(
      fit: StackFit.expand,
      children: [
        RemaxPhotoArea(model: model, iconColor: const Color(0xFF7A8296)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.28, 0.42, 1.0],
              colors: [
                RemaxBrand.navy.withValues(alpha: 0.55),
                RemaxBrand.navy.withValues(alpha: 0.0),
                RemaxBrand.navy.withValues(alpha: 0.0),
                RemaxBrand.navy.withValues(alpha: 0.88),
              ],
            ),
          ),
        ),
        Positioned(
          top: cqw(4),
          left: cqw(4),
          child: BrandLogo(brand: RemaxBrand.theme, height: cqw(6), light: true),
        ),
        Positioned(
          top: cqw(4.4),
          right: cqw(4),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: cqw(2.6), vertical: cqw(1.2)),
            decoration: BoxDecoration(color: RemaxBrand.red, borderRadius: BorderRadius.circular(cqw(1))),
            child: Text(
              model.kicker,
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: cqw(2.8),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: RemaxBrand.white,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(cqw(4), cqw(5), cqw(4), cqw(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${model.zona} · ${model.tipoLabel}',
                  style: TextStyle(fontSize: cqw(3.4), color: RemaxBrand.white.withValues(alpha: 0.85)),
                ),
                SizedBox(height: cqw(0.8)),
                PlacaHeadline(
                  model.precioLine ?? 'Consultar',
                  style: TextStyle(fontSize: cqw(10), fontWeight: FontWeight.w800, letterSpacing: -0.5, color: RemaxBrand.white),
                ),
                SizedBox(height: cqw(3)),
                FeatureChipsRow(
                  chips: model.chips,
                  spacing: cqw(1.6),
                  runSpacing: cqw(1.6),
                  chipBuilder: (chip) => Container(
                    padding: EdgeInsets.symmetric(horizontal: cqw(2.4), vertical: cqw(1)),
                    decoration: BoxDecoration(
                      color: RemaxBrand.white.withValues(alpha: 0.15),
                      border: Border.all(color: RemaxBrand.white.withValues(alpha: 0.25), width: cqw(0.4)),
                      borderRadius: BorderRadius.circular(cqw(6)),
                    ),
                    child: Text(chip.label, style: TextStyle(fontSize: cqw(2.9), fontWeight: FontWeight.w600, color: RemaxBrand.white)),
                  ),
                ),
                SizedBox(height: cqw(3)),
                Container(height: cqw(0.4), color: RemaxBrand.white.withValues(alpha: 0.2)),
                SizedBox(height: cqw(2.6)),
                ContactStrip(
                  contact: model.contacto,
                  matricula: model.matricula,
                  avatarColor: RemaxBrand.red,
                  avatarTextColor: RemaxBrand.white,
                  avatarRadius: cqw(4),
                  nameStyle: TextStyle(fontSize: cqw(3.2), fontWeight: FontWeight.w700, color: RemaxBrand.white),
                  whatsappStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.6), color: RemaxBrand.whatsappGreen),
                  matriculaStyle: TextStyle(fontFamily: 'Space Mono', fontSize: cqw(2.3), color: RemaxBrand.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
