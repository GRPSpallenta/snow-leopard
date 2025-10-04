# Supabase Setup

This folder contains SQL migrations to provision the database schema, RLS policies, storage buckets, and seed data for the marketplace platform.

## Contents

- `migrations/001_core_schema.sql` — Core tables and indexes
- `migrations/002_rls.sql` — Row Level Security (RLS) policies
- `migrations/003_storage.sql` — Storage buckets and storage RLS
- `migrations/004_seed.sql` — Seed data: services, countries, notification types

## Prerequisites

- Supabase project (hosted) and access to the SQL editor
- The following environment variables available for your backend/frontend runtime (do not commit real secrets):
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`

Create a local `.env` in your app projects (backend/frontend) and keep it out of version control.

## Apply Migrations (Recommended: SQL Editor)

1. Open your project in the Supabase dashboard.
2. Go to SQL → New Query.
3. Run each file in order:
   - `001_core_schema.sql`
   - `002_rls.sql`
   - `003_storage.sql`
   - `004_seed.sql`
4. Confirm tables appear under `public` schema and buckets under `Storage`.

## Alternative: Supabase CLI (remote execute)

If you prefer CLI-based execution, use the SQL editor approach above for hosted projects. The Supabase CLI primarily manages local dev instances or migrations via `db push` for local Docker. For hosted, the safest path is the SQL editor.

## Post-Setup Checklist

- Profiles: Confirm RLS allows users to read/update their own profile. We default to public-read for listing professionals, but the API should avoid exposing sensitive fields.
- Jobs: Pros can read `open` jobs; clients manage their own jobs.
- Proposals: Pros can create/maintain their proposals; clients can read proposals for their jobs.
- Workflow/Chat: Parties to a job can read/write workflow events and messages.
- Invoices/Payments: Visible to parties; payments are written by the backend using the service role.
- Storage:
  - Buckets: `job-images`, `portfolio-images`
  - Uploads allowed to authenticated users. Reads should use signed URLs from the server.
  - Note: If `owner`/`created_by` columns behave differently in your project version, adjust the storage delete policies accordingly in `003_storage.sql`.

## Seeding Notes

- Services: A broad catalog is inserted. You can add or disable items later.
- Countries: Initially seeds BW, ZA, ZW, NA, ZM with default currencies.
- Notification Types: Seeds the mandatory events as discussed.

## Next Steps

- Connect the backend API using `SUPABASE_SERVICE_ROLE_KEY` for privileged server operations.
- Use `SUPABASE_ANON_KEY` in the frontend for client-authenticated access.
- Create views or API serializers to ensure sensitive profile fields are never returned to clients.
- Consider PostGIS if you need advanced geospatial queries.
