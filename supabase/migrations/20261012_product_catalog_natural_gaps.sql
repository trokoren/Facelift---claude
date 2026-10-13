-- Natural picks without essential oils, to fill the slots that came up empty for
-- sensitive skin or redness in Natural mode (2026-10-12). Prices, links and ingredient
-- lists checked on the retailer or brand page; every one lists no fragrance or essential oils.
-- Also: SkinCeuticals Phyto Corrective Gel moved to clinical only, with a Dermstore photo.

update public.product_catalog
set approach = 'clinical',
    image_url = 'https://static.thcdn.com/productimg/original/11289623-1055302037225421.jpg'
where brand = 'SkinCeuticals' and name = 'Phyto Corrective Gel';

insert into public.product_catalog
  (concern, tier, rank, brand, name, price, url, image_name, pregnancy_safe, strength, approach, essential_oils,
   description, key_ingredients, how_to_use, size, image_url, active)
select v.concern, v.tier,
       (select coalesce(max(p.rank), 0) from public.product_catalog p where p.concern = v.concern and p.tier = v.tier) + v.off,
       v.brand, v.name, v.price, v.url, v.image_name, v.pregnancy_safe, v.strength, v.approach, false,
       v.description, v.key_ingredients, v.how_to_use, v.size, v.image_url, true
from (values
  ('dark_circle', 'Luxury', 1, 'Biossance', 'Squalane + Marine Algae Eye Cream', 56,
   'https://www.sephora.com/product/P447210', 'eye_cream_jar_gold_lid', true, 'gentle', 'natural',
   'A soft, cushiony eye cream built on sugarcane squalane and pink marine algae. It smooths and plumps the delicate skin under the eyes so shadows and fine lines read softer, and it is fragrance free.',
   array['Squalane', 'Pink marine algae', 'Paracress extract', 'Peptides'],
   'Morning and night after cleansing, tap a small amount around the whole eye area with your ring finger, sweeping out toward the temple.',
   '0.5 oz / 15 mL',
   'https://www.sephora.com/productimages/sku/s2260016-main-zoom.jpg?imwidth=600'),

  ('age_spot', 'Luxury', 1, 'Marie Veronique', 'Vitamins C+E+Ferulic Serum', 120,
   'https://credobeauty.com/products/vitamin-c-e-ferulic-acid-serum', 'serum_bottle_dropper', true, 'regular', 'natural',
   'A clean take on the classic vitamin C, E and ferulic trio, set in green tea and botanical antioxidants. It brightens uneven tone and fades the look of dark spots over steady use, without fragrance or essential oils.',
   array['Vitamin C', 'Vitamin E', 'Ferulic acid', 'Green tea'],
   'Shake well, then press one to two pumps onto face, neck and chest, morning and night. Follow with SPF in the morning.',
   '1 oz / 30 mL',
   'https://credobeauty.com/cdn/shop/files/MarieVeronique_VitaminsCEFerulicSerum_01_609b1a08-f89f-47e4-a45d-4d7875600fad.png?v=1773274541'),

  ('age_spot', 'Balanced', 1, 'Biossance', 'Squalane + 10% Vitamin C Dark Spot Serum', 68,
   'https://www.sephora.com/product/P467110', 'serum_bottle_dropper', true, 'regular', 'natural',
   'A fragrance-free vitamin C serum paired with white shiitake and licorice root to fade the look of dark spots, with squalane to keep skin comfortable. A good daily brightener for skin that does not like strong scents.',
   array['Vitamin C (10%)', 'White shiitake mushroom', 'Licorice root', 'Squalane'],
   'Massage two to three pumps onto clean face and neck, morning and night, before moisturizer. Finish with SPF in the morning.',
   '1 oz / 30 mL',
   'https://www.sephora.com/productimages/sku/s2404655-main-zoom.jpg?imwidth=600'),

  ('age_spot', 'Budget', 1, 'Beauty of Joseon', 'Glow Deep Serum: Rice + Alpha-Arbutin', 17,
   'https://www.walmart.com/ip/seort/1612488532', 'serum_bottle_dropper', false, 'gentle', 'both',
   'A light, watery serum made with rice bran water, alpha-arbutin and niacinamide to even out tone and soften the look of spots. Fragrance free and gentle enough for daily use.',
   array['Rice bran water', 'Alpha-arbutin', 'Niacinamide'],
   'After toner, press a few drops into the skin morning or night. Use SPF during the day.',
   '1 oz / 30 mL',
   'https://i5.walmartimages.com/seo/Beauty-of-Joseon-Glow-Deep-Serum-Rice-Alpha-Arbutin_14d4ac02-5100-400b-b5fd-e62f73d2a2ac.f6d547d2c371f5ad15e293959e55b031.jpeg'),

  ('wrinkle', 'Balanced', 1, 'Medik8', 'Bakuchiol Peptides', 58,
   'https://www.sephora.com/product/bakuchiol-peptides-serum-P525907', 'serum_bottle_dropper', true, 'gentle', 'natural',
   'A plant-based retinol alternative: bakuchiol in a nourishing oil blend with centella. It softens the look of fine lines and evens tone without the dryness retinol can bring, and it can be used morning and night.',
   array['Bakuchiol (1.25%)', 'Centella asiatica', 'Moringa oil'],
   'After cleansing, morning and evening, massage about six drops across face, neck and chest.',
   '1 oz / 30 mL',
   'https://www.sephora.com/productimages/sku/s3011251-main-zoom.jpg?imwidth=600'),

  ('wrinkle', 'Luxury', 1, 'Biossance', 'Squalane + Growth Factor Firming Moisturizer', 64,
   'https://www.sephora.com/product/biossance-growth-factor-firming-anti-aging-moisturizer-with-peptides-collagen-squalane-P519872', 'skincare_box_jar', true, 'gentle', 'natural',
   'A rich, comforting moisturizer with plant-derived peptides, vegan collagen and squalane. It helps skin look firmer and smoother over time, with no fragrance in the formula.',
   array['Plant-based growth factor', 'Peptides', 'Vegan collagen', 'Squalane'],
   'Smooth over face and neck after serums, morning and night. Follow with SPF in the morning.',
   '1.69 oz / 50 mL',
   'https://www.sephora.com/productimages/sku/s2935583-main-zoom.jpg?imwidth=600'),

  ('redness', 'Balanced', 1, 'KraveBeauty', 'Great Barrier Relief', 29,
   'https://kravebeauty.com/collections/shop-all/products/great-barrier-relief', 'serum_bottle_dropper', true, 'gentle', 'natural',
   'A barrier-repair serum with tamanu oil, ceramides and niacinamide that calms flushed, reactive skin. It is free of essential oils and fragrance, and has a faint natural scent from the oils.',
   array['Tamanu oil (10%)', 'Ceramides', 'Niacinamide (2%)'],
   'Apply one to two pumps to clean, dry skin and massage until absorbed. On sensitive spots, pat on lightly.',
   '1.52 oz / 45 mL',
   'https://kravebeauty.com/cdn/shop/files/GBR01.png?v=1781703707'),

  ('redness', 'Balanced', 2, 'Biossance', 'Squalane + Omega Repair Deep Hydration Moisturizer', 60,
   'https://www.sephora.com/product/squalane-omega-repair-cream-P433887', 'skincare_box_jar', true, 'gentle', 'natural',
   'A fragrance-free cream with ceramides, omega fatty acids and squalane that rebuilds a stressed barrier. Ideal when redness comes with dryness or tightness.',
   array['Ceramides', 'Omega fatty acids', 'Squalane', 'Hyaluronic acid'],
   'Apply to clean face and neck after serums, morning and night.',
   '1.69 oz / 50 mL',
   'https://www.sephora.com/productimages/sku/s2105856-main-zoom.jpg?imwidth=600'),

  ('redness', 'Budget', 1, 'Purito', 'Wonder Releaf Centella Serum Unscented', 22,
   'https://www.vitacost.com/products/purito-wonder-releaf-centella-serum-unscented-2-02-fl-oz-60-ml-102177', 'serum_bottle_dropper', true, 'gentle', 'both',
   'An unscented centella serum with niacinamide, panthenol and peptides that soothes redness and supports a calmer barrier. Simple and kind to sensitive skin.',
   array['Centella asiatica', 'Niacinamide', 'Panthenol', 'Peptides'],
   'After toner, pat a few drops into the skin morning and night, then follow with moisturizer.',
   '2.02 oz / 60 mL',
   'https://www.vitacost.com/cdn/shop/files/61_bc23bd32-dc7f-4f58-8636-fa8e9f427a07.jpg?v=1781986673'),

  ('texture', 'Budget', 1, 'Good Molecules', 'Pineapple Exfoliating Powder', 16,
   'https://www.ulta.com/p/p-pimprod2023934', 'skincare_box_jar', true, 'gentle', 'both',
   'A rice-based powder that turns into a soft paste with water. Papaya and pineapple enzymes lift dull, rough skin without scrubbing grit or acids, so it suits skin that finds acids too much.',
   array['Papain (papaya enzyme)', 'Pineapple extract', 'Rice powder'],
   'Mix about a teaspoon with a few drops of water into a paste, massage gently over damp skin, then rinse. Use up to three or four times a week.',
   '2.1 oz',
   'https://media.ulta.com/i/ulta/2582313?w=600&h=600')
) as v(concern, tier, off, brand, name, price, url, image_name, pregnancy_safe, strength, approach,
       description, key_ingredients, how_to_use, size, image_url);
