-- 002_rls.sql
-- Enable Row Level Security and define baseline policies

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.services enable row level security;
alter table public.professional_services enable row level security;
alter table public.jobs enable row level security;
alter table public.job_images enable row level security;
alter table public.proposals enable row level security;
alter table public.job_assignments enable row level security;
alter table public.workflow_events enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.invoices enable row level security;
alter table public.payments enable row level security;
alter table public.portfolios enable row level security;
alter table public.portfolio_items enable row level security;
alter table public.reviews enable row level security;
alter table public.job_milestones enable row level security;
alter table public.fx_rates enable row level security;
alter table public.countries enable row level security;
alter table public.notification_types enable row level security;
alter table public.user_notification_prefs enable row level security;

-- Public can read professional directory (limited fields responsibility handled by API/view). For now allow read; app should avoid exposing sensitive fields.
create policy profiles_read_public on public.profiles
for select using (true);

-- Owners can read/update themselves
create policy profiles_read_own on public.profiles
for select using (user_id = auth.uid());

create policy profiles_update_own on public.profiles
for update using (user_id = auth.uid());

create policy profiles_insert_self on public.profiles
for insert with check (user_id = auth.uid());

-- SERVICES are readable by all; writable by service role only (no RLS policy for writes)
create policy services_read_all on public.services
for select using (true);

-- PROFESSIONAL_SERVICES
create policy pro_services_read_all on public.professional_services
for select using (true);

create policy pro_services_insert_own on public.professional_services
for insert with check (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy pro_services_update_own on public.professional_services
for update using (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy pro_services_delete_own on public.professional_services
for delete using (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

-- JOBS
-- Clients can read/write their own jobs
create policy jobs_client_select_own on public.jobs
for select using (client_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy jobs_client_insert_own on public.jobs
for insert with check (client_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy jobs_client_update_own on public.jobs
for update using (client_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy jobs_client_delete_own on public.jobs
for delete using (client_profile_id in (select id from public.profiles where user_id = auth.uid()));

-- Professionals can read open jobs
create policy jobs_pros_read_open on public.jobs
for select using (status = 'open');

-- JOB_IMAGES: visible to job owner and assigned pro
create policy job_images_read on public.job_images
for select using (
  job_id in (
    select j.id from public.jobs j
    left join public.job_assignments a on a.job_id = j.id
    where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
       or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

create policy job_images_write_owner on public.job_images
for insert with check (
  job_id in (
    select id from public.jobs where client_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

-- PROPOSALS
-- Professionals can write their own proposals
create policy proposals_insert_own on public.proposals
for insert with check (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy proposals_update_own on public.proposals
for update using (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy proposals_delete_own on public.proposals
for delete using (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

-- Clients can read proposals for their jobs
create policy proposals_read_client_jobs on public.proposals
for select using (
  job_id in (
    select id from public.jobs where client_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

-- Professionals can read their own proposals
create policy proposals_read_own on public.proposals
for select using (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

-- JOB_ASSIGNMENTS: readable by job client and assigned pro
create policy assignment_read on public.job_assignments
for select using (
  pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  or job_id in (select id from public.jobs where client_profile_id in (select id from public.profiles where user_id = auth.uid()))
);

-- WORKFLOW_EVENTS: readable by job client and assigned pro; inserts by either party
create policy workflow_read on public.workflow_events
for select using (
  job_id in (
    select j.id from public.jobs j
    left join public.job_assignments a on a.job_id = j.id
    where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
       or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

create policy workflow_write_parties on public.workflow_events
for insert with check (
  job_id in (
    select j.id from public.jobs j
    left join public.job_assignments a on a.job_id = j.id
    where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
       or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

-- CHATS & MESSAGES
create policy chats_read_parties on public.chats
for select using (
  job_id in (
    select j.id from public.jobs j
    left join public.job_assignments a on a.job_id = j.id
    where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
       or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

create policy messages_read_parties on public.messages
for select using (
  chat_id in (
    select id from public.chats where job_id in (
      select j.id from public.jobs j
      left join public.job_assignments a on a.job_id = j.id
      where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
         or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
    )
  )
);

create policy messages_write_sender on public.messages
for insert with check (
  sender_profile_id in (select id from public.profiles where user_id = auth.uid())
);

-- INVOICES & PAYMENTS
create policy invoices_read_parties on public.invoices
for select using (
  (job_id is not null and job_id in (
    select j.id from public.jobs j
    left join public.job_assignments a on a.job_id = j.id
    where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
       or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )) or
  (milestone_id is not null and milestone_id in (select id from public.job_milestones where job_id in (
    select j.id from public.jobs j
    left join public.job_assignments a on a.job_id = j.id
    where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
       or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )))
);

-- payments visible to invoice parties
create policy payments_read_parties on public.payments
for select using (
  invoice_id in (select id from public.invoices)
);

-- PORTFOLIOS & ITEMS
create policy portfolios_read_all on public.portfolios for select using (true);
create policy portfolio_items_read_all on public.portfolio_items for select using (true);

create policy portfolios_insert_own on public.portfolios
for insert with check (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy portfolios_update_own on public.portfolios
for update using (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy portfolios_delete_own on public.portfolios
for delete using (pro_profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy portfolio_items_insert_own on public.portfolio_items
for insert with check (
  portfolio_id in (
    select id from public.portfolios where pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

create policy portfolio_items_update_own on public.portfolio_items
for update using (
  portfolio_id in (
    select id from public.portfolios where pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

create policy portfolio_items_delete_own on public.portfolio_items
for delete using (
  portfolio_id in (
    select id from public.portfolios where pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

-- REVIEWS: readable to all; insert by client on their job once completed
create policy reviews_read_all on public.reviews for select using (true);

create policy reviews_insert_client on public.reviews
for insert with check (
  client_profile_id in (select id from public.profiles where user_id = auth.uid())
);

-- JOB_MILESTONES: parties can read; client writes
create policy milestones_read_parties on public.job_milestones
for select using (
  job_id in (
    select j.id from public.jobs j
    left join public.job_assignments a on a.job_id = j.id
    where j.client_profile_id in (select id from public.profiles where user_id = auth.uid())
       or a.pro_profile_id in (select id from public.profiles where user_id = auth.uid())
  )
);

create policy milestones_insert_client on public.job_milestones
for insert with check (
  job_id in (select id from public.jobs where client_profile_id in (select id from public.profiles where user_id = auth.uid()))
);

create policy milestones_update_client on public.job_milestones
for update using (
  job_id in (select id from public.jobs where client_profile_id in (select id from public.profiles where user_id = auth.uid()))
);

create policy milestones_delete_client on public.job_milestones
for delete using (
  job_id in (select id from public.jobs where client_profile_id in (select id from public.profiles where user_id = auth.uid()))
);

-- FX_RATES & COUNTRIES & NOTIFICATION_TYPES
create policy fx_rates_read_all on public.fx_rates for select using (true);
create policy countries_read_all on public.countries for select using (true);
create policy notification_types_read_all on public.notification_types for select using (true);

-- USER_NOTIFICATION_PREFS: owner only
create policy notif_prefs_read_owner on public.user_notification_prefs
for select using (profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy notif_prefs_insert_owner on public.user_notification_prefs
for insert with check (profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy notif_prefs_update_owner on public.user_notification_prefs
for update using (profile_id in (select id from public.profiles where user_id = auth.uid()));

create policy notif_prefs_delete_owner on public.user_notification_prefs
for delete using (profile_id in (select id from public.profiles where user_id = auth.uid()));
