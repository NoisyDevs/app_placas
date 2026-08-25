-- Espejo de supabase/schema.sql para que `supabase db reset` lo aplique
-- automáticamente. supabase/schema.sql sigue siendo la fuente documentada
-- que referencian README.md y ARCHITECTURE.md §4 (single-file schema a
-- propósito, no un historial de migraciones incremental) — este archivo
-- existe únicamente porque el CLI de Supabase solo aplica DDL que vive bajo
-- supabase/migrations/. Si se edita schema.sql, este archivo se debe
-- actualizar en el mismo commit (o regenerar copiando su contenido).
--
-- Generador de Placas RE/MAX — schema del MVP.
-- Ver ARCHITECTURE.md §4 para el razonamiento detrás de cada decisión.
--
-- Diseño deliberado:
--   - property_data / search_data NO tienen tabla: son one-shot (ver Épica 2
--     y la sección "Restricciones y supuestos" del doc de requerimientos).
--   - El cupo mensual es un ledger de eventos (placa_events), no un contador
--     mutable: el período se calcula, nunca se "resetea".
--   - subscriptions y placa_events no tienen policy de insert/update para el
--     rol autenticado: solo service_role (el backend) puede escribirlas, así
--     el agente no puede inflar su propio cupo ni autopromoverse a pro.

create extension if not exists pgcrypto;

create type plan_tier  as enum ('free', 'pro');
create type sub_status as enum ('none', 'pending', 'authorized', 'paused', 'cancelled', 'courtesy');

-- ---------------------------------------------------------------------------
-- profiles: único dato persistente del agente (Historia 1.2)
-- ---------------------------------------------------------------------------
create table public.profiles (
  agent_id    uuid primary key references auth.users (id) on delete cascade,
  nombre      text not null default '',
  whatsapp    text not null default '',
  red_social  text,
  matricula   text,
  foto_path   text,                     -- ruta en Supabase Storage, no una URL
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy profiles_select_own on public.profiles
  for select using (auth.uid() = agent_id);

create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = agent_id);

create policy profiles_update_own on public.profiles
  for update using (auth.uid() = agent_id) with check (auth.uid() = agent_id);

-- sin policy de delete: el agente no borra su propio perfil desde el cliente.

create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- subscriptions: estado (tier, status) de Épica 3. Solo service_role escribe.
-- ---------------------------------------------------------------------------
create table public.subscriptions (
  agent_id             uuid primary key references auth.users (id) on delete cascade,
  tier                 plan_tier  not null default 'free',
  status               sub_status not null default 'none',
  mp_preapproval_id    text unique,
  current_period_end   timestamptz,     -- null en 'courtesy' == nunca expira
  courtesy_note        text,
  updated_at           timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

create policy subs_select_own on public.subscriptions
  for select using (auth.uid() = agent_id);

-- Deliberadamente SIN policy de insert/update/delete para el rol
-- 'authenticated': solo service_role (el backend) puede escribir esta tabla.

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- placa_events: ledger append-only de generación. Es la fuente de verdad del
-- cupo mensual (Historia 3.1) y de la idempotencia de /v1/placas/consume.
-- ---------------------------------------------------------------------------
create table public.placa_events (
  id                  uuid primary key default gen_random_uuid(),
  agent_id            uuid not null references auth.users (id) on delete cascade,
  client_request_id   uuid not null,
  template_id         text not null,
  kind                text not null check (kind in ('publicacion', 'busqueda')),
  formats             text[] not null,
  include_contact     boolean not null,
  created_at          timestamptz not null default now(),

  -- Un client_request_id repetido para el mismo agente es un reintento, no
  -- una nueva generación: nunca debe cobrar dos veces.
  unique (agent_id, client_request_id)
);

create index placa_events_agent_created_idx
  on public.placa_events (agent_id, created_at desc);

alter table public.placa_events enable row level security;

create policy events_select_own on public.placa_events
  for select using (auth.uid() = agent_id);

-- Deliberadamente SIN policy de insert: el cliente físicamente no puede
-- escribir, borrar ni retrofechar una fila de uso. Solo service_role inserta,
-- vía la función consume_placa_credit() más abajo.

-- ---------------------------------------------------------------------------
-- mp_webhook_events: deduplicación de entregas del webhook de Mercado Pago.
-- ---------------------------------------------------------------------------
create table public.mp_webhook_events (
  id            bigserial primary key,
  mp_event_id   text not null unique,
  topic         text not null,
  payload       jsonb not null,
  received_at   timestamptz not null default now(),
  processed_at  timestamptz
);

alter table public.mp_webhook_events enable row level security;
-- Sin policies: tabla accesible únicamente vía service_role.

-- ---------------------------------------------------------------------------
-- Alta automática de fila en profiles/subscriptions al registrarse.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (agent_id) values (new.id);
  insert into public.subscriptions (agent_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Helpers de período mensual, en huso horario de Argentina.
-- Argentina es UTC-3 sin DST desde 2009, pero se nombra la zona en vez de
-- hardcodear el offset para que quede correcto igual si eso cambiara.
-- ---------------------------------------------------------------------------
create or replace function public.current_period_start() returns timestamptz
language sql stable as $$
  select date_trunc('month', now() at time zone 'America/Argentina/Buenos_Aires')
         at time zone 'America/Argentina/Buenos_Aires';
$$;

-- ---------------------------------------------------------------------------
-- quota_status(): lectura directa del cliente Flutter vía rpc(). Aplica el
-- downgrade perezoso de pro -> free cuando venció current_period_end, sin
-- necesidad de un cron.
-- ---------------------------------------------------------------------------
create or replace function public.quota_status()
returns table (
  tier          plan_tier,
  status        sub_status,
  used          integer,
  quota_limit   integer,
  period_start  timestamptz,
  period_end    timestamptz
)
language sql stable security definer set search_path = public as $$
  select
    s.tier,
    s.status,
    (
      select count(*)::int from public.placa_events e
      where e.agent_id = auth.uid()
        and e.created_at >= public.current_period_start()
    ),
    case
      when s.tier = 'pro'
       and (s.current_period_end is null or s.current_period_end > now())
        then null   -- null == sin límite
      else 10
    end,
    public.current_period_start(),
    public.current_period_start() + interval '1 month'
  from public.subscriptions s
  where s.agent_id = auth.uid();
$$;

grant execute on function public.quota_status() to authenticated;

-- ---------------------------------------------------------------------------
-- consume_placa_credit(): único punto de escritura de placa_events. Se llama
-- exclusivamente desde el backend (service_role) vía /v1/placas/consume.
-- Serializa por agente con un advisory lock para que dos consumos
-- concurrentes del mismo agente no pasen juntos el límite de 10.
-- ---------------------------------------------------------------------------
create or replace function public.consume_placa_credit(
  p_agent           uuid,
  p_request         uuid,
  p_template        text,
  p_kind            text,
  p_formats         text[],
  p_include_contact boolean
)
returns table (
  granted      boolean,
  reason       text,
  used         integer,
  quota_limit  integer
)
language plpgsql security definer set search_path = public as $$
declare
  v_limit integer;
  v_used  integer;
begin
  -- Serializa por agente: dos consumos concurrentes del mismo agente no
  -- pueden leer el mismo "used" y pasar juntos el límite.
  perform pg_advisory_xact_lock(hashtextextended(p_agent::text, 0));

  -- v_limit se calcula siempre, antes de mirar si es un reintento: la rama
  -- 'replay' de abajo lo necesita para responder el límite real (BUG real
  -- encontrado en verificación local: antes devolvía null::integer fijo en
  -- el replay sin importar el tier, así que un doble-tap de un agente free
  -- veía "sin límite" hasta el próximo consumo no repetido).
  select case
           when tier = 'pro'
            and (current_period_end is null or current_period_end > now())
             then null
           else 10
         end
    into v_limit
  from public.subscriptions
  where agent_id = p_agent
  for update;

  if exists (
    select 1 from public.placa_events
    where agent_id = p_agent and client_request_id = p_request
  ) then
    -- Reintento idempotente: mismo request_id, no se cobra de nuevo.
    select count(*)::int into v_used
    from public.placa_events
    where agent_id = p_agent and created_at >= public.current_period_start();

    return query select true, 'replay'::text, v_used, v_limit;
    return;
  end if;

  select count(*)::int into v_used
  from public.placa_events
  where agent_id = p_agent and created_at >= public.current_period_start();

  if v_limit is not null and v_used >= v_limit then
    return query select false, 'quota_exceeded'::text, v_used, v_limit;
    return;
  end if;

  insert into public.placa_events (
    agent_id, client_request_id, template_id, kind, formats, include_contact
  ) values (
    p_agent, p_request, p_template, p_kind, p_formats, p_include_contact
  );

  return query select true, 'granted'::text, v_used + 1, v_limit;
end;
$$;

-- BUG real encontrado en verificación local (2026-08-25): "sin grant a
-- authenticated" NO alcanza para bloquear esta función. El proyecto de
-- Supabase configura (vía ALTER DEFAULT PRIVILEGES a nivel de rol postgres/
-- supabase_admin) que toda función NUEVA creada en el schema public recibe
-- EXECUTE automáticamente para anon, authenticated y service_role — no es
-- un grant a PUBLIC (revocar "from public" no alcanza; hay que revocar de
-- los roles concretos). Verificado con
-- has_function_privilege('authenticated', ..., 'execute') = true antes del
-- fix. Como esta función es security definer y confía en p_agent sin
-- validarlo contra auth.uid() (por diseño: el único llamante legítimo es el
-- backend, que ya verificó el JWT y pasa el agent_id correcto), dejar el
-- EXECUTE de authenticated/anon abierto permitía que cualquier usuario
-- autenticado (o incluso anon) consumiera o escribiera indebidamente
-- placa_events a nombre de OTRO agente con solo pasar su uuid como p_agent.
revoke execute on function public.consume_placa_credit(
  uuid, uuid, text, text, text[], boolean
) from public, anon, authenticated;

grant execute on function public.consume_placa_credit(
  uuid, uuid, text, text, text[], boolean
) to service_role;
