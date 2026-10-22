-- Treatments (phase 2): the in-office treatments FACELIFT suggests she ask about, and the
-- waitlist of women who want to be matched with a provider.
--
-- public.treatments: edited in Supabase like product_catalog, no app update needed.
--   Anyone can read active rows. `concerns` uses the same keys as product_catalog.concern:
--   wrinkle, dark_circle, age_spot, redness, texture, pore, moisture.
--   Prices are rough typical US ranges in dollars, shown as "about $X to $Y <price_unit>".
--
-- public.treatment_interest: "Get matched with a top provider near you".
--   The app can only add rows; nobody can read them from the app (Trevor reads them in
--   Supabase). No photos, scores or health answers are stored here, only the treatment,
--   her city and age range. Rows are erased with her account when she's signed in.

create table if not exists public.treatments (
  slug text primary key,
  name text not null,
  short_name text,
  tagline text not null,
  concerns text[] not null,
  rank int not null default 100,
  description text,
  how_it_works text,
  price_low int,
  price_high int,
  price_unit text,
  sessions text,
  results_last text,
  downtime text,
  avoid_when_pregnant boolean not null default true,
  skin_tone_caution boolean not null default false,
  sensitive_caution boolean not null default false,
  min_age int,
  image_url text,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.treatments enable row level security;

drop policy if exists "Anyone reads active treatments" on public.treatments;
create policy "Anyone reads active treatments" on public.treatments
  for select to anon, authenticated using (active);

revoke all on public.treatments from anon, authenticated;
grant select on public.treatments to anon, authenticated;

create table if not exists public.treatment_interest (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null,
  user_id uuid references auth.users (id) on delete cascade default auth.uid(),
  treatment_slug text not null references public.treatments (slug) on update cascade,
  city text check (char_length(city) <= 120),
  region text check (char_length(region) <= 120),
  country text check (char_length(country) <= 60),
  age_range text check (char_length(age_range) <= 20),
  source text check (source in ('results', 'my_skin', 'shop', 'treatment_sheet')),
  created_at timestamptz not null default now(),
  unique (client_id, treatment_slug)
);

create index if not exists treatment_interest_city on public.treatment_interest (country, region, city);
create index if not exists treatment_interest_treatment on public.treatment_interest (treatment_slug, created_at desc);

alter table public.treatment_interest enable row level security;

drop policy if exists "App adds interest" on public.treatment_interest;
create policy "App adds interest" on public.treatment_interest
  for insert to anon, authenticated
  with check (user_id is null or user_id = (select auth.uid()));

revoke all on public.treatment_interest from anon, authenticated;
grant insert on public.treatment_interest to anon, authenticated;

-- Demand by city and treatment, for Trevor (not exposed to the app).
create or replace view public.treatment_demand
with (security_invoker = true) as
select country, region, city, treatment_slug,
       count(*) as women,
       max(created_at) as latest
from public.treatment_interest
group by country, region, city, treatment_slug
order by women desc;

revoke all on public.treatment_demand from anon, authenticated;

-- Starting list. Prices are rough typical US ranges; check before launch.
insert into public.treatments
  (slug, name, short_name, tagline, concerns, rank, description, how_it_works,
   price_low, price_high, price_unit, sessions, results_last, downtime,
   avoid_when_pregnant, skin_tone_caution, sensitive_caution, min_age)
values
  ('neurotoxin', 'Botox and similar injections', 'Botox',
   'Softens expression lines on the forehead, between the brows and around the eyes.',
   array['wrinkle'], 1,
   'A few small injections relax the muscles that crease the skin when you frown, squint or raise your brows. Lines soften and, over time, new ones are slower to set in. Brands include Botox, Dysport, Xeomin and Daxxify.',
   'A purified protein quiets the targeted muscle for a few months. Results appear over 3 to 14 days.',
   300, 800, 'per visit', 'One visit, repeated every 3 to 4 months', '3 to 4 months', 'None. Avoid lying down and hard exercise for a few hours.',
   true, false, false, 21),

  ('bbl', 'BBL (BroadBand Light)', 'BBL',
   'Clears sun spots and calms redness for a brighter, more even tone.',
   array['age_spot', 'redness'], 2,
   'Gentle pulses of light target brown spots and small visible vessels. Spots darken, then flake away over about a week, and redness fades over the series. Also known as photofacial or IPL.',
   'Light is absorbed by pigment and by the red in small vessels, which the body then clears.',
   300, 700, 'per session', 'Usually 3 sessions, a month apart, then once or twice a year', '1 year or more with daily sunscreen', 'About a week of darker spots that flake off. Mild redness for a day.',
   true, true, true, 25),

  ('microneedling', 'Microneedling', 'Microneedling',
   'Refines texture, pores and fine lines by prompting fresh collagen.',
   array['texture', 'pore', 'wrinkle'], 3,
   'Fine needles create tiny channels in the skin, which repairs itself with new collagen. Over a series, skin looks smoother and firmer, pores look smaller and acne marks soften. Often paired with radiofrequency (RF microneedling) for more lift.',
   'Controlled micro-injuries start the skin''s own repair and collagen building.',
   200, 700, 'per session', '3 to 6 sessions, about a month apart', 'Many months, with upkeep once or twice a year', '1 to 3 days of pinkness, like a mild sunburn.',
   true, false, true, 25),

  ('sofwave', 'Sofwave', 'Sofwave',
   'Lifts and tightens to smooth fine lines, with no needles.',
   array['wrinkle'], 4,
   'Ultrasound energy heats the layer of skin where collagen lives, without harming the surface. Over the next 3 months, skin looks firmer and lines look softer, especially along the brow, jaw and neck.',
   'Gentle heat beneath the surface starts new collagen.',
   1500, 3500, 'per treatment', 'Usually one treatment, repeated about once a year', 'About a year', 'Little to none. Some redness for a few hours.',
   true, false, false, 30),

  ('chemical_peel', 'Chemical peel', 'Peel',
   'Fades dark spots and smooths rough texture for a fresh, even glow.',
   array['age_spot', 'texture', 'pore'], 5,
   'A professional-strength acid lifts away dull surface cells. Light peels give a quick glow; medium peels go further on spots and texture. Your provider matches the strength to your skin.',
   'Acids loosen and shed the top layer, revealing newer, more even skin.',
   150, 600, 'per peel', 'A series of 3 to 6 light peels, or one medium peel', 'A few months, longer with sunscreen', 'None to a week of peeling, depending on strength.',
   true, true, true, 21),

  ('fractional_laser', 'Gentle fractional laser', 'Fractional laser',
   'Evens tone and refines texture and pores, like Moxi or Clear + Brilliant.',
   array['age_spot', 'texture', 'pore', 'wrinkle'], 6,
   'A gentle laser treats tiny columns of skin, leaving the rest intact to heal quickly. Over a few sessions, tone looks more even, texture smoother and pores finer. Popular options include Moxi and Clear + Brilliant.',
   'Tiny treated zones prompt renewal and new collagen while the skin between them speeds healing.',
   300, 1000, 'per session', '3 to 4 sessions, about a month apart', 'Many months, with yearly upkeep', '2 to 3 days of redness and a sandpaper feel.',
   true, true, true, 25),

  ('hydrafacial', 'HydraFacial', 'HydraFacial',
   'Deep cleans pores and floods skin with hydration, with no downtime.',
   array['moisture', 'pore'], 7,
   'A medical-grade facial that cleanses, gently exfoliates, clears pores with suction and infuses hydrating serums. Skin looks plump and clear right away, which makes it a favorite before events.',
   'Cleansing, gentle exfoliation and suction, followed by hydrating serums.',
   150, 300, 'per facial', 'Once a month for upkeep, or before an event', 'About a week to a month', 'None.',
   true, false, false, 18),

  ('sculptra', 'Sculptra', 'Sculptra',
   'Gradually restores lost fullness to soften lines and firm the skin.',
   array['wrinkle'], 8,
   'An injectable that helps the skin rebuild its own collagen over several months, for a natural-looking return of fullness in the cheeks and temples and firmer skin overall. Best in experienced hands.',
   'Poly-L-lactic acid prompts the body to build new collagen over time.',
   800, 1200, 'per vial', 'Usually 2 to 3 vials over a few visits', 'Up to 2 years', 'A few days of possible swelling or bruising.',
   true, false, false, 30),

  ('under_eye_filler', 'Under-eye filler', 'Under-eye filler',
   'Softens hollows that cast shadows and make dark circles look deeper.',
   array['dark_circle'], 9,
   'A small amount of soft filler smooths the hollow under the eye, so less shadow falls there and you look more rested. It helps shadows from hollowness, not color from pigment. This area needs a very experienced injector.',
   'A soft hyaluronic acid gel fills the hollow that creates the shadow.',
   600, 1200, 'per visit', 'One visit, sometimes a small touch-up', '9 to 18 months', 'A few days of possible swelling or bruising.',
   true, false, false, 25)
on conflict (slug) do nothing;
