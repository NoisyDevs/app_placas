# Generador de Placas RE/MAX

Herramienta self-serve para que agentes inmobiliarios de RE/MAX generen
placas de marketing (feed, story, WhatsApp) para sus propiedades, sin
depender de Canva ni de un diseñador.

- Requerimientos completos (español): [`requerimientos-placas-remax-mvp.md`](requerimientos-placas-remax-mvp.md)
- Arquitectura técnica: [`ARCHITECTURE.md`](ARCHITECTURE.md)

## Estructura del repo

```
app/         Flutter (mobile Android/iOS + web), un solo codebase
backend/     FastAPI — cupo, suscripción de Mercado Pago, webhook
supabase/    schema.sql — Postgres + RLS (perfil, suscripción, cupo)
```

## Backend

```bash
cd backend
python -m venv .venv
.venv/Scripts/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env          # completar con credenciales reales
pytest                        # 30 tests
uvicorn app.main:app --reload
```

## App Flutter

Requiere el [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable). La primera vez, generar las carpetas de plataforma sobre el
código ya versionado:

```bash
cd app
flutter create --platforms=android,web --org=com.placasapp .
flutter pub get
```

Después, para cualquier cambio:

```bash
flutter analyze
dart test test/domain test/architecture_test.dart   # dominio puro, sin engine
flutter test                                         # widgets
flutter run -d chrome                                # o -d edge / -d windows
```

## Golden tests

`app/test/goldens/` tiene 50 tests de snapshot visual (5 templates × 2 tipos
× 2 formatos × perfiles de contenido mínimo/típico/extremo) que comparan el
render actual contra una imagen de referencia guardada, para frenar
regresiones visuales silenciosas en los templates. Si un cambio intencional
altera cómo se ve un template, regenerar las referencias:

```bash
flutter test test/goldens --update-goldens
```

## Supabase

`supabase/migrations/` es lo que aplica `supabase db reset` de verdad;
`supabase/schema.sql` es un espejo legible del mismo schema (tablas, RLS,
funciones de cupo), que se mantiene sincronizado a mano. Requiere Docker
para levantar una instancia local:

```bash
supabase start      # revisar `supabase status` para la URL real —
                     # puede no ser el puerto 54321 default si hay otro proyecto local usándolo
supabase db reset    # aplica supabase/migrations/
```

## Probar en un Android real

No hace falta instalar Android Studio completo — con las "command line
tools" del SDK alcanza:

```bash
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.1.0"
flutter doctor -v    # confirmar que el Android toolchain está en verde
```

Con el celular conectado por USB (depuración USB activada, popup de
autorización aceptado), `flutter devices` lo tiene que listar. Si la app va
a hablar con el backend/Supabase que corren en esta PC, hace falta mapear
los puertos:

```bash
adb reverse tcp:8000 tcp:8000
adb reverse tcp:55321 tcp:55321   # o el puerto real de `supabase status`
```

## Estado

Ver "Project status" en [`CLAUDE.md`](CLAUDE.md) para qué está hecho y qué
falta (iOS, fuente `Space Grotesk` sin empaquetar, rotación EXIF, Supabase
solo local todavía). Diseño técnico completo y "Orden de implementación por
fases" en [`ARCHITECTURE.md`](ARCHITECTURE.md#8-orden-de-implementación-por-fases).
