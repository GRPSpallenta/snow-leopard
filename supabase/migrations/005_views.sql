-- 005_views.sql
-- Safe views for public/consumer queries

-- Professional directory view (exclude sensitive ciphertext fields)
create or replace view public.professional_directory as
select
  p.id,
  p.first_name,
  p.last_name,
  p.role,
  p.email,               -- consider hiding or hashing if needed later
  p.phone,               -- consider masking if needed later
  p.country_code,
  p.locale,
  jsonb_build_object(
    'formatted', p.home_address->>'formatted',
    'lat', p.home_address->>'lat',
    'lng', p.home_address->>'lng'
  ) as home_location,
  p.rating_avg,
  p.rating_count,
  p.completed_jobs,
  p.completed_value
from public.profiles p
where p.role = 'professional';

-- Jobs open listing view
create or replace view public.open_jobs as
select
  j.id,
  j.service_id,
  j.description,
  j.budget,
  j.currency,
  j.service_type,
  j.desired_by,
  jsonb_build_object(
    'formatted', j.location->>'formatted',
    'lat', j.location->>'lat',
    'lng', j.location->>'lng'
  ) as location,
  j.status,
  j.created_at
from public.jobs j
where j.status = 'open';
