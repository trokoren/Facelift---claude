-- Her scans backed up to her account, so they follow her to a new iPhone.
-- Scores, consultations and recommendations only: never photos, never her health answers
-- (those stay on the phone). Each member can read and change only her own rows, and
-- everything is erased automatically when her account is deleted.

create table if not exists public.member_scans (
  user_id uuid not null references auth.users (id) on delete cascade,
  scan_id uuid not null,
  scanned_at timestamptz not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, scan_id)
);

create index if not exists member_scans_user_scanned on public.member_scans (user_id, scanned_at desc);

alter table public.member_scans enable row level security;

drop policy if exists "Members read their own scans" on public.member_scans;
create policy "Members read their own scans" on public.member_scans
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "Members add their own scans" on public.member_scans;
create policy "Members add their own scans" on public.member_scans
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "Members update their own scans" on public.member_scans;
create policy "Members update their own scans" on public.member_scans
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "Members delete their own scans" on public.member_scans;
create policy "Members delete their own scans" on public.member_scans
  for delete to authenticated using ((select auth.uid()) = user_id);

revoke all on public.member_scans from anon;
grant select, insert, update, delete on public.member_scans to authenticated;
