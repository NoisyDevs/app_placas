import 'dart:typed_data';

import 'package:placas/domain/agent_profile.dart';
import 'package:placas/domain/caracteristicas.dart';
import 'package:placas/domain/placa_render_model.dart';
import 'package:placas/domain/placa_resolver.dart';
import 'package:placas/domain/placa_spec.dart';
import 'package:placas/domain/precio.dart';
import 'package:placas/domain/property_data.dart';
import 'package:placas/domain/property_enums.dart';
import 'package:placas/domain/search_data.dart';
import 'package:placas/domain/template_descriptor.dart';
import 'package:test/test.dart';

const _completeProfile = AgentProfile(
  agentId: 'agent-1',
  nombre: 'Juana Pérez',
  whatsapp: '+54 9 11 5555-5555',
  redSocial: '@juana.remax',
  matricula: 'CUCICBA 1234',
  fotoPath: 'agents/agent-1/foto.jpg',
);

TemplateDescriptor _publicacionTemplate({
  int photoSlots = 3,
  int maxFeatureChips = 4,
  bool requiresMatricula = false,
  Set<PlacaFormat> formats = const {PlacaFormat.feed, PlacaFormat.story},
}) {
  return TemplateDescriptor(
    id: 'remax.hero_v1',
    packId: 'remax',
    nombre: 'Hero',
    kind: PlacaKind.publicacion,
    formats: formats,
    thumbAsset: 'thumb.png',
    photoSlots: photoSlots,
    maxFeatureChips: maxFeatureChips,
    requiresMatricula: requiresMatricula,
  );
}

TemplateDescriptor _busquedaTemplate({
  bool requiresMatricula = false,
  Map<TipoPropiedad, String> illustrations = const {
    TipoPropiedad.casa: 'ilustraciones/casa.svg',
    TipoPropiedad.departamento: 'ilustraciones/depto.svg',
    TipoPropiedad.ph: 'ilustraciones/ph.svg',
    TipoPropiedad.lote: 'ilustraciones/lote.svg',
    TipoPropiedad.local: 'ilustraciones/local.svg',
    TipoPropiedad.oficina: 'ilustraciones/oficina.svg',
    TipoPropiedad.cochera: 'ilustraciones/cochera.svg',
    TipoPropiedad.campo: 'ilustraciones/campo.svg',
  },
}) {
  return TemplateDescriptor(
    id: 'remax.busqueda_v1',
    packId: 'remax',
    nombre: 'Busco propiedad',
    kind: PlacaKind.busqueda,
    formats: const {PlacaFormat.feed, PlacaFormat.story},
    thumbAsset: 'thumb-busqueda.png',
    photoSlots: 0,
    requiresMatricula: requiresMatricula,
    illustrations: illustrations,
  );
}

void main() {
  group('resolvePlaca — publicación', () {
    test('campos vacíos de Caracteristicas no generan chips', () {
      final data = PropertyData(
        operacion: Operacion.venta,
        tipo: TipoPropiedad.departamento,
        precio: const PrecioMonto(monto: 250000, moneda: Moneda.usd),
        zona: 'Palermo',
        caracteristicas: const Caracteristicas(ambientes: 3),
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _publicacionTemplate(),
        format: PlacaFormat.feed,
      );

      expect(model.chips, hasLength(1));
      expect(model.chips.single.label, '3 ambientes');
    });

    test('precio oculto resuelve a "Consultar"', () {
      final data = PropertyData(
        operacion: Operacion.venta,
        tipo: TipoPropiedad.casa,
        precio: const PrecioConsultar(),
        zona: 'Belgrano',
        caracteristicas: const Caracteristicas(),
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _publicacionTemplate(),
        format: PlacaFormat.feed,
      );

      expect(model.precioLine, 'Consultar');
    });

    test('contacto apagado oculta el bloque de contacto pero conserva la matrícula', () {
      final data = PropertyData(
        operacion: Operacion.alquiler,
        tipo: TipoPropiedad.ph,
        precio: const PrecioMonto(monto: 300000, moneda: Moneda.ars),
        zona: 'Caballito',
        caracteristicas: const Caracteristicas(),
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
        includeContact: false,
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _publicacionTemplate(requiresMatricula: true),
        format: PlacaFormat.feed,
      );

      expect(model.contacto, isNull);
      expect(model.matricula, 'CUCICBA 1234');
    });

    test('contacto encendido pero template sin requiresMatricula no la incluye', () {
      final data = PropertyData(
        operacion: Operacion.venta,
        tipo: TipoPropiedad.casa,
        precio: const PrecioConsultar(),
        zona: 'Recoleta',
        caracteristicas: const Caracteristicas(),
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _publicacionTemplate(requiresMatricula: false),
        format: PlacaFormat.feed,
      );

      expect(model.contacto, isNotNull);
      expect(model.matricula, isNull);
    });

    test('las fotos se recortan a photoSlots del template', () {
      final fotos = List.generate(5, (i) => Uint8List.fromList([i]));
      final data = PropertyData(
        operacion: Operacion.venta,
        tipo: TipoPropiedad.casa,
        precio: const PrecioMonto(monto: 100000, moneda: Moneda.usd),
        zona: 'Nuñez',
        caracteristicas: const Caracteristicas(),
        fotos: fotos,
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _publicacionTemplate(photoSlots: 2),
        format: PlacaFormat.feed,
      );

      expect(model.images, hasLength(2));
      expect(model.images.every((img) => img is PlacaFoto), isTrue);
    });

    test('la cantidad de chips nunca supera maxFeatureChips', () {
      final data = PropertyData(
        operacion: Operacion.venta,
        tipo: TipoPropiedad.casa,
        precio: const PrecioMonto(monto: 100000, moneda: Moneda.usd),
        zona: 'Nuñez',
        caracteristicas: const Caracteristicas(
          ambientes: 4,
          dormitorios: 3,
          banos: 2,
          superficieM2: 120,
          cochera: true,
        ),
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _publicacionTemplate(maxFeatureChips: 3),
        format: PlacaFormat.feed,
      );

      expect(model.chips.length, 3);
    });

    test('cochera == false no genera chip (solo true lo hace)', () {
      final data = PropertyData(
        operacion: Operacion.venta,
        tipo: TipoPropiedad.casa,
        precio: const PrecioMonto(monto: 100000, moneda: Moneda.usd),
        zona: 'Nuñez',
        caracteristicas: const Caracteristicas(cochera: false),
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _publicacionTemplate(),
        format: PlacaFormat.feed,
      );

      expect(model.chips, isEmpty);
    });

    test('lanza si el template no soporta el formato pedido', () {
      final data = PropertyData(
        operacion: Operacion.venta,
        tipo: TipoPropiedad.casa,
        precio: const PrecioConsultar(),
        zona: 'X',
        caracteristicas: const Caracteristicas(),
      );
      final spec = PlacaSpec(
        content: PublicacionContent(data),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      expect(
        () => resolvePlaca(
          spec: spec,
          profile: _completeProfile,
          template: _publicacionTemplate(formats: const {PlacaFormat.feed}),
          format: PlacaFormat.story,
        ),
        throwsArgumentError,
      );
    });

    test('lanza si el kind de la placa no coincide con el kind del template', () {
      final searchData = SearchData(
        operacion: OperacionBuscada.compra,
        tipo: TipoPropiedad.casa,
        zona: 'X',
      );
      final spec = PlacaSpec(
        content: BusquedaContent(searchData),
        templateId: 'remax.hero_v1',
        formats: const {PlacaFormat.feed},
      );

      expect(
        () => resolvePlaca(
          spec: spec,
          profile: _completeProfile,
          template: _publicacionTemplate(),
          format: PlacaFormat.feed,
        ),
        throwsArgumentError,
      );
    });
  });

  group('resolvePlaca — búsqueda', () {
    test('nunca tiene fotos: resuelve a exactamente una ilustración', () {
      final data = SearchData(
        operacion: OperacionBuscada.compra,
        tipo: TipoPropiedad.departamento,
        zona: 'Villa Crespo',
      );
      final spec = PlacaSpec(
        content: BusquedaContent(data),
        templateId: 'remax.busqueda_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _busquedaTemplate(),
        format: PlacaFormat.feed,
      );

      expect(model.images, hasLength(1));
      expect(model.images.single, isA<PlacaIlustracion>());
      expect((model.images.single as PlacaIlustracion).assetPath, 'ilustraciones/depto.svg');
    });

    test('sin presupuesto, precioLine es null', () {
      final data = SearchData(
        operacion: OperacionBuscada.alquiler,
        tipo: TipoPropiedad.casa,
        zona: 'Flores',
      );
      final spec = PlacaSpec(
        content: BusquedaContent(data),
        templateId: 'remax.busqueda_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _busquedaTemplate(),
        format: PlacaFormat.feed,
      );

      expect(model.precioLine, isNull);
    });

    test('con presupuesto de rango cerrado, formatea "desde a hasta"', () {
      final data = SearchData(
        operacion: OperacionBuscada.compra,
        tipo: TipoPropiedad.casa,
        zona: 'Flores',
        presupuesto: const RangoPresupuesto(moneda: Moneda.usd, desde: 80000, hasta: 120000),
      );
      final spec = PlacaSpec(
        content: BusquedaContent(data),
        templateId: 'remax.busqueda_v1',
        formats: const {PlacaFormat.feed},
      );

      final model = resolvePlaca(
        spec: spec,
        profile: _completeProfile,
        template: _busquedaTemplate(),
        format: PlacaFormat.feed,
      );

      expect(model.precioLine, 'USD 80.000 a 120.000');
    });

    test('kicker distingue compra de alquiler', () {
      final compra = SearchData(operacion: OperacionBuscada.compra, tipo: TipoPropiedad.casa, zona: 'X');
      final alquiler = SearchData(operacion: OperacionBuscada.alquiler, tipo: TipoPropiedad.casa, zona: 'X');

      PlacaRenderModel resolve(SearchData d) => resolvePlaca(
            spec: PlacaSpec(
              content: BusquedaContent(d),
              templateId: 'remax.busqueda_v1',
              formats: const {PlacaFormat.feed},
            ),
            profile: _completeProfile,
            template: _busquedaTemplate(),
            format: PlacaFormat.feed,
          );

      expect(resolve(compra).kicker, 'BUSCO PARA COMPRAR');
      expect(resolve(alquiler).kicker, 'BUSCO PARA ALQUILAR');
    });

    test('lanza si el template no tiene ilustración para el tipo pedido', () {
      final data = SearchData(operacion: OperacionBuscada.compra, tipo: TipoPropiedad.campo, zona: 'X');
      final spec = PlacaSpec(
        content: BusquedaContent(data),
        templateId: 'remax.busqueda_v1',
        formats: const {PlacaFormat.feed},
      );

      expect(
        () => resolvePlaca(
          spec: spec,
          profile: _completeProfile,
          template: _busquedaTemplate(illustrations: const {TipoPropiedad.casa: 'x.svg'}),
          format: PlacaFormat.feed,
        ),
        throwsStateError,
      );
    });
  });
}
