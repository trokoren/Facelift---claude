-- Trial-ending reminder for website trials (2026-11-15). The web-trial-reminder edge
-- function saves each web free trial here from RevenueCat's webhook, and an hourly job emails
-- her through Resend about a day before the trial turns into a paid year.
create extension if not exists pg_net;
create extension if not exists pg_cron;

create table if not exists public.web_trials (
  app_user_id text primary key,
  email text,
  product_id text,
  environment text,
  trial_ends_at timestamptz not null,
  price numeric,
  currency text,
  status text not null default 'trial', -- trial, canceled, converted, expired
  reminded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.web_trials enable row level security;
-- No policies: only the service role (edge functions) can read or write.

create index if not exists web_trials_due on public.web_trials (trial_ends_at)
  where status = 'trial' and reminded_at is null;

-- Every hour at :05. Uses the public anon key (same as youcam-credit-check).
select cron.schedule(
  'web-trial-reminders',
  '5 * * * *',
  $$ select net.http_post(
       url := 'https://mrpdyksjydzxujaniflu.supabase.co/functions/v1/web-trial-reminder',
       body := '{"send": true}'::jsonb,
       headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer <anon key from Backend.swift>'),
       timeout_milliseconds := 20000) $$
);
