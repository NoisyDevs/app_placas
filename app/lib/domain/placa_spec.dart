import 'property_data.dart';
import 'property_enums.dart';
import 'search_data.dart';

/// Sealed: una placa es DE publicación O de búsqueda, nunca las dos cosas ni
/// ninguna — el `switch` exhaustivo en placa_resolver.dart es lo que
/// garantiza que ambos casos siempre se resuelven.
sealed class PlacaContent {
  const PlacaContent();

  PlacaKind get kind;
}

class PublicacionContent extends PlacaContent {
  const PublicacionContent(this.data);

  final PropertyData data;

  @override
  PlacaKind get kind => PlacaKind.publicacion;
}

class BusquedaContent extends PlacaContent {
  const BusquedaContent(this.data);

  final SearchData data;

  @override
  PlacaKind get kind => PlacaKind.busqueda;
}

/// Lo que arma el wizard y lo que se le pasa al resolver. Una `PlacaSpec`
/// con `formats = {feed, story}` es UN acto de generación que produce las
/// dos imágenes — consume un solo crédito de cupo (ver ARCHITECTURE.md §4,
/// "1 placa = 1 acto de generación, no 1 por formato").
class PlacaSpec {
  PlacaSpec({
    required this.content,
    required this.templateId,
    required this.formats,
    this.includeContact = true,
  }) : assert(formats.isNotEmpty, 'Debe elegirse al menos un formato');

  final PlacaContent content;
  final String templateId;
  final Set<PlacaFormat> formats;

  /// Historia 2.6: apagar esto oculta foto/nombre/WhatsApp/redes del
  /// agente, pero NO la matrícula si el template la requiere — esa regla
  /// vive en el resolver, no acá.
  final bool includeContact;
}
