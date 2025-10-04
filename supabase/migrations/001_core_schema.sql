-- 001_core_schema.sql
-- Core tables, indexes, and base structures for the marketplace

-- Extensions
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- SCHEMA: Core
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  role text not null check (role in ('client','professional')),
  first_name text not null,
  last_name text not null,
  email text not null unique,
  phone text not null,
  country_code text,                           -- ISO-3166-1 alpha-2
  locale text,                                 -- e.g., en-ZA
  home_address jsonb not null,                  -- {formatted, lat, lng, components}
  work_address jsonb,                           -- {formatted, lat, lng, components}
  id_number_ct bytea,                           -- app-layer AES-256-GCM ciphertext
  bank_ct bytea,                                -- app-layer AES-256-GCM ciphertext
  rating_avg numeric default 0,
  rating_count int default 0,
  completed_jobs int default 0,
  completed_value numeric default 0,
  created_at timestamptz default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  category text not null
);

create table if not exists public.professional_services (
  id uuid primary key default gen_random_uuid(),
  pro_profile_id uuid not null references public.profiles(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete restrict,
  rate numeric,
  currency text default 'USD',
  unique (pro_profile_id, service_id)
);

create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  client_profile_id uuid not null references public.profiles(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete restrict,
  description text not null,
  images_meta jsonb default '[]'::jsonb,
  budget numeric,
  currency text not null default 'USD',
  service_type text not null check (service_type in ('fix','supply_fix')),
  desired_by date,
  location jsonb not null, -- {formatted, lat, lng}
  job_size text check (job_size in ('small','large')),
  status text not null default 'open' check (status in ('open','assigned','in_progress','paused','completed','cancelled')),
  created_at timestamptz default now()
);

create table if not exists public.job_images (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  storage_path text not null,                  -- path in storage bucket
  created_at timestamptz default now()
);

create table if not exists public.proposals (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  pro_profile_id uuid not null references public.profiles(id) on delete cascade,
  offer_price numeric not null,
  eta timestamptz,
  notes text,
  status text not null default 'submitted' check (status in ('submitted','withdrawn','accepted','rejected')),
  created_at timestamptz default now(),
  unique (job_id, pro_profile_id)
);

create table if not exists public.job_assignments (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references public.jobs(id) on delete cascade,
  pro_profile_id uuid not null references public.profiles(id) on delete cascade,
  accepted_proposal_id uuid not null references public.proposals(id) on delete restrict,
  accepted_at timestamptz default now()
);

create table if not exists public.workflow_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  type text not null check (type in ('start','pause','resume','finish','invoice','payment')),
  payload jsonb default '{}'::jsonb,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  client_approved boolean default false,
  pro_approved boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references public.jobs(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_profile_id uuid references public.profiles(id) on delete set null,
  body text,
  attachments jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

-- Milestones for large jobs (moved before invoices to satisfy FKs)
create table if not exists public.job_milestones (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  title text not null,
  description text,
  amount numeric not null,
  currency text not null,
  order_index int not null,
  status text not null default 'planned' check (status in ('planned','in_progress','submitted','approved','paid')),
  created_at timestamptz default now()
);
create index if not exists job_milestones_job_idx on public.job_milestones(job_id, order_index);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs(id) on delete cascade,
  pro_profile_id uuid not null references public.profiles(id) on delete cascade,
  milestone_id uuid references public.job_milestones(id) on delete set null,
  amount numeric not null,
  currency text not null default 'USD',
  status text not null default 'draft' check (status in ('draft','submitted','approved','paid','disputed')),
  line_items jsonb default '[]'::jsonb,
  created_at timestamptz default now(),
  constraint invoice_job_or_milestone check ((job_id is not null) or (milestone_id is not null))
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  provider text not null default 'stripe',
  provider_payment_intent text not null,
  status text not null check (status in ('requires_action','processing','succeeded','canceled')),
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.portfolios (
  id uuid primary key default gen_random_uuid(),
  pro_profile_id uuid not null unique references public.profiles(id) on delete cascade
);

create table if not exists public.portfolio_items (
  id uuid primary key default gen_random_uuid(),
  portfolio_id uuid not null references public.portfolios(id) on delete cascade,
  title text not null,
  description text,
  images jsonb default '[]'::jsonb,
  job_id uuid references public.jobs(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references public.jobs(id) on delete cascade,
  client_profile_id uuid not null references public.profiles(id) on delete cascade,
  pro_profile_id uuid not null references public.profiles(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz default now()
);

-- FX rates for reporting/conversions
create table if not exists public.fx_rates (
  id uuid primary key default gen_random_uuid(),
  base text not null,
  quote text not null,
  rate numeric not null,
  as_of date not null,
  unique (base, quote, as_of)
);

-- Countries metadata
create table if not exists public.countries (
  code text primary key,           -- ISO alpha-2
  name text not null,
  default_currency text not null,
  phone_country_code text
);

-- Notifications config
create table if not exists public.notification_types (
  key text primary key,
  description text,
  mandatory boolean default false
);

create table if not exists public.user_notification_prefs (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  type_key text not null references public.notification_types(key) on delete cascade,
  channel text not null check (channel in ('in_app','email','sms')),
  enabled boolean not null default true,
  unique (profile_id, type_key, channel)
);

-- Indexes for performance
create index if not exists profiles_role_idx on public.profiles(role);
create index if not exists jobs_status_created_idx on public.jobs(status, created_at);
create index if not exists proposals_job_status_idx on public.proposals(job_id, status);
create index if not exists professional_services_service_idx on public.professional_services(service_id);
create index if not exists reviews_pro_idx on public.reviews(pro_profile_id);

-- Note: For geo queries, consider PostGIS later. For now, JSON fields exist for lat/lng.
