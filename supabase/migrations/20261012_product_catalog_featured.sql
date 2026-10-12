-- Shop tab features: "Dermatologist Recommends" (each pick sourced to a named, board-certified
-- dermatologist in a published article) and "Natural Favorites" (chosen by FACELIFT, no expert
-- claim). A product can sit under several concerns; every row for it carries the same feature.
-- Sources checked 2026-10-12.

alter table public.product_catalog
  add column if not exists featured text check (featured in ('dermatologist','natural')),
  add column if not exists featured_rank int,
  add column if not exists expert_name text,
  add column if not exists expert_title text,
  add column if not exists source_name text,
  add column if not exists source_url text;
comment on column public.product_catalog.featured is 'dermatologist = Dermatologist Recommends (needs expert_name and source_url); natural = Natural Favorites (FACELIFT picks).';

update public.product_catalog p set
  featured = 'dermatologist', featured_rank = v.r, expert_name = v.expert, expert_title = v.title,
  source_name = v.outlet, source_url = v.url
from (values
  (1, 'SkinCeuticals', 'C E Ferulic', 'Dr. Jennifer Segal, MD', 'Dermatologist', 'NewBeauty', 'https://www.newbeauty.com/best-skinceuticals-products-according-to-derms'),
  (2, 'La Roche-Posay', 'Cicaplast Balm B5+', 'Dr. Daniel Sugai, MD', 'Board-certified dermatologist', 'Refinery29', 'https://www.refinery29.com/en-us/best-la-roche-posay-skincare-products'),
  (3, 'The Ordinary', 'Niacinamide 10% + Zinc 1%', 'Dr. Whitney Hovenic', 'Board-certified dermatologist', 'Forbes', 'https://www.forbes.com/sites/forbes-personal-shopper/article/best-niacinamide-serum/'),
  (4, 'La Roche-Posay', 'Hyalu B5 Pure Hyaluronic Acid Serum', 'Dr. Valerie Callender, MD', 'Board-certified dermatologist', 'Refinery29', 'https://www.refinery29.com/en-us/best-la-roche-posay-skincare-products'),
  (5, 'CeraVe', 'Eye Repair Cream', 'Dr. Heather Woolery-Lloyd', 'Board-certified dermatologist', 'NBC Select', 'https://www.nbcnews.com/select/amp/rcna251683'),
  (6, 'La Roche-Posay', 'Toleriane Double Repair Face Moisturizer', 'Dr. Hilary Baldwin, MD', 'Board-certified dermatologist', 'Refinery29', 'https://www.refinery29.com/en-us/best-la-roche-posay-skincare-products'),
  (7, 'Paula''s Choice', '10% Niacinamide Booster', 'Dr. Whitney Hovenic', 'Board-certified dermatologist', 'Forbes', 'https://www.forbes.com/sites/forbes-personal-shopper/article/best-niacinamide-serum/')
) as v(r, brand, name, expert, title, outlet, url)
where p.brand = v.brand and p.name = v.name;

update public.product_catalog p set featured = 'natural', featured_rank = v.r
from (values
  (1, 'The INKEY List', 'Bakuchiol Retinol Alternative Moisturizer'),
  (2, 'Purito', 'Wonder Releaf Centella Cream Unscented'),
  (3, 'Pai Skincare', 'Stabilized Vitamin C 20% Brightening Booster'),
  (4, 'The Ordinary', '100% Organic Cold-Pressed Rose Hip Seed Oil'),
  (5, 'Three Ships', 'First Light Vitamin C + Caffeine Eye Cream'),
  (6, 'RMS Beauty', 'Kakadu Luxe Cream'),
  (7, 'Pai Skincare', 'Bright Now PHA & Rosehip Exfoliating Toner'),
  (8, 'Thayers', 'Alcohol-Free Unscented Witch Hazel Toner')
) as v(r, brand, name)
where p.brand = v.brand and p.name = v.name;
