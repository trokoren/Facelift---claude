-- YouCam credit alerts (2026-10-12). The credit-alert edge function checks the YouCam
-- balance and emails trevor@faceliftai.app through Resend when it drops below 240 credits
-- (about 20 scans), at most once every 12 hours. ops_alerts records what was sent.
create extension if not exists pg_net;
create extension if not exists pg_cron;

create table if not exists public.ops_alerts (
  id bigint generated always as identity primary key,
  kind text not null,
  detail text,
  sent_at timestamptz not null default now()
);
alter table public.ops_alerts enable row level security;
-- No policies: only the service role (edge functions) can read or write.

-- Daily at 15:00 UTC (9am Denver in summer, 8am in winter). Uses the public anon key.
select cron.schedule(
  'youcam-credit-check',
  '0 15 * * *',
  $$ select net.http_post(
       url := 'https://mrpdyksjydzxujaniflu.supabase.co/functions/v1/credit-alert',
       body := '{}'::jsonb,
       headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer <anon key from Backend.swift>'),
       timeout_milliseconds := 20000) $$
);
