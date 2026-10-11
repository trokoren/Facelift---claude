-- FACELIFT product catalog: the products recommended for each of the 7 measures, in three tiers.
-- Edit rows in the Supabase table editor to change products, prices or links; the app picks
-- up changes on its next launch. Only active rows are readable by the app.
create table if not exists public.product_catalog (
  id bigint generated always as identity primary key,
  concern text not null check (concern in ('wrinkle','dark_circle','age_spot','redness','texture','pore','moisture')),
  tier text not null check (tier in ('Budget','Balanced','Luxury')),
  rank int not null default 1,
  brand text not null,
  name text not null,
  price int not null,
  url text,
  image_name text,
  pregnancy_safe boolean not null default true,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

comment on column public.product_catalog.rank is 'Within a concern and tier, the lowest eligible rank is shown (rank 2+ are fallbacks, e.g. pregnancy-safe alternatives).';
comment on column public.product_catalog.url is 'Affiliate or product link. Empty = a shopping search for the product.';
comment on column public.product_catalog.pregnancy_safe is 'False for retinoids, hydroquinone-family and high-strength salicylic acid: hidden from members who are pregnant, trying to conceive or breastfeeding.';

alter table public.product_catalog enable row level security;

create policy "Anyone can read active products"
  on public.product_catalog for select
  to anon, authenticated
  using (active);
