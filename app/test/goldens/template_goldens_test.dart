import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:placas/domain/placa_spec.dart';
import 'package:placas/domain/property_enums.dart';
import 'package:placas/placas/placa_preview.dart';

import 'golden_fixtures.dart';

/// Golden tests del motor de templates (ARCHITECTURE.md §2, "Overflow de
/// texto", capa 4). Renderiza cada combinación diseño × kind × formato ×
/// perfil de contenido a través del MISMO camino que usa la app real
/// (`PlacaPreview` → `resolvePlaca()` → `template.build()` sobre
/// `PlacaCanvas`) y compara contra una imagen de referencia — así un
/// desborde de texto, un chip cortado o un color que cambia se vuelven un
/// test rojo en vez de algo que alguien tiene que notar a mano.
///
/// Cada uno de los 5 diseños RE/MAX (Clásico, Minimal, Franja, Bold,
/// Editorial) está registrado dos veces en el catálogo — una por
/// `PlacaKind` — con ids `remax.<slug>_v1` (publicación) y
/// `remax.<slug>_v1.busqueda` (búsqueda). Ver `lib/placas/packs/remax/remax_pack.dart`.
class _Design {
  const _Design(this.slug, this.publicacionId, this.busquedaId);

  final String slug;
  final String publicacionId;
  final String busquedaId;
}

const _designs = [
  _Design('clasico_v1', 'remax.clasico_v1', 'remax.clasico_v1.busqueda'),
  _Design('minimal_v1', 'remax.minimal_v1', 'remax.minimal_v1.busqueda'),
  _Design('franja_v1', 'remax.franja_v1', 'remax.franja_v1.busqueda'),
  _Design('bold_v1', 'remax.bold_v1', 'remax.bold_v1.busqueda'),
  _Design('editorial_v1', 'remax.editorial_v1', 'remax.editorial_v1.busqueda'),
];

const _formats = [PlacaFormat.feed, PlacaFormat.story];

const _goldenKey = ValueKey('golden-placa');

/// El canvas lógico real es 1080×1080 (feed) / 1080×1920 (story) —
/// ARCHITECTURE.md §2, regla 3. `PlacaCanvas` ya escala ese canvas fijo con
/// `FittedBox`, así que capturar el golden a 1/4 de esa resolución
/// (270×270 / 270×480, mismo aspect ratio) pinta exactamente el mismo
/// layout — solo más chico — y mantiene los ~50 archivos PNG de este
/// archivo livianos sin perder la capacidad de detectar overflow/recorte.
Size _captureSizeFor(PlacaFormat format) => Size(format.width / 4, format.height / 4);

Future<void> _pumpPlaca(
  WidgetTester tester, {
  required String templateId,
  required PlacaContent content,
  required PlacaFormat format,
  required bool includeContact,
}) async {
  final size = _captureSizeFor(format);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: RepaintBoundary(
              key: _goldenKey,
              child: PlacaPreview(
                templateId: templateId,
                content: content,
                agent: goldenAgent,
                format: format,
                includeContact: includeContact,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Carga las fuentes reales empaquetadas (`lib/app/theme/fonts/`, ver
/// `pubspec.yaml` y `lib/app/theme/fonts/LICENSES.md`) en el binding de
/// test. `flutter_test` NO carga por defecto las fuentes declaradas en
/// `pubspec.yaml` — sin esto, cada glyph se dibuja como un bloque sólido de
/// ancho uniforme ("fuente de test"), lo que esconde cualquier overflow de
/// texto real (que depende del ancho real de cada carácter). Mecanismo
/// estándar de Flutter: `FontLoader` + `rootBundle.load()` para los bytes.
Future<void> _loadRealFonts() async {
  final spaceMono = FontLoader('Space Mono')
    ..addFont(rootBundle.load('lib/app/theme/fonts/SpaceMono-Regular.ttf'))
    ..addFont(rootBundle.load('lib/app/theme/fonts/SpaceMono-Bold.ttf'));
  final dmSerifDisplay = FontLoader('DM Serif Display')
    ..addFont(rootBundle.load('lib/app/theme/fonts/DMSerifDisplay-Regular.ttf'));
  await spaceMono.load();
  await dmSerifDisplay.load();
}

void main() {
  setUpAll(preparePhotoFixture);
  setUpAll(_loadRealFonts);

  for (final design in _designs) {
    for (final format in _formats) {
      final formatSlug = format.name;

      for (final profile in publicacionProfiles()) {
        testWidgets(
          '${design.slug} publicacion $formatSlug ${profile.name}',
          (tester) async {
            await _pumpPlaca(
              tester,
              templateId: design.publicacionId,
              content: PublicacionContent(profile.build()),
              format: format,
              includeContact: profile.includeContact,
            );

            await expectLater(
              find.byKey(_goldenKey),
              matchesGoldenFile(
                'goldens/${design.slug}_publicacion_${formatSlug}_${profile.name}.png',
              ),
            );
          },
        );
      }

      for (final profile in busquedaProfiles()) {
        testWidgets(
          '${design.slug} busqueda $formatSlug ${profile.name}',
          (tester) async {
            await _pumpPlaca(
              tester,
              templateId: design.busquedaId,
              content: BusquedaContent(profile.data),
              format: format,
              includeContact: profile.includeContact,
            );

            await expectLater(
              find.byKey(_goldenKey),
              matchesGoldenFile(
                'goldens/${design.slug}_busqueda_${formatSlug}_${profile.name}.png',
              ),
            );
          },
        );
      }
    }
  }
}
