import 'package:flutter/material.dart';

import '../../../domain/placa_render_model.dart';
import 'remax_brand.dart';

/// Ícono de placeholder por ilustración de búsqueda. Las claves coinciden
/// con los `assetPath` que arma `RemaxPack.illustrations` (ver
/// `remax_pack.dart`). No son archivos reales todavía — Fase 7 /
/// ARCHITECTURE.md §9 trampa 7: hay que resolver antes de producción si
/// esto se reemplaza por ilustraciones encargadas o un set licenciado
/// (riesgo legal, igual que el logo). Hasta entonces, un ícono geométrico
/// simple por tipo de propiedad es una placa funcional sin depender de
/// ninguna imagen de origen dudoso.
const Map<String, IconData> _illustrationIcons = {
  'remax/illustration/casa': Icons.home_outlined,
  'remax/illustration/departamento': Icons.apartment_outlined,
  'remax/illustration/ph': Icons.holiday_village_outlined,
  'remax/illustration/lote': Icons.crop_square_outlined,
  'remax/illustration/local': Icons.storefront_outlined,
  'remax/illustration/oficina': Icons.business_outlined,
  'remax/illustration/cochera': Icons.directions_car_outlined,
  'remax/illustration/campo': Icons.landscape_outlined,
};

/// Área de foto/ilustración compartida por los 5 templates RE/MAX: si el
/// modelo trae una foto real la muestra a pantalla completa; si no
/// (búsqueda, o publicación sin fotos cargadas todavía) dibuja el
/// placeholder del mockup: fondo neutro + ícono + etiqueta.
class RemaxPhotoArea extends StatelessWidget {
  const RemaxPhotoArea({super.key, required this.model, this.iconColor});

  final PlacaRenderModel model;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final first = model.images.isEmpty ? null : model.images.first;

    if (first is PlacaFoto) {
      return Image.memory(first.bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }

    final label = first is PlacaIlustracion
        ? 'Imagen genérica · ${model.tipoLabel}'
        : 'Foto de la propiedad';
    final icon = first is PlacaIlustracion
        ? (_illustrationIcons[first.assetPath] ?? Icons.image_outlined)
        : Icons.home_work_outlined;
    final fg = iconColor ?? RemaxBrand.placeholderFg;

    return ColoredBox(
      color: RemaxBrand.placeholderBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: cqw(11), color: fg),
            SizedBox(height: cqw(1.6)),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: cqw(2.6),
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
