-- Web purchases unlocked in the app automatically (2026-11-16, FAC-192).
--
-- web_purchases: every purchase made on the website (RevenueCat Web Billing), saved from
-- RevenueCat's webhook with the email she typed at checkout.
--
-- web_handoffs: when she taps "Get Facelift" on the website's thank-you page, web-handoff
-- notes her website customer id, her connection (IP) and iPhone's iOS version, then sends her
-- to the App Store. When the app first opens on that connection, web-handoff moves the
-- purchase onto the app (RevenueCat transfer), so she's unlocked with no extra step.
--
-- Signing in with Apple afterwards ties it to her account for good (RevenueCat carries an
-- unlocked phone's membership over at sign-in; claim-web-purchase also matches by email).
create table if not exists public.web_purchases (
  app_user_id text primary key,          -- RevenueCat customer the website created
  email text,                            -- lowercased checkout email
  product_id text,
  period_type text,
  environment text,
  claimed_by text,                       -- RevenueCat app user id it was moved to
  claimed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.web_purchases enable row level security;
-- No policies: only the service role (edge functions) can read or write.
create index if not exists web_purchases_email on public.web_purchases (email) where claimed_by is null;

create table if not exists public.web_handoffs (
  id bigint generated always as identity primary key,
  web_app_user_id text not null,
  ip text not null,
  ios_version text,                      -- e.g. "18.1", from the browser
  created_at timestamptz not null default now(),
  matched_at timestamptz,
  matched_to text
);
alter table public.web_handoffs enable row level security;
create index if not exists web_handoffs_recent on public.web_handoffs (ip, created_at desc) where matched_at is null;

-- Web trials saved before this table existed.
insert into public.web_purchases (app_user_id, email, product_id, period_type, environment, created_at)
select app_user_id, lower(email), product_id, 'TRIAL', environment, created_at
from public.web_trials
where app_user_id <> 'test_reminder_20261115'
on conflict (app_user_id) do nothing;
