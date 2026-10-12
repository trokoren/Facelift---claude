-- Product sheet details. Descriptions, ingredients, size and how-to-use are filled in by research
-- (verified against brand pages); the sheet hides any field that's empty.
-- expert_quote: the dermatologist's exact words from source_url (empty if the article only paraphrases).
alter table public.product_catalog
  add column if not exists description text,
  add column if not exists key_ingredients text[],
  add column if not exists how_to_use text,
  add column if not exists size text,
  add column if not exists expert_quote text;
comment on column public.product_catalog.description is 'Two sentences in the FACELIFT esthetician voice, shown in the product sheet.';
comment on column public.product_catalog.expert_quote is 'Exact words of the dermatologist from source_url. Leave empty if the article only paraphrases.';

update public.product_catalog p set expert_quote = v.q
from (values
  ('SkinCeuticals', 'C E Ferulic', 'C E Ferulic is my favorite vitamin C serum.'),
  ('La Roche-Posay', 'Cicaplast Balm B5+', 'I love this stuff and have multiple tubes of it all over my house.'),
  ('The Ordinary', 'Niacinamide 10% + Zinc 1%', 'Affordable, effective, and especially helpful for oily or acne-prone skin thanks to the added zinc.'),
  ('La Roche-Posay', 'Hyalu B5 Pure Hyaluronic Acid Serum', 'The Hyalu B5 is great for hydration.'),
  ('La Roche-Posay', 'Toleriane Double Repair Face Moisturizer', 'Has just the right consistency and hydrates the skin without clogging pores.'),
  ('Paula''s Choice', '10% Niacinamide Booster', 'It''s lightweight, gentle, and suitable for all skin types.')
) as v(brand, name, q)
where p.brand = v.brand and p.name = v.name;
