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

## Supabase

`supabase/schema.sql` define el schema completo (tablas, RLS, funciones de
cupo). Requiere Docker para levantar una instancia local:

```bash
supabase start
supabase db reset   # aplica schema.sql + seed
```

## Estado

MVP en construcción. Ver "Orden de implementación por fases" en
[`ARCHITECTURE.md`](ARCHITECTURE.md#8-orden-de-implementación-por-fases)
para qué está hecho y qué falta.
