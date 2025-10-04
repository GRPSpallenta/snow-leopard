-- 003_storage.sql
-- Create Supabase Storage buckets and baseline RLS policies

-- Buckets (private by default)
insert into storage.buckets (id, name, public) values
  ('job-images', 'job-images', false)
  on conflict (id) do nothing;

insert into storage.buckets (id, name, public) values
  ('portfolio-images', 'portfolio-images', false)
  on conflict (id) do nothing;

-- Enable RLS (already enabled by default on storage.objects)
-- Baseline policies: allow authenticated uploads; reads via signed URLs or service role

-- Allow authenticated users to upload to specific buckets
create policy storage_job_images_insert
on storage.objects for insert to authenticated
with check (bucket_id = 'job-images');

create policy storage_portfolio_images_insert
on storage.objects for insert to authenticated
with check (bucket_id = 'portfolio-images');

-- Optional: allow authenticated users to delete their own uploads (by owner)
-- Note: storage.objects has owner via created_by = auth.uid() only if using GoTrue JWT context
create policy storage_job_images_delete_own
on storage.objects for delete to authenticated
using (bucket_id = 'job-images' and owner = auth.uid());

create policy storage_portfolio_images_delete_own
on storage.objects for delete to authenticated
using (bucket_id = 'portfolio-images' and owner = auth.uid());

-- No broad select policy: reads should use signed URLs or service role
-- If you want authenticated reads (non-public), uncomment below but prefer signed URLs for access control
-- create policy storage_job_images_select_auth
-- on storage.objects for select to authenticated
-- using (bucket_id = 'job-images');
-- create policy storage_portfolio_images_select_auth
-- on storage.objects for select to authenticated
-- using (bucket_id = 'portfolio-images');
