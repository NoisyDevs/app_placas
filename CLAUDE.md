# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This repository currently contains only the product requirements document
(`requerimientos-placas-remax-mvp.md`). No code has been written yet — there is
no `pubspec.yaml`, no backend project, and no git history. There are no build,
lint, or test commands to document until the codebase is scaffolded.

When implementation starts, update this file with:
- The actual build/run/test commands (e.g. `flutter run`, `flutter test`, `flutter build web`).
- The real module layout once it exists, instead of the planned one below.

## What this product is

A self-serve tool ("Generador de Placas") for RE/MAX real estate agents to
generate marketing images ("placas") for property listings — feed posts,
Instagram/WhatsApp stories — from pre-designed templates carrying RE/MAX brand
identity, without needing Canva or a designer. Full requirements are in
`requerimientos-placas-remax-mvp.md` (Spanish); the summary below is the
minimum needed to make architectural decisions consistently with that spec.

## Planned architecture (from the requirements doc)

- **Client**: single Flutter codebase targeting two separate products — a
  native mobile app (Android/iOS) and a responsive web app — not one
  responsive page serving both. Platform differences to account for: photo
  upload, native share sheet, and web download flows differ per target.
- **Backend**: FastAPI, used at least for the Mercado Pago Suscripciones
  (`preapproval`) recurring-billing integration.
- **Auth/data**: Supabase Auth + Row Level Security, isolated per `agent_id`
  (multi-tenant: each agent sees only their own profile and usage).
- **Image compositing**: server-side (Python/Pillow) vs. client-side (Flutter
  canvas) is explicitly undecided — left to the implementing architect (see
  "Compositing" in Preguntas abiertas).

## Key domain rules (do not violate silently when implementing)

- **One-shot property data**: property listing data and photos are NOT
  persisted — used to generate the "placa" and discarded. Only the agent's
  profile persists. Design data models so persistent "cartera" (property
  portfolio) can be added later without a rework, but don't build it now.
- **No watermarks on any tier.** The free/paid gate is a monthly generation
  count (10 free "placas"/month), not a watermark — this was a deliberate
  decision to protect RE/MAX brand identity. Don't reintroduce watermarking.
- **Brand separation**: the app's own UI uses a neutral, brand-agnostic design
  system. RE/MAX identity lives *only* inside the "placa" templates (the
  output), never in app chrome. This is intentional: the same app is meant to
  serve other real estate brands later by swapping the template pack — RE/MAX
  is the first pack, not the app's theme. Never bleed RE/MAX styling into app
  UI components.
- **Templates are fixed/non-customizable** in the MVP — agents pick a
  template, they don't edit colors/positions/fonts.
- **RE/MAX logo integrity**: any template using the RE/MAX logo must keep
  official colors and must not crop, stretch, or otherwise alter the logo.
- **Two placa types**: "publicación" (a real listing, with photos) and
  "búsqueda" (agent is searching for a property on behalf of a client, no
  photos — uses a curated placeholder illustration by property type instead).
  Both generate in 1:1 and 9:16 aspect ratios.
- **Contact-info toggle**: placas can be generated with or without the
  agent's contact info stamped on them (for co-broke sharing between
  colleagues), but the "matrícula" (license number) stays on the placa even
  with contact info hidden, if the template requires it — this is a legal
  requirement, not a style choice.
- **Courtesy Pro accounts**: some accounts are manually flagged as Pro without
  going through the Mercado Pago payment flow (distribution partner comps) —
  keep this path separate from the paid-subscription state machine.
- **AI description generation (Épica 4) is post-MVP** and explicitly out of
  scope until per-generation cost is analyzed — don't build it opportunistically
  alongside MVP work; it needs its own usage-gating tier.
