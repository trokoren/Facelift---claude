-- Skincare approach: Clinical to Natural.
-- approach: clinical (proven actives), natural (plant-based, evidence-backed botanicals), or both.
-- essential_oils: contains essential oils or fragrant botanicals. Hidden from sensitive and very
-- sensitive skin and from members who are pregnant, trying to conceive or breastfeeding; everyone
-- else sees a patch-test note.
-- The natural products below were added inactive; they are switched on when the app version that
-- understands the approach setting ships (see CLAUDE.md).
-- Prices and links verified 2026-10-11. Empty url = a shopping search for the product.

alter table public.product_catalog
  add column if not exists approach text not null default 'clinical' check (approach in ('clinical','natural','both')),
  add column if not exists essential_oils boolean not null default false;
comment on column public.product_catalog.approach is 'clinical, natural or both. Matched to her Skincare approach setting (Clinical, Leaning clinical, Balanced, Leaning natural, Natural).';
comment on column public.product_catalog.essential_oils is 'Contains essential oils or fragrant botanicals: hidden for sensitive skin and pregnancy; others see a patch-test note.';

-- Existing products that are botanical-led as well as clinical.
update public.product_catalog set approach = 'both'
where (brand, name) in (
  ('Kiehl''s', 'Creamy Eye Treatment with Avocado'),
  ('Tatcha', 'The Rice Polish Foaming Enzyme Powder'),
  ('Tatcha', 'The Dewy Skin Cream'),
  ('Tatcha', 'The Water Cream'),
  ('SkinCeuticals', 'Phyto Corrective Gel'),
  ('Dr. Jart+', 'Cicapair Soothing Color Correcting Treatment SPF 30')
);

insert into public.product_catalog
  (concern, tier, rank, brand, name, price, url, image_name, pregnancy_safe, strength, skin_types, approach, essential_oils, active)
values
  -- Fine lines and wrinkles
  ('wrinkle', 'Budget', 10, 'The INKEY List', 'Bakuchiol Retinol Alternative Moisturizer', 15, NULL, 'skincare_box_jar', true, 'gentle', NULL, 'natural', false, false),
  ('wrinkle', 'Budget', 11, 'The Ordinary', '100% Organic Cold-Pressed Rose Hip Seed Oil', 11, 'https://www.sephora.com/product/the-ordinary-deciem-100-organic-cold-pressed-rose-hip-seed-oil-P427415', 'serum_bottle_dropper', true, 'gentle', ARRAY['dry','normal','combination'], 'natural', false, false),
  ('wrinkle', 'Balanced', 10, 'Herbivore', 'Bakuchiol Dual-Retinol Alternative Face Serum', 68, 'https://www.herbivorebotanicals.com/products/bakuchiol-dual-retinol-alternative-serum-1', 'skincare_jar_serum_dropper', true, 'gentle', NULL, 'natural', true, false),
  ('wrinkle', 'Luxury', 10, 'Tata Harper', 'Retinoic Nutrient Face Oil', 132, 'https://tataharperskincare.com/products/retinoic-nutrient-face-oil', 'skincare_bottles_gold', false, 'gentle', ARRAY['dry','normal','combination'], 'natural', true, false),
  -- Dark spots
  ('age_spot', 'Budget', 10, 'Beauty of Joseon', 'Glow Serum: Propolis + Niacinamide', 17, 'https://www.walmart.com/ip/429051079', 'serum_bottle_dropper', false, 'regular', NULL, 'natural', true, false),
  ('age_spot', 'Balanced', 10, 'Pai Skincare', 'Stabilized Vitamin C 20% Brightening Booster', 34, 'https://credobeauty.com/products/stabilized-vitamin-c-20-brightening-booster', 'serum_bottle_dropper', true, 'gentle', NULL, 'natural', false, false),
  ('age_spot', 'Balanced', 11, 'Follain', 'Brightening Serum', 40, 'https://credobeauty.com/products/follain-brightening-serum', 'skincare_jar_serum_dropper', true, 'regular', NULL, 'natural', true, false),
  ('age_spot', 'Luxury', 10, 'Ursa Major', 'Brighten Up Vitamin C Serum', 56, 'https://credobeauty.com/products/ursa-major-brighten-up-vitamin-c-serum', 'skincare_jar_serum_dropper', true, 'regular', NULL, 'natural', true, false),
  ('age_spot', 'Luxury', 11, 'Odacité', 'Vitamin C & E + Hyaluronic Acid Brightening Serum', 78, 'https://credobeauty.com/products/vitamin-c-e-hyaluronic-acid-renewing-serum', 'skincare_bottles_gold', true, 'regular', NULL, 'natural', true, false),
  -- Dark circles
  ('dark_circle', 'Budget', 10, 'Three Ships', 'First Light Vitamin C + Caffeine Eye Cream', 32, 'https://credobeauty.com/products/first-light-vitamin-c-caffeine-eye-cream', 'eye_cream_jar_gold_lid', true, 'gentle', NULL, 'natural', false, false),
  ('dark_circle', 'Balanced', 10, 'Herbivore', 'Moon Dew 1% Bakuchiol + Peptides Eye Cream', 48, 'https://www.herbivorebotanicals.com/products/moon-dew-1-bakuchiol-peptides-retinol-alternative-eye-cream-1', 'eye_cream_jar_gold_lid', true, 'gentle', NULL, 'natural', true, false),
  ('dark_circle', 'Balanced', 11, 'OSEA', 'Advanced Repair Eye Cream', 68, 'https://www.ulta.com/p/p-pimprod2038423', 'eye_cream_jar_gold_lid', true, 'gentle', NULL, 'natural', false, false),
  ('dark_circle', 'Luxury', 10, 'Tata Harper', 'Brightening Eye Gel', 76, 'https://credobeauty.com/products/brightening-eye-gel', 'eye_cream_jar_gold_lid', true, 'gentle', NULL, 'natural', true, false),
  -- Hydration
  ('moisture', 'Budget', 10, 'The Ordinary', '100% Plant-Derived Squalane', 10, NULL, 'serum_bottle_dropper', true, 'gentle', NULL, 'natural', false, false),
  ('moisture', 'Budget', 11, 'Weleda', 'Skin Food Original Ultra-Rich Cream', 14, 'https://www.walmart.com/ip/Weleda-Skin-Food-Original-Ultra-Rich-Cream-2-5-oz-75-g/28775218', 'skincare_tube_box', true, 'regular', ARRAY['dry','normal'], 'natural', true, false),
  ('moisture', 'Balanced', 10, 'Follain', 'Moisturizer', 36, 'https://credobeauty.com/products/follain-moisturizer', 'skincare_box_jar', true, 'gentle', NULL, 'natural', false, false),
  ('moisture', 'Luxury', 10, 'RMS Beauty', 'Kakadu Luxe Cream', 60, 'https://bluemercury.com/products/rms-beauty-kakadu-luxe-cream', 'skincare_box_jar', true, 'gentle', NULL, 'natural', false, false),
  ('moisture', 'Luxury', 11, 'Tata Harper', 'Water-Lock Moisturizer', 74, 'https://www.nordstrom.com/s/water-lock-moisturizer/5707494', 'skincare_box_jar', true, 'gentle', NULL, 'natural', true, false),
  -- Redness
  ('redness', 'Budget', 10, 'Purito', 'Wonder Releaf Centella Cream Unscented', 21, 'https://thebaerry.com/en-us/products/wonder-releaf-centella-cream-unscented-50ml', 'skincare_box_jar', true, 'gentle', NULL, 'natural', false, false),
  ('redness', 'Budget', 11, 'Beauty of Joseon', 'Calming Serum: Green Tea + Panthenol', 14, 'https://www.vitacost.com/products/beauty-of-joseon-calming-serum-green-tea-panthenol-1-01-fl-oz-30-ml-116211', 'serum_bottle_dropper', true, 'gentle', NULL, 'natural', false, false),
  ('redness', 'Balanced', 10, 'Pai Skincare', 'Chamomile & Rosehip Calming Day Cream', 69, NULL, 'skincare_box_jar', true, 'gentle', NULL, 'natural', true, false),
  ('redness', 'Luxury', 10, 'Cosmetics 27', 'Recovery 27 Bio-Soothing Restoring Serum', 125, 'https://credobeauty.com/products/recovery-27-bio-soothing-restoring-serum', 'skincare_bottles_gold', true, 'gentle', NULL, 'natural', false, false),
  ('redness', 'Luxury', 11, 'Tata Harper', 'Superkind Calming Crème', 168, 'https://www.sephora.com/product/tata-harper-calming-creme-for-redness-and-skin-repair-P512283', 'skincare_box_jar', true, 'gentle', NULL, 'natural', false, false),
  -- Pores
  ('pore', 'Budget', 10, 'Thayers', 'Alcohol-Free Unscented Witch Hazel Toner', 8, 'https://www.walmart.com/ip/seort/673336960', 'skincare_products_shower', true, 'gentle', NULL, 'natural', false, false),
  ('pore', 'Budget', 11, 'Ursa Major', 'Fantastic Face Wash', 15, 'https://credobeauty.com/products/ursa-major-fantastic-face-wash', 'skincare_products_shower', true, 'regular', NULL, 'natural', true, false),
  ('pore', 'Balanced', 10, 'Lona Beauty', 'Desert Dust Active Clay Cleansing + Brightening Exfoliator', 42, 'https://credobeauty.com/products/desert-dust-active-clay-cleansing-brightening-exfoliator', 'skincare_jar_stone_branch', true, 'regular', NULL, 'natural', false, false),
  ('pore', 'Luxury', 10, 'Tata Harper', 'Resurfacing Mask', 88, 'https://credobeauty.com/collections/tata-harper/products/tata-harper-resurfacing-mask', 'skincare_jar_stone_branch', true, 'regular', NULL, 'natural', true, false),
  -- Texture
  ('texture', 'Budget', 10, 'Ursa Major', 'Essential Face Tonic', 26, 'https://credobeauty.com/products/4-in-1-essential-tonic', 'skincare_products_shower', true, 'regular', NULL, 'natural', true, false),
  ('texture', 'Balanced', 10, 'Pai Skincare', 'Bright Now PHA & Rosehip Exfoliating Toner', 49, 'https://credobeauty.com/products/bright-now-pha-rosehip-exfoliating-toner', 'skincare_products_shower', true, 'gentle', NULL, 'natural', false, false),
  ('texture', 'Balanced', 11, 'Lona Beauty', 'Desert Dust Active Clay Cleansing + Brightening Exfoliator', 42, 'https://credobeauty.com/products/desert-dust-active-clay-cleansing-brightening-exfoliator', 'skincare_jar_stone_branch', true, 'regular', NULL, 'natural', false, false),
  ('texture', 'Luxury', 10, 'Tata Harper', 'Resurfacing Mask', 88, 'https://credobeauty.com/collections/tata-harper/products/tata-harper-resurfacing-mask', 'skincare_jar_stone_branch', true, 'regular', NULL, 'natural', true, false);
