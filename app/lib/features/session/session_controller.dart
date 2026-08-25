import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/agent_profile.dart';
import '../../domain/caracteristicas.dart';
import '../../domain/placa_spec.dart';
import '../../domain/precio.dart';
import '../../domain/property_data.dart';
import '../../domain/property_enums.dart';
import '../../domain/search_data.dart';
import '../../placas/registry.dart';

/// Sentinel para distinguir "no pasé este argumento a `copyWith`" de
/// "lo pasé explícitamente en `null`" — ver los comentarios en
/// `PropertyDraft.copyWith` / `SearchDraft.copyWith`.
const Object _unset = Object();

/// Estado compartido de toda la sesión: perfil del agente, borrador del
/// wizard (publicación o búsqueda), cupo y historial.
///
/// Fase 3 de ARCHITECTURE.md §8 ("wizard + export + compartir/descargar,
/// con perfil local fake") junta a propósito lo que en fases más avanzadas
/// se separa en `features/{auth,profile,wizard,billing,quota}` con sus
/// propios `data/` respaldados por Supabase — acá todavía no hay backend
/// ni persistencia real, así que un solo controller evita separar capas
/// que todavía no existen. Migrar a providers por feature cuando llegue
/// Fase 4/5 no debería tocar las pantallas: todas leen `sessionProvider`.
class PropertyDraft {
  const PropertyDraft({
    this.operacion = Operacion.venta,
    this.tipo = TipoPropiedad.departamento,
    this.precio = 185000,
    this.moneda = Moneda.usd,
    this.ocultarPrecio = false,
    this.zona = 'Palermo, CABA',
    this.ambientes = 3,
    this.dormitorios = 2,
    this.banos = 1,
    this.superficieM2 = 78,
    this.cochera = true,
    this.fotos = const [],
  });

  final Operacion operacion;
  final TipoPropiedad tipo;
  final num precio;
  final Moneda moneda;
  final bool ocultarPrecio;
  final String zona;
  final int? ambientes;
  final int? dormitorios;
  final int? banos;
  final num? superficieM2;
  final bool cochera;
  final List<Uint8List> fotos;

  /// Los campos numéricos opcionales usan el truco del sentinel `_unset`
  /// en vez de `campo ?? this.campo`: con `??` sería imposible volver a
  /// dejar el campo en `null` desde la UI (ej. el agente borra el input de
  /// "Ambientes") porque `copyWith(ambientes: null)` se leería como "no
  /// tocar este campo" en vez de "vaciarlo".
  PropertyDraft copyWith({
    Operacion? operacion,
    TipoPropiedad? tipo,
    num? precio,
    Moneda? moneda,
    bool? ocultarPrecio,
    String? zona,
    Object? ambientes = _unset,
    Object? dormitorios = _unset,
    Object? banos = _unset,
    Object? superficieM2 = _unset,
    bool? cochera,
    List<Uint8List>? fotos,
  }) {
    return PropertyDraft(
      operacion: operacion ?? this.operacion,
      tipo: tipo ?? this.tipo,
      precio: precio ?? this.precio,
      moneda: moneda ?? this.moneda,
      ocultarPrecio: ocultarPrecio ?? this.ocultarPrecio,
      zona: zona ?? this.zona,
      ambientes: identical(ambientes, _unset) ? this.ambientes : ambientes as int?,
      dormitorios: identical(dormitorios, _unset) ? this.dormitorios : dormitorios as int?,
      banos: identical(banos, _unset) ? this.banos : banos as int?,
      superficieM2: identical(superficieM2, _unset) ? this.superficieM2 : superficieM2 as num?,
      cochera: cochera ?? this.cochera,
      fotos: fotos ?? this.fotos,
    );
  }

  PropertyData toDomain() => PropertyData(
        operacion: operacion,
        tipo: tipo,
        precio: ocultarPrecio ? const PrecioConsultar() : PrecioMonto(monto: precio <= 0 ? 1 : precio, moneda: moneda),
        zona: zona,
        caracteristicas: Caracteristicas(
          ambientes: ambientes,
          dormitorios: dormitorios,
          banos: banos,
          superficieM2: superficieM2,
          cochera: cochera,
        ),
        fotos: fotos,
      );
}

class SearchDraft {
  const SearchDraft({
    this.operacion = OperacionBuscada.compra,
    this.tipo = TipoPropiedad.departamento,
    this.zona = 'Palermo o Villa Crespo, CABA',
    this.moneda = Moneda.usd,
    this.presupuesto = 200000,
    this.ambientes = 3,
    this.dormitorios = 2,
  });

  final OperacionBuscada operacion;
  final TipoPropiedad tipo;
  final String zona;
  final Moneda moneda;
  final num? presupuesto;
  final int? ambientes;
  final int? dormitorios;

  /// Ver el comentario en `PropertyDraft.copyWith` sobre el sentinel
  /// `_unset`: sin él, borrar el input de "Presupuesto" no podría volver a
  /// dejarlo en `null`.
  SearchDraft copyWith({
    OperacionBuscada? operacion,
    TipoPropiedad? tipo,
    String? zona,
    Moneda? moneda,
    Object? presupuesto = _unset,
    Object? ambientes = _unset,
    Object? dormitorios = _unset,
  }) {
    return SearchDraft(
      operacion: operacion ?? this.operacion,
      tipo: tipo ?? this.tipo,
      zona: zona ?? this.zona,
      moneda: moneda ?? this.moneda,
      presupuesto: identical(presupuesto, _unset) ? this.presupuesto : presupuesto as num?,
      ambientes: identical(ambientes, _unset) ? this.ambientes : ambientes as int?,
      dormitorios: identical(dormitorios, _unset) ? this.dormitorios : dormitorios as int?,
    );
  }

  SearchData toDomain() => SearchData(
        operacion: operacion,
        tipo: tipo,
        zona: zona,
        presupuesto: (presupuesto == null || presupuesto! <= 0) ? null : RangoPresupuesto(moneda: moneda, hasta: presupuesto),
        deseadas: Caracteristicas(ambientes: ambientes, dormitorios: dormitorios),
      );
}

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.templateId,
    required this.content,
    required this.fecha,
    required this.titulo,
  });

  final int id;
  final String templateId;
  final PlacaContent content;
  final String fecha;
  final String titulo;
}

class SessionState {
  const SessionState({
    required this.agent,
    required this.propertyDraft,
    required this.searchDraft,
    required this.mode,
    required this.templateId,
    required this.format,
    required this.includeContact,
    required this.used,
    required this.limit,
    required this.history,
  });

  final AgentProfile agent;
  final PropertyDraft propertyDraft;
  final SearchDraft searchDraft;
  final PlacaKind mode;
  final String templateId;
  final PlacaFormat format;
  final bool includeContact;
  final int used;
  final int limit;
  final List<HistoryEntry> history;

  int get left => (limit - used).clamp(0, limit);

  PlacaContent get content => mode == PlacaKind.publicacion
      ? PublicacionContent(propertyDraft.toDomain())
      : BusquedaContent(searchDraft.toDomain());

  SessionState copyWith({
    AgentProfile? agent,
    PropertyDraft? propertyDraft,
    SearchDraft? searchDraft,
    PlacaKind? mode,
    String? templateId,
    PlacaFormat? format,
    bool? includeContact,
    int? used,
    int? limit,
    List<HistoryEntry>? history,
  }) {
    return SessionState(
      agent: agent ?? this.agent,
      propertyDraft: propertyDraft ?? this.propertyDraft,
      searchDraft: searchDraft ?? this.searchDraft,
      mode: mode ?? this.mode,
      templateId: templateId ?? this.templateId,
      format: format ?? this.format,
      includeContact: includeContact ?? this.includeContact,
      used: used ?? this.used,
      limit: limit ?? this.limit,
      history: history ?? this.history,
    );
  }

  static SessionState initial() {
    const agent = AgentProfile(
      agentId: 'fake-agent-1',
      nombre: 'Martín Herrera',
      whatsapp: '+54 9 11 5555-1234',
      redSocial: '@martin.propiedades',
      matricula: 'CUCICBA 6789',
    );
    final defaultTemplateId = templateRegistry.catalog.firstWhere((d) => d.kind == PlacaKind.publicacion).id;

    final history = [
      HistoryEntry(
        id: 1,
        templateId: _idByNombre('Franja', PlacaKind.publicacion),
        fecha: 'Ayer · 18:24',
        titulo: 'Venta · Departamento en Palermo',
        content: const PublicacionContent(
          PropertyData(
            operacion: Operacion.venta,
            tipo: TipoPropiedad.departamento,
            precio: PrecioMonto(monto: 210000, moneda: Moneda.usd),
            zona: 'Palermo, CABA',
            caracteristicas: Caracteristicas(ambientes: 4, dormitorios: 3, banos: 2, superficieM2: 96, cochera: true),
          ),
        ),
      ),
      HistoryEntry(
        id: 2,
        templateId: _idByNombre('Minimal', PlacaKind.busqueda),
        fecha: 'Ayer · 11:02',
        titulo: 'Busco · Casa en Nordelta',
        content: BusquedaContent(
          SearchData(
            operacion: OperacionBuscada.compra,
            tipo: TipoPropiedad.casa,
            zona: 'Nordelta',
            presupuesto: const RangoPresupuesto(moneda: Moneda.usd, hasta: 350000),
            deseadas: const Caracteristicas(ambientes: 5, dormitorios: 4),
          ),
        ),
      ),
      HistoryEntry(
        id: 3,
        templateId: _idByNombre('Editorial', PlacaKind.publicacion),
        fecha: 'Lun · 09:47',
        titulo: 'Alquiler · PH en Caballito',
        content: const PublicacionContent(
          PropertyData(
            operacion: Operacion.alquiler,
            tipo: TipoPropiedad.ph,
            precio: PrecioMonto(monto: 480000, moneda: Moneda.ars),
            zona: 'Caballito, CABA',
            caracteristicas: Caracteristicas(ambientes: 3, dormitorios: 2, banos: 1, superficieM2: 65, cochera: false),
          ),
        ),
      ),
    ];

    return SessionState(
      agent: agent,
      propertyDraft: const PropertyDraft(),
      searchDraft: const SearchDraft(),
      mode: PlacaKind.publicacion,
      templateId: defaultTemplateId,
      format: PlacaFormat.feed,
      includeContact: true,
      used: 9,
      limit: 10,
      history: history,
    );
  }
}

/// Busca un template por su nombre de catálogo agnóstico de marca ("Franja",
/// "Editorial"…) en vez de su id interno — así el historial fake de acá no
/// necesita mencionar ningún pack ni id de marca concretos (regla de
/// separación de marca, ver `test/architecture_test.dart`).
String _idByNombre(String nombre, PlacaKind kind) =>
    templateRegistry.catalog.firstWhere((d) => d.nombre == nombre && d.kind == kind).id;

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => SessionState.initial();

  void updateAgent(AgentProfile Function(AgentProfile) update) {
    state = state.copyWith(agent: update(state.agent));
  }

  void updateProperty(PropertyDraft Function(PropertyDraft) update) {
    state = state.copyWith(propertyDraft: update(state.propertyDraft));
  }

  void updateSearch(SearchDraft Function(SearchDraft) update) {
    state = state.copyWith(searchDraft: update(state.searchDraft));
  }

  /// Historia 2.x: elegir "publicación" o "búsqueda" en la pantalla "Tipo
  /// de placa". Reinicia el template elegido al primero del catálogo que
  /// soporte el nuevo modo (cada template de pack se registra dos veces,
  /// una por `PlacaKind` — ver `placas/registry.dart`).
  void setMode(PlacaKind mode) {
    final firstId = templateRegistry.catalog.firstWhere((d) => d.kind == mode).id;
    state = state.copyWith(mode: mode, templateId: firstId);
  }

  void pickTemplate(String templateId) {
    state = state.copyWith(templateId: templateId);
  }

  void setFormat(PlacaFormat format) {
    state = state.copyWith(format: format);
  }

  void setIncludeContact(bool value) {
    state = state.copyWith(includeContact: value);
  }

  /// Historia 2.x "Generar": consume 1 de cupo y agrega la placa al
  /// historial. La UI debe llamar esto solo cuando `state.left > 0` — si
  /// no, redirige a `/upgrade` (ver ARCHITECTURE.md §5, "el render solo
  /// ocurre después de `granted`"; acá `granted` es local/fake hasta que
  /// exista `POST /v1/placas/consume`).
  void consume() {
    final content = state.content;
    final nextId = state.history.isEmpty ? 1 : (state.history.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final entry = HistoryEntry(
      id: nextId,
      templateId: state.templateId,
      content: content,
      fecha: 'Recién',
      titulo: _titleFor(content),
    );
    state = state.copyWith(
      used: state.used + 1 > state.limit ? state.limit : state.used + 1,
      history: [entry, ...state.history],
    );
  }

  /// Fake local, equivalente al `upgradeNow()` del mockup: hasta que exista
  /// la suscripción real de Mercado Pago (ARCHITECTURE.md §6), "pasar a
  /// ilimitado" solo resetea el contador del mes.
  void upgradeNow() {
    state = state.copyWith(used: 0);
  }

  String _titleFor(PlacaContent content) {
    return switch (content) {
      PublicacionContent(:final data) =>
        '${data.operacion == Operacion.alquiler ? 'Alquiler' : 'Venta'} · ${data.tipo.label} en ${data.zona.split(',').first}',
      BusquedaContent(:final data) => 'Busco · ${data.tipo.label} en ${data.zona.split(',').first}',
    };
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
