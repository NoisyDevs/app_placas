import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:placas/domain/agent_profile.dart';
import 'package:placas/domain/caracteristicas.dart';
import 'package:placas/domain/precio.dart';
import 'package:placas/domain/property_data.dart';
import 'package:placas/domain/property_enums.dart';
import 'package:placas/domain/search_data.dart';

/// Fixtures puros (sin Flutter) para los golden tests del motor de
/// templates — ver ARCHITECTURE.md §2 ("Golden tests: template × formato ×
/// perfil de contenido") y §9. Construidos con los tipos de dominio reales
/// (`PropertyData`/`SearchData`, igual que en `test/domain/placa_resolver_test.dart`),
/// no mocks: si la forma del dominio cambia, esto rompe en compilación en
/// vez de generar en silencio datos que ya no existen.

Uint8List? _cachedPhoto;

/// Foto real y decodificable para los perfiles de publicación que cargan
/// fotos ("típico"/"extremo"). Requiere haber llamado a
/// [preparePhotoFixture] antes (el test de goldens lo hace en
/// `setUpAll`) — tirar temprano y explícito acá es mejor que una foto
/// `null` silenciosa en medio del render.
///
/// BUG encontrado armando este archivo: el "PNG mínimo de 1×1" que circula
/// en la web (67 bytes, RGBA, usado típicamente como data-URI de
/// placeholder) NO decodifica en el motor de este entorno de test —
/// `Image.memory` tira "Codec failed to produce an image" de forma
/// reproducible (no es flaky: falla siempre, con cualquier template que
/// use una foto real), dejando el área de foto en blanco y el golden
/// "aprobando" una placa rota. En vez de perseguir bytes de PNG escritos a
/// mano que este decoder acepte, se generan acá con el propio `dart:ui`
/// (`PictureRecorder` → `Image.toByteData(format: png)`) — así el mismo
/// motor que los va a decodificar es el que los produce, sin duda posible
/// de compatibilidad.
Uint8List get golden1x1Png {
  final photo = _cachedPhoto;
  if (photo == null) {
    throw StateError('Llamá a preparePhotoFixture() (ver setUpAll) antes de usar golden1x1Png');
  }
  return photo;
}

/// Genera (una sola vez, cacheada) la foto real usada por los perfiles de
/// publicación con fotos. Debe llamarse desde un `setUpAll` async, antes
/// de armar cualquier `PropertyData` que la use — ver nota en
/// [golden1x1Png].
Future<void> preparePhotoFixture() async {
  if (_cachedPhoto != null) return;
  const size = 32.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, size, size),
    ui.Paint()..color = const ui.Color(0xFF888B99),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('No se pudo encodear la foto de prueba a PNG');
  }
  _cachedPhoto = byteData.buffer.asUint8List();
}

/// Perfil de agente fijo para todos los goldens. Sin foto real: `fotoPath`
/// es un string fijo — ningún template actual pinta la foto del agente
/// (solo iniciales en `ContactStrip`), así que no hace falta que el
/// archivo exista.
const AgentProfile goldenAgent = AgentProfile(
  agentId: 'golden-agent',
  nombre: 'Juana Pérez',
  whatsapp: '+54 9 11 5555-5555',
  redSocial: '@juana.remax',
  matricula: 'CUCICBA 1234',
  fotoPath: 'agents/golden-agent/foto.jpg',
);

const _zonaLarga = 'Barrio Parque Leloir, Ituzaingó, Provincia de Buenos Aires';

// ---------------------------------------------------------------------------
// Publicación
// ---------------------------------------------------------------------------

/// Mínimo: precio oculto ("Consultar"), cero características, sin fotos,
/// contacto apagado. `minPhotos` es 0 en los 5 templates RE/MAX actuales
/// (`clasico_v1`, `minimal_v1`, `franja_v1`, `bold_v1`, `editorial_v1`), así
/// que "sin fotos" es un input válido — el placeholder de `RemaxPhotoArea`
/// debe hacerse cargo. La matrícula se prueba vía `requiresMatricula` del
/// template (todos los 5 lo requieren), no acá.
PropertyData publicacionMinimo() => const PropertyData(
      operacion: Operacion.venta,
      tipo: TipoPropiedad.casa,
      precio: PrecioConsultar(),
      zona: 'Palermo',
      caracteristicas: Caracteristicas(),
      fotos: [],
    );

/// Típico: datos normales, precio con monto, 4 características (3-4 pedido
/// por el criterio de la sesión), contacto incluido, 1 foto real.
PropertyData publicacionTipico() => PropertyData(
      operacion: Operacion.venta,
      tipo: TipoPropiedad.departamento,
      precio: const PrecioMonto(monto: 185000, moneda: Moneda.usd),
      zona: 'Belgrano',
      caracteristicas: const Caracteristicas(
        ambientes: 3,
        dormitorios: 2,
        banos: 1,
        cochera: true,
      ),
      fotos: [golden1x1Png],
    );

/// Extremo: el peor caso de overflow en todos los campos de texto a la vez
/// — precio con monto largo, zona larga, las 5 características (todas +
/// cochera, tope de `maxFeatureChips` en los 5 templates), y más fotos que
/// `photoSlots` (1 en los 5 diseños actuales) para ejercitar también el
/// recorte del resolver. `includeContact: false` para probar que la
/// matrícula sobrevive aunque el contacto esté apagado.
PropertyData publicacionExtremo() => PropertyData(
      operacion: Operacion.alquiler,
      tipo: TipoPropiedad.oficina,
      precio: const PrecioMonto(monto: 1250000, moneda: Moneda.usd),
      zona: _zonaLarga,
      caracteristicas: const Caracteristicas(
        ambientes: 5,
        dormitorios: 4,
        banos: 3,
        superficieM2: 480,
        cochera: true,
      ),
      fotos: [golden1x1Png, golden1x1Png, golden1x1Png],
    );

/// Un perfil de contenido de publicación + si ese perfil pide el contacto
/// encendido o apagado (Historia 2.6) — se agrupa acá para que el test de
/// goldens no tenga que repetir la decisión por diseño/formato.
///
/// `build` (no un `PropertyData` ya armado) a propósito: "típico" y
/// "extremo" usan [golden1x1Png], que recién existe después de
/// `preparePhotoFixture()` (un `setUpAll` async). Los tests registran esta
/// lista de forma síncrona ANTES de que corra `setUpAll`, así que evaluar
/// la foto en ese momento tiraría el `StateError` de [golden1x1Png] — por
/// eso `build()` se llama recién adentro de cada `testWidgets`, después de
/// que el `setUpAll` terminó.
class GoldenPublicacionProfile {
  const GoldenPublicacionProfile(this.name, this.build, this.includeContact);

  final String name;
  final PropertyData Function() build;
  final bool includeContact;
}

List<GoldenPublicacionProfile> publicacionProfiles() => [
      GoldenPublicacionProfile('minimo', publicacionMinimo, false),
      GoldenPublicacionProfile('tipico', publicacionTipico, true),
      GoldenPublicacionProfile('extremo', publicacionExtremo, false),
    ];

// ---------------------------------------------------------------------------
// Búsqueda
// ---------------------------------------------------------------------------
//
// Solo dos perfiles, no tres: una placa de búsqueda no tiene fotos ni
// precio real (siempre una única ilustración de placeholder), así que la
// superficie de overflow es más chica que en publicación. Lo único
// numérico es el rango de presupuesto, y "sin cargar" (mínimo) vs. "rango
// grande con montos largos" (extremo) ya cubren ese rango — un perfil
// "típico" intermedio no ejercitaría ninguna ruta de overflow que mínimo +
// extremo no prueben ya.

/// Mínimo: sin presupuesto cargado, cero características deseadas.
/// `includeContact: true` acá (a diferencia de publicación-mínimo) para que
/// entre los 5 perfiles de este archivo se cubran ambos valores de
/// `includeContact` también del lado de búsqueda.
SearchData busquedaMinimo() => const SearchData(
      operacion: OperacionBuscada.compra,
      tipo: TipoPropiedad.casa,
      zona: 'Recoleta',
    );

/// Extremo: zona larga, rango de presupuesto con montos grandes en ambas
/// puntas, todas las características deseadas cargadas. `includeContact:
/// false` para volver a probar que la matrícula sobrevive con el contacto
/// apagado, esta vez del lado de búsqueda.
SearchData busquedaExtremo() => SearchData(
      operacion: OperacionBuscada.alquiler,
      tipo: TipoPropiedad.departamento,
      zona: _zonaLarga,
      presupuesto: const RangoPresupuesto(moneda: Moneda.usd, desde: 80000, hasta: 1250000),
      deseadas: const Caracteristicas(
        ambientes: 5,
        dormitorios: 4,
        banos: 3,
        superficieM2: 480,
        cochera: true,
      ),
    );

/// Igual que [GoldenPublicacionProfile] pero para `SearchData`.
class GoldenBusquedaProfile {
  const GoldenBusquedaProfile(this.name, this.data, this.includeContact);

  final String name;
  final SearchData data;
  final bool includeContact;
}

List<GoldenBusquedaProfile> busquedaProfiles() => [
      GoldenBusquedaProfile('minimo', busquedaMinimo(), true),
      GoldenBusquedaProfile('extremo', busquedaExtremo(), false),
    ];
