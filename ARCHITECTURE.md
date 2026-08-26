# ARCHITECTURE.md

Arquitectura técnica del Generador de Placas para Agentes RE/MAX (MVP). Este
documento asume que ya leíste `requerimientos-placas-remax-mvp.md` — acá se
explica el **cómo**, no el **qué**.

## 0. Decisiones de alto nivel

| Decisión | Elegida | Por qué (resumen) |
|---|---|---|
| Compositing de la placa | **Client-side, en Flutter** | El preview ES el output (un solo motor de render). Las fotos de la propiedad nunca salen del dispositivo → "one-shot / efímero" es cierto por construcción, no por disciplina. Costo por placa ≈ 0. |
| Backend | **Supabase (Auth + Postgres + RLS) + FastAPI delgado** | Flutter habla directo con Supabase para perfil y lectura de cupo. FastAPI solo hace lo que necesita secretos de servidor: suscripción de Mercado Pago, webhook, y consumo de cupo (escritura, no lectura). |
| Codebase | **Un Flutter único → mobile nativo + web** | Ya fijado en el doc de requerimientos (no es una decisión de este documento). |
| State management (Flutter) | **flutter_riverpod, sin codegen** | `AsyncValue` mapea 1:1 a los tres estados que todo tiene acá (loading/data/error). Providers testeables sin árbol de widgets. Sin `build_runner` porque no hay SDK instalado todavía para correr codegen. |
| Routing (Flutter) | **go_router** | El target web necesita URLs reales. Es el default del equipo de Flutter. |
| Motor de templates | **Descriptor de datos + resolver puro + widget tonto** (ver §2) | Ni JSON declarativo completo (reinventa Flutter adentro de Flutter) ni widgets 100% hardcodeados sin capa común (cada template reimplementa las mismas reglas y diverge). |

## 1. Vista de capas

```
┌─────────────────────────── Flutter (mobile + web) ───────────────────────────┐
│                                                                                │
│  app/            design system neutro (NO sabe qué es RE/MAX)                 │
│  features/        auth · profile · wizard · billing · quota                   │
│      │                                                                        │
│      ▼                                                                        │
│  domain/          Dart puro, sin imports de Flutter. Testeable con `dart test`│
│      │            PlacaSpec, PropertyData, TemplateDescriptor, resolver       │
│      ▼                                                                        │
│  placas/kit/      primitivas de render agnósticas de marca                    │
│  placas/packs/    remax/  ← única carpeta que sabe qué es RE/MAX              │
│                                                                                │
└───────┬─────────────────────────────────────────────────┬────────────────────┘
        │ supabase-flutter (directo)                       │ HTTPS + JWT
        ▼                                                   ▼
┌───────────────────┐                          ┌─────────────────────────────┐
│     Supabase       │                          │      FastAPI (backend/)     │
│  Auth · Postgres    │◄────── service_role ─────│  consume cupo, suscripción, │
│  RLS · Storage      │        (solo backend)     │  webhook de Mercado Pago    │
└───────────────────┘                          └──────────────┬───────────────┘
                                                                 │
                                                                 ▼
                                                        Mercado Pago
                                                        (Suscripciones / preapproval)
```

**Regla dura:** las fotos de la propiedad nunca cruzan esta frontera hacia
ningún backend. Viven en memoria del dispositivo (`Uint8List`), se usan para
renderizar, y se descartan al cerrar el flujo. Ningún endpoint recibe una foto
de propiedad.

## 2. El motor de templates

Es el corazón del producto. El contrato tiene tres reglas que no se negocian:

**Regla 1 — la app nunca ve píxeles, solo un `TemplateDescriptor`.**
El catálogo, el formulario y la llamada de cupo razonan sobre datos puros. El
widget real de un template solo se obtiene vía `TemplateRegistry.byId()`.

**Regla 2 — toda la lógica de negocio corre *antes* del widget, en una función
pura.**

```dart
// lib/domain/placa_resolver.dart — Dart puro, sin import de Flutter
PlacaRenderModel resolvePlaca({
  required PlacaSpec spec,
  required AgentProfile profile,
  required TemplateDescriptor template,
  required PlacaFormat format,
});
```

El resultado (`PlacaRenderModel`) ya viene "limpio": sin nulls con
significado. Un campo vacío nunca llega al widget — es un problema de layout
de longitud de lista (0..N chips), no un `if`. El contacto apagado y la
matrícula son campos independientes por construcción, así que la regla legal
("matrícula sobrevive aunque el contacto esté oculto") no se puede olvidar en
el template #4. Si un widget de template tiene un
`if (model.dormitorios != null)`, eso es un bug en el resolver, no en el
template — es la regla de revisión de código para esta capa.

**Regla 3 — canvas lógico fijo + escala, para que el preview SEA el output.**
Cada template renderiza sobre un canvas absoluto: feed 1080×1080, story
1080×1920. Ningún valor de diseño es responsive dentro de un template. El
preview escala ese canvas con `FittedBox`; el export captura el mismo widget
con un `pixelRatio` que compensa la escala, así que un preview de teléfono a
340pt y uno de desktop a 700pt emiten exactamente 1080px. El WYSIWYG es cierto
por construcción, no por disciplina.

### Dos formatos, un widget, dos composiciones

```dart
abstract class PlacaTemplate {
  TemplateDescriptor get descriptor;
  Widget build(BuildContext context, PlacaRenderModel model, PlacaFormat format);
}
```

Internamente cada template implementa `_buildFeed` y `_buildStory` como dos
composiciones separadas que comparten subwidgets (bloque de precio, fila de
chips, franja de contacto, logo). 1:1 y 9:16 son diseños genuinamente
distintos — una story es un hero vertical más un tercio inferior; un feed es
un split o un overlay. Un único layout parametrizado para cubrir ambos se
vuelve ilegible ya con dos templates.

### Overflow de texto — el modo de falla clásico de este tipo de producto

Cuatro capas, las cuatro necesarias:

1. **Ningún `Text` crudo dentro de un template.** El kit expone tres políticas:

   | Widget del kit | Se usa para | Política |
   |---|---|---|
   | `PlacaHeadline` | precio | shrink-to-fit, 1 línea, **ellipsis prohibido** (un precio truncado es peor que uno chico). |
   | `PlacaLabel` | zona, línea de tipo | shrink hasta un piso, después ellipsis, `maxLines: 2` (zonas como "Barrio Parque Leloir, Ituzaingó" son de longitud no acotada). |
   | `PlacaChip` | características | nunca reduce texto; el **contenedor** absorbe con `Wrap` a una segunda fila, y el resolver cappea la cantidad vía `descriptor.maxFeatureChips`. |

   Se usa `auto_size_text` en vez de reinventarlo a mano.

2. **Se ataja en el input, no en el output.** El `TemplateDescriptor.limits`
   publica topes de caracteres por campo y el formulario los aplica con
   contador en vivo ("Zona (máx. 34)"). El agente ve el riesgo antes de
   generar. Doble cinturón: el form cappea, el widget además reduce.

3. **`assert` de overflow en debug**, para que un overflow sea un test rojo,
   no una captura con rayas amarillas en producción.

4. **Golden tests: template × formato × perfil de contenido.** Perfiles
   `minimo` / `tipico` / `extremo` (precio oculto y 0 características vs.
   longitud máxima en todo + "Consultar" + 4 fotos + matrícula con contacto
   apagado). Es el único mecanismo que frena el deterioro silencioso con el
   tiempo. Requiere el SDK instalado — llega en la Fase 2+.

### Separación de marca, forzada mecánicamente

```
lib/placas/kit/            agnóstico. SIN colores, SIN logos. Recibe un BrandTheme.
lib/placas/packs/remax/
    remax_brand.dart       colores oficiales como const — el ÚNICO lugar donde existen
    remax_pack.dart
    templates/{hero_v1,split_v1,minimal_v1,busqueda_v1}.dart
    assets/{logo_remax.svg, ilustraciones/*.svg, LICENSES.md}
```

`BrandLogo` en el kit solo pinta con `BoxFit.contain` dentro de una caja de
clearspace mínimo, y falla en debug si alguien intenta `cover`/`fill` —
la integridad del logo queda estructuralmente imposible de violar, en vez de
depender de que nadie se olvide.

Esto se verifica con un test de arquitectura (`test/architecture_test.dart`,
~40 líneas) que lee el código fuente y falla si:
- algo bajo `lib/app/**` o `lib/features/**` importa `lib/placas/packs/**`
- algo bajo `lib/placas/**` importa `lib/app/theme/**`
- hay un `Color(0x` o `Colors.` literal bajo `lib/placas/kit/**`
- aparece la palabra "remax" (case-insensitive) en cualquier lugar bajo
  `lib/app/**` o `lib/features/**`

Sumar una marca nueva más adelante = una carpeta nueva bajo `packs/` y una
const. En el MVP: `const activePack = remaxPack;`.

## 3. Modelo de dominio

El límite one-shot / futura cartera está en la **forma de los tipos**, no en
un comentario: `PropertyData` no tiene `id`, ni `agentId`, ni repositorio, ni
serializador de persistencia. Para agregar cartera más adelante se agrega
`SavedProperty { id, agentId, PropertyData data, createdAt }` — la identidad
de persistencia *envuelve* el value object, en vez de que el value object le
crezca un id. Ese es el cambio que evita tener que reescribir todo.

```dart
// lib/domain/ — Dart puro, cero imports de Flutter (testeable con `dart test`)

class AgentProfile {                      // espeja public.profiles 1:1
  final String agentId; final String nombre; final String whatsapp;
  final String? redSocial; final String? matricula; final String? fotoPath;
  bool get isCompleteForPlaca =>
      nombre.isNotEmpty && whatsapp.isNotEmpty && fotoPath != null;
}

enum Operacion { venta, alquiler }
enum TipoPropiedad { casa, departamento, ph, lote, local, oficina, cochera, campo }
enum Moneda { usd, ars }
enum PlacaFormat { feed, story }          // 1080x1080 / 1080x1920
enum PlacaKind { publicacion, busqueda }

sealed class Precio {}
class PrecioMonto extends Precio { final num monto; final Moneda moneda; }
class PrecioConsultar extends Precio {}

class Caracteristicas {                   // null == no se renderiza
  final int? ambientes, dormitorios, banos;
  final num? superficieM2;
  final bool? cochera;
}

class PropertyData {                      // ONE-SHOT: sin id, sin repo, sin tabla
  final Operacion operacion; final TipoPropiedad tipo; final Precio precio;
  final String zona; final Caracteristicas caracteristicas;
  final List<Uint8List> fotos;            // solo bytes, nunca una URL
}

class SearchData {
  final OperacionBuscada operacion; final TipoPropiedad tipo; final String zona;
  final RangoPresupuesto? presupuesto; final Caracteristicas deseadas;
}

sealed class PlacaContent {}
class PublicacionContent extends PlacaContent { final PropertyData data; }
class BusquedaContent    extends PlacaContent { final SearchData   data; }

class PlacaSpec {
  final PlacaContent content; final String templateId;
  final Set<PlacaFormat> formats; final bool includeContact;  // default true
}

class TemplateDescriptor {
  final String id;            // "remax.hero_v1"
  final String packId;        // "remax"
  final String nombre;        // etiqueta de catálogo en es-AR
  final PlacaKind kind;
  final int photoSlots, minPhotos, maxFeatureChips;
  final bool requiresMatricula;
  final Set<PlacaFormat> formats;
  final TemplateLimits limits;   // topes de caracteres por campo, los consume el FORM
  final String thumbAsset;
}
```

**Qué espeja una tabla y qué deliberadamente no:**
- `AgentProfile` ↔ `public.profiles` — 1:1.
- `PlacaSpec` / `PropertyData` / `SearchData` — **no existe tabla, a propósito.**
- `TemplateDescriptor` — const de Dart en tiempo de compilación, **no una
  tabla.** Una tabla acá permitiría que el código y la data no coincidan en
  cuántos slots de foto tiene un template.
- Cupo — autoritativo del servidor; el cliente solo tiene una proyección
  `QuotaStatus` de solo lectura, nunca un contador que pueda escribir.

## 4. Postgres + RLS

Ver `supabase/schema.sql` para el DDL completo. Decisiones clave:

- **Ledger de eventos, no un contador mutable.** `placa_events` es append-only;
  el período se calcula con `date_trunc('month', created_at AT TIME ZONE
  'America/Argentina/Buenos_Aires')`. No hay "momento de reseteo" que pueda
  fallar (ni cron, ni race de lazy-reset) — el mes rueda por aritmética.
  Bonus: da analytics gratis (template más usado, publicación vs. búsqueda).
- **1 placa = 1 acto de generación, no 1 por formato.** Genera 1:1 y 9:16 a la
  vez y consume un solo crédito — así coincide "10 placas por mes" con
  "genero en los dos formatos" del mismo requerimiento.
- **RLS impide que el agente infle su propio cupo:** `subscriptions` no tiene
  policy de insert/update para el rol autenticado — solo `service_role`
  (el backend) puede escribirla. `placa_events` no tiene policy de insert
  para el agente — el cliente físicamente no puede escribir, borrar ni
  retrofechar una fila de uso.
- **Downgrade perezoso, sin cron:** `quota_status()` trata un `pro` cuyo
  `current_period_end` ya pasó como `free`, calculado en el momento de la
  lectura. Un registro `courtesy` tiene `current_period_end = null` y queda
  pro para siempre.
- **Idempotencia:** `placa_events` tiene `unique (agent_id, client_request_id)`
  — el mismo `request_id` reintentado nunca cobra dos veces.

## 5. Cupo con render client-side

Principio explícito: **el servidor vende permiso para generar, no vende
píxeles.** Como no puede retener los píxeles (el render es local), no
pretende hacerlo.

1. El preview es gratis e ilimitado — no consume crédito.
2. El cupo se lee al entrar al wizard (`rpc('quota_status')` directo a
   Supabase) y se muestra como "Te quedan 7 placas este mes". Si ya está en 0,
   se muestra el muro de upgrade **antes** de que el agente cargue los datos.
3. El crédito se consume al tocar "Generar": `POST /v1/placas/consume` con un
   `request_id` determinístico por intento de generación (así un doble-tap
   es gratis por construcción). Responde `{granted, used, limit, remaining}`
   o `403 quota_exceeded`.
4. El render solo ocurre después de `granted`.
5. Si el render falla después de consumir, el reintento reenvía el mismo
   `request_id` (idempotente, gratis). **No hay endpoint de reembolso** — es
   una superficie de abuso, es más código, y el peor caso es perder 1 de 10
   créditos en una falla rara que se arregla a mano. Es una herramienta de
   consumo de bajo riesgo, no DRM.
6. Backend inalcanzable → falla cerrado, con mensaje claro y reintento. Nunca
   falla abierto.
7. Anti-abuso más allá de auth + conteo server-side: **ninguno.** Sin
   fingerprinting ni attestation.

## 6. Backend FastAPI + Mercado Pago

`backend/app/`: `main.py`, `config.py`, `deps.py` (verifica el JWT de
Supabase vía JWKS), `supabase.py` (wrapper de httpx sobre PostgREST/RPC con
la service_role key — **sin driver de base de datos**), `routers/{placas,
billing,webhooks}.py`, `services/{mercadopago,billing_state}.py`,
`schemas.py`.

```
GET  /v1/health
POST /v1/placas/consume        {request_id, template_id, kind, formats[], include_contact}
GET  /v1/billing/status
POST /v1/billing/subscribe     -> crea preapproval en MP, devuelve {init_point, preapproval_id}
POST /v1/billing/cancel
POST /v1/webhooks/mercadopago  -> sin auth, verificado por firma
```

Deliberadamente **no** se construye: `/v1/quota` (el cliente lee Supabase
directo), ni endpoints de admin. **Pro de cortesía es un SQL manual** en el
dashboard de Supabase — pasa ~2 veces, no justifica una superficie de auth
nueva.

**Máquina de estados `(tier, status)`:**

| Estado | Significado | Entra por |
|---|---|---|
| `(free, none)` | default al registrarse | trigger de signup |
| `(free, pending)` | preapproval creado, no autorizado aún | `/billing/subscribe` |
| `(pro, authorized)` | MP confirmó; `current_period_end` = próximo pago | webhook |
| `(pro, paused)` | pago fallando, MP reintenta; sigue pro hasta `current_period_end` | webhook |
| `(pro, cancelled)` | cancelado; pro hasta fin de período, después free (lazy) | webhook o `/billing/cancel` |
| `(pro, courtesy)` | comped, sin `mp_preapproval_id`, sin `current_period_end` | SQL manual |

El webhook **salta cualquier agente `status = 'courtesy'`** como primera
línea, y siempre re-consulta `GET /preapproval/{id}` a MP en vez de confiar en
el payload — así una entrega fuera de orden es inofensiva.

**Idempotencia del webhook:** verificar `x-signature` (HMAC) → 401 si no
coincide; `insert ... on conflict (mp_event_id) do nothing` → si no vuelve
fila, ya se procesó, devolver 200 y cortar; recién ahí aplicar la transición.
Siempre 200 rápido (MP reintenta ante no-2xx).

## 7. Estructura del proyecto Flutter

```
app/
  pubspec.yaml
  lib/
    main.dart
    app/                           # NEUTRO. Design system agnóstico de marca
      router.dart
      theme/{app_theme,app_colors,app_spacing}.dart
      widgets/{app_button,app_text_field,app_scaffold,app_empty_state}.dart
    features/
      auth/ profile/ wizard/ billing/ quota/     # cada una: data/ application/ presentation/
    domain/                        # Dart puro, cero imports de Flutter
      agent_profile.dart property_data.dart search_data.dart placa_spec.dart
      template_descriptor.dart placa_render_model.dart placa_resolver.dart formatters.dart
    placas/
      kit/  placa_canvas.dart placa_text.dart placa_photo.dart feature_chips.dart
            contact_strip.dart brand_logo.dart brand_theme.dart
            placa_template.dart template_registry.dart
      packs/remax/  remax_brand.dart remax_pack.dart templates/*.dart assets/
      export/ placa_exporter.dart placa_saver_io.dart placa_saver_web.dart
    services/ supabase_service.dart backend_client.dart photo_picker.dart share_service.dart
  test/ domain/placa_resolver_test.dart  architecture_test.dart  goldens/
```

Diferencias de plataforma vía **conditional export**, nunca ramas en el
código de features:

```dart
export 'share_service_io.dart' if (dart.library.js_interop) 'share_service_web.dart';
```

- **Fotos:** `image_picker` en ambos targets, siempre vía
  `XFile.readAsBytes()` — el pipeline es bytes-only e idéntico en web, que es
  también lo que hace estructuralmente cierto que "las fotos nunca salen del
  dispositivo".
- **Compartir:** mobile → share sheet nativo (`share_plus`). Web → descarga
  explícita (anchor + blob) por default, con botón "Compartir" solo si la Web
  Share API está presente.
- **Guardar en galería** (mobile): `gal`, necesita permisos en las carpetas
  `android/`/`ios/` que genera `flutter create` — llega en Fase 3+.

## 8. Orden de implementación por fases

Estado real al día de hoy (ver "Project status" en `CLAUDE.md` para el
detalle vivo — esto queda como el plan original, con una marca de qué se
cumplió):

- ✅ **Fase 0** — todo lo verificable hoy, sin Flutter: `ARCHITECTURE.md`,
  `supabase/schema.sql` + `seed.sql`, backend FastAPI con `/v1/health` +
  `/v1/placas/consume`, tests con pytest.
- ✅ **Fase 1** — `pubspec.yaml` + `lib/domain/**` (Dart puro).
- ✅ **Fase 2** — primer píxel: `main.dart` renderiza **una placa hardcodeada**
  (`hero_v1`, feed) con datos fake. Sin auth, sin backend, sin wizard. Es el
  hito visible y de paso valida la parte más difícil (el kit) antes de armar
  el resto.
- ✅ **Fase 3** — wizard + export + compartir/descargar, con perfil local fake.
  Producto demostrable de punta a punta.
- ✅ **Fase 4** — Auth de Supabase, CRUD de perfil, subida de foto a Storage,
  lectura de cupo.
- ✅ **Fase 5** — llamada de consumo + muro de upgrade.
- 🟡 **Fase 6** — suscripción MP + webhook (código y máquina de estados
  hechos y testeados); cortesía por SQL (mecanismo listo, sin usar todavía).
  Falta probar contra credenciales reales de Mercado Pago — las de hoy son
  placeholders de dev, la suscripción llega al backend pero MP la rechaza.
- 🟡 **Fase 7** — los 5 templates y la suite completa de 50 goldens están
  hechos. Falta: hardening web más allá de forzar CanvasKit, empaquetado
  para tiendas (Play Store / App Store), iOS (necesita Mac o CI en la nube),
  y la fuente `Space Grotesk` sigue sin empaquetar (cae a la fuente del
  sistema — deliberadamente sin resolver todavía).

## 9. Trampas conocidas y qué se difiere a propósito

1. **El export en web necesita CanvasKit** — `RepaintBoundary.toImage` no es
   confiable con el renderer HTML. Forzar CanvasKit en el build web (costo:
   ~2MB extra de carga inicial).
2. **`Offstage: true` no pinta**, así que `toImage` falla ahí adentro. El
   patrón confiable es capturar el preview visible ya escalado, compensando
   con `pixelRatio`.
3. **Fuentes:** nada de `google_fonts` con fetch en runtime para texto de
   placa (rompe goldens determinísticos y offline). Fuentes empaquetadas como
   asset del pack. Si la fuente oficial de RE/MAX no se puede embeber, se
   elige una licenciada similar y se documenta en `packs/remax/LICENSES.md`.
4. **Rotación EXIF** en fotos de cámara Android — normalizar orientación al
   elegir la foto, no confiar en que `Image.memory` la respete.
5. **Deriva de precio en MP** — el monto de la preapproval queda fijo en ARS
   al crearla; "USD 10 con cláusula Banco Nación" implica que ese número
   ARS se desactualiza. Se define un monto ARS con margen + una cláusula de
   ToS de actualización trimestral. **No se automatiza FX en el MVP.**
6. **Facturación AFIP** — manual mensual en el MVP.
7. **Placeholders de búsqueda (pregunta abierta del doc de requerimientos)**
   — "cualquier imagen de Google" es un riesgo legal real al lado del logo
   de RE/MAX. Debe resolverse antes de salir a producción: ilustraciones
   encargadas o un set explícitamente licenciado, con `LICENSES.md` en el
   pack.
8. **iOS necesita cuenta de Apple Developer** — se lanza primero
   Android + web.
9. Se difiere a propósito: espejo `/v1/quota`, cualquier API de admin,
   endpoint de reembolso/void de crédito, entrega remota de templates,
   contabilidad de crédito por formato, y la Épica 4 completa (descripciones
   con IA).
