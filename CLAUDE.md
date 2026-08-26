# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

MVP scaffold is built and working end-to-end on this machine: real Auth,
real quota/billing calls to the backend, real placa export (downloads an
actual PNG), 5 RE/MAX templates rendering with real fonts, 50 golden tests,
and the app running on a real Android device. See `ARCHITECTURE.md` for the
full technical design and §8 for the phase-by-phase build order this
followed.

**Not done yet:**
- iOS — needs a Mac or a cloud CI (e.g. Codemagic); nothing iOS-specific has
  been attempted.
- `'Space Grotesk'` (the app's neutral-UI body font) is referenced by code
  but not packaged as an asset — Flutter silently falls back to the system
  font for it. Deliberately left as-is for now (see how `'Space Mono'` /
  `'DM Serif Display'` were packaged in `app/lib/app/theme/fonts/` for the
  pattern to follow when this gets picked up).
- EXIF photo rotation (camera photos can render sideways) not handled yet.
- Supabase is **local-only** (this machine's `supabase start`) — nothing is
  deployed to a hosted Supabase project. Mercado Pago credentials are dev
  placeholders — subscribing will reach the backend but fail at MP.
- Búsqueda illustrations are Flutter's built-in Material Icons (legally
  safe, not a copyright risk) rather than commissioned/licensed art — an
  intentional placeholder, not a bug (see "Preguntas abiertas" in the
  requirements doc).

## Development commands

Flutter SDK lives outside OneDrive at `C:\src\flutter` (this machine only —
OneDrive syncing an SDK's tens of thousands of files corrupts builds and
burns cloud quota). If a fresh shell doesn't have it on `PATH`, prefix
commands with:
```
$env:Path = "$env:Path;C:\src\flutter\bin"
```

```bash
cd app
flutter pub get
flutter analyze
dart test test/domain test/architecture_test.dart   # pure-Dart domain + brand-separation rules, no engine needed
flutter test                                         # widgets + all 50 golden tests
flutter test test/goldens --update-goldens           # only after an intentional visual change to a template
flutter run -d chrome                                # or -d edge / -d windows / a real device id from `flutter devices`
flutter build web --debug
```

Web caching gotcha: Chromium (and possibly V8's code cache) can keep
serving a stale `main.dart.js` even from a brand-new tab with
`Cache-Control: no-store` on every response. The only reliable fix found
this session was serving from a **port the browser has never visited**
(`app/tool/serve_web.ps1 -Port <new-port>`) — don't burn time re-debugging
this if a rebuilt app still shows old behavior in the browser.

Backend (FastAPI):
```bash
cd backend
.venv/Scripts/python -m pytest          # 30 tests, no external services needed (fakes/mocks)
.venv/Scripts/python -m uvicorn app.main:app --port 8000
```

Supabase (local dev instance, already initialized in `supabase/`):
```bash
supabase start   # this machine runs it on the 553xx port block, not the 543xx default —
                  # another local project already owns 543xx; check `supabase status` for the real URL
supabase db reset  # re-applies supabase/migrations/ (schema.sql is the human-readable mirror, kept in sync manually)
```

Android (command-line SDK tools only, no Android Studio — see git log
"Instalar Android SDK..." for how this was set up if it needs redoing on
another machine): `ANDROID_HOME=C:\android-sdk`, JDK 17 at
`C:\jdk-17.0.20.1+1`. A real device over USB needs `adb reverse tcp:8000
tcp:8000` and `adb reverse tcp:55321 tcp:55321` (or whatever port
`supabase status` reports) so the phone can reach the PC's backend/Supabase
as if they were local to the device.

## Module layout

```
app/         Flutter — one codebase, two products (mobile + web)
  lib/domain/       pure Dart (no Flutter imports): PropertyData, TemplateDescriptor,
                     placa_resolver.dart — the template engine's business logic
  lib/placas/kit/    brand-agnostic render primitives (PlacaCanvas, PlacaTemplate, text policies)
  lib/placas/packs/remax/   the only brand pack — templates, brand colors/logo, illustrations
  lib/placas/export/ RepaintBoundary -> PNG capture
  lib/app/           neutral design system (theme, shared widgets) — must never import packs/remax
  lib/features/      one folder per screen area (auth, profile, wizard, billing, history, session)
  lib/services/      supabase_service.dart, backend_client.dart, share_service*.dart
  test/domain/        pure-Dart tests
  test/goldens/       golden_fixtures.dart (mínimo/típico/extremo content profiles) + template_goldens_test.dart
  test/architecture_test.dart   scans source to enforce the brand-separation rule mechanically
backend/     FastAPI — quota consumption, Mercado Pago subscription + webhook
  app/routers/       placas.py (consume), billing.py, webhooks.py
  app/services/      billing_state.py (pure state machine), mercadopago.py, mp_signature.py
  tests/             30 tests against fakes — no live Supabase/MP needed to run these
supabase/
  schema.sql          human-readable full schema (tables, RLS, functions) — kept in sync with migrations/ by hand
  migrations/          what `supabase db reset` actually applies
```

## What this product is

A self-serve tool ("Generador de Placas") for RE/MAX real estate agents to
generate marketing images ("placas") for property listings — feed posts,
Instagram/WhatsApp stories — from pre-designed templates carrying RE/MAX brand
identity, without needing Canva or a designer. Full requirements are in
`requerimientos-placas-remax-mvp.md` (Spanish); ARCHITECTURE.md has the full
technical design built from that spec.

## Key domain rules (do not violate silently when implementing)

- **One-shot property data**: property listing data and photos are NOT
  persisted — used to generate the "placa" and discarded. Only the agent's
  profile persists. `PropertyData`/`SearchData` in `lib/domain/` deliberately
  have no `id` field and no repository — this is enforced by the type shapes,
  not just convention.
- **No watermarks on any tier.** The free/paid gate is a monthly generation
  count (10 free "placas"/month, enforced server-side via a ledger table —
  see `supabase/schema.sql`'s `placa_events` / `consume_placa_credit()`), not
  a watermark. Don't reintroduce watermarking.
- **Brand separation**: the app's own UI (`lib/app/`, `lib/features/`) uses a
  neutral, brand-agnostic design system. RE/MAX identity lives *only* inside
  `lib/placas/packs/remax/`. This is mechanically enforced by
  `test/architecture_test.dart` — it fails the build if `lib/app/**` or
  `lib/features/**` import from `packs/**` or contain the string "remax".
  Never bleed RE/MAX styling into app UI components.
- **Templates are fixed/non-customizable** in the MVP — agents pick a
  template, they don't edit colors/positions/fonts.
- **RE/MAX logo integrity**: any template using the RE/MAX logo must keep
  official colors and must not crop, stretch, or otherwise alter the logo
  (`BrandLogo` in the kit enforces `BoxFit.contain` only).
- **Two placa types**: "publicación" (a real listing, with photos) and
  "búsqueda" (agent is searching for a property on behalf of a client, no
  photos — uses a curated placeholder illustration by property type instead).
  Both generate in 1:1 (feed) and 9:16 (story) aspect ratios — rendered on a
  fixed 1080×1080 / 1080×1920 logical canvas so the on-screen preview and the
  exported PNG are pixel-identical.
- **Contact-info toggle**: placas can be generated with or without the
  agent's contact info stamped on them (for co-broke sharing between
  colleagues), but the "matrícula" (license number) stays on the placa even
  with contact info hidden, if the template requires it — this is a legal
  requirement, not a style choice. `PlacaRenderModel.contacto` and
  `.matricula` are independent fields precisely so this can't be forgotten.
- **Courtesy Pro accounts**: some accounts are manually flagged as Pro
  (`subscriptions.status = 'courtesy'`) without going through the Mercado
  Pago payment flow (distribution partner comps) — set via direct SQL, not
  an admin endpoint. The MP webhook handler explicitly skips these accounts.
- **AI description generation (Épica 4) is post-MVP** and explicitly out of
  scope until per-generation cost is analyzed — don't build it opportunistically
  alongside MVP work; it needs its own usage-gating tier.
