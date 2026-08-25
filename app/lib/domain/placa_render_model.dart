import 'dart:typed_data';

import 'property_enums.dart';

/// Una característica ya resuelta a texto ("3 ambientes", "Cochera") y ya
/// recortada a `TemplateDescriptor.maxFeatureChips` — el widget del kit
/// (`PlacaChip`) solo hace `Wrap` sobre esta lista, nunca decide qué mostrar.
class FeatureChip {
  const FeatureChip(this.label);

  final String label;
}

/// Unión sellada: una imagen de placa es una foto real O una ilustración de
/// placeholder, nunca "una URL que puede o no tener bytes". Evita el típico
/// bug de "olvidé chequear si es placeholder" en el template.
sealed class PlacaImage {
  const PlacaImage();
}

class PlacaFoto extends PlacaImage {
  const PlacaFoto(this.bytes);

  final Uint8List bytes;
}

class PlacaIlustracion extends PlacaImage {
  const PlacaIlustracion(this.assetPath);

  final String assetPath;
}

/// Datos de contacto ya resueltos para el template. Ver
/// `PlacaRenderModel.contacto` — es `null`, no una versión "vacía" de este
/// objeto, cuando el agente apagó "incluir mis datos de contacto".
class ContactBlock {
  const ContactBlock({
    required this.nombre,
    required this.whatsapp,
    this.redSocial,
    this.fotoPath,
  });

  final String nombre;
  final String whatsapp;
  final String? redSocial;
  final String? fotoPath;
}

/// Salida de `resolvePlaca()` — lo único que ve un widget de template. Ver
/// ARCHITECTURE.md §2, regla 2: "el resultado ya viene limpio, sin nulls
/// con significado salvo los que están documentados acá mismo". Si un
/// template necesita un `if` sobre algún dato de negocio, es un bug en el
/// resolver, no en el template.
class PlacaRenderModel {
  const PlacaRenderModel({
    required this.format,
    required this.kind,
    required this.kicker,
    required this.tipoLabel,
    required this.zona,
    required this.precioLine,
    required this.chips,
    required this.images,
    required this.contacto,
    required this.matricula,
  });

  final PlacaFormat format;
  final PlacaKind kind;

  /// "VENTA" | "ALQUILER" | "BUSCO PARA COMPRAR" | "BUSCO PARA ALQUILAR".
  final String kicker;

  final String tipoLabel;
  final String zona;

  /// `null` únicamente en placas de búsqueda sin presupuesto cargado (es
  /// opcional en Historia 2.5). En publicación siempre viene resuelto —
  /// "Consultar" cuando el agente ocultó el precio, nunca `null`.
  final String? precioLine;

  final List<FeatureChip> chips;

  /// Fotos reales en publicación (recortadas a `photoSlots` del template);
  /// exactamente una ilustración de placeholder en búsqueda.
  final List<PlacaImage> images;

  /// `null` cuando `PlacaSpec.includeContact == false` (Historia 2.6).
  final ContactBlock? contacto;

  /// Sobrevive aunque `contacto` sea `null`, si el template la requiere —
  /// es un requisito legal (matrícula), no de estilo.
  final String? matricula;
}
