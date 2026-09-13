-- mv_promo_dimensions (materialized view) — feeds every filter dropdown.
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.
--
-- Reference only: the view already exists. Do NOT drop/recreate it to "apply"
-- this file — just refresh it after every pipeline ingestion:
--
--   REFRESH MATERIALIZED VIEW public.mv_promo_dimensions;
--
-- Values keep the table's own casing (e.g. "Cheese", "Al marai"); the UI
-- title-cases them for display.

CREATE MATERIALIZED VIEW public.mv_promo_dimensions AS
 SELECT lower((flyer_products.country)::text) AS country_key,
    'category'::text AS dimension_type,
    flyer_products.category AS dimension_value,
    NULL::text AS parent_category
   FROM flyer_products
  WHERE ((flyer_products.country IS NOT NULL) AND (flyer_products.category IS NOT NULL))
  GROUP BY (lower((flyer_products.country)::text)), flyer_products.category
UNION ALL
 SELECT lower((flyer_products.country)::text) AS country_key,
    'brand'::text AS dimension_type,
    flyer_products.brand AS dimension_value,
    flyer_products.category AS parent_category
   FROM flyer_products
  WHERE ((flyer_products.country IS NOT NULL) AND (flyer_products.brand IS NOT NULL) AND (flyer_products.category IS NOT NULL))
  GROUP BY (lower((flyer_products.country)::text)), flyer_products.brand, flyer_products.category
UNION ALL
 SELECT lower((flyer_products.country)::text) AS country_key,
    'subcategory'::text AS dimension_type,
    flyer_products.type AS dimension_value,
    flyer_products.category AS parent_category
   FROM flyer_products
  WHERE ((flyer_products.country IS NOT NULL) AND (flyer_products.type IS NOT NULL) AND (flyer_products.category IS NOT NULL))
  GROUP BY (lower((flyer_products.country)::text)), flyer_products.type, flyer_products.category
UNION ALL
 SELECT DISTINCT lower((fp.country)::text) AS country_key,
    'region'::text AS dimension_type,
    TRIM(BOTH FROM r.region) AS dimension_value,
    NULL::text AS parent_category
   FROM flyer_products fp,
    LATERAL unnest(string_to_array(fp.coverage_regions, ','::text)) r(region)
  WHERE ((fp.country IS NOT NULL) AND (fp.coverage_regions IS NOT NULL) AND (TRIM(BOTH FROM r.region) <> ''::text))
UNION ALL
 SELECT lower((flyer_products.country)::text) AS country_key,
    'retailer'::text AS dimension_type,
    flyer_products.mart_name AS dimension_value,
    NULL::text AS parent_category
   FROM flyer_products
  WHERE ((flyer_products.country IS NOT NULL) AND (flyer_products.mart_name IS NOT NULL))
  GROUP BY (lower((flyer_products.country)::text)), flyer_products.mart_name
UNION ALL
 SELECT lower((flyer_products.country)::text) AS country_key,
    'pack_size'::text AS dimension_type,
    flyer_products.weight_quantity AS dimension_value,
    flyer_products.category AS parent_category
   FROM flyer_products
  WHERE ((flyer_products.country IS NOT NULL) AND (flyer_products.weight_quantity IS NOT NULL) AND (flyer_products.category IS NOT NULL))
  GROUP BY (lower((flyer_products.country)::text)), flyer_products.weight_quantity, flyer_products.category;

-- Indexes on the view (live, 2026-09-13)
CREATE INDEX IF NOT EXISTS idx_mv_promo_dims_country             ON public.mv_promo_dimensions USING btree (country_key);
CREATE INDEX IF NOT EXISTS idx_mv_promo_dims_country_type        ON public.mv_promo_dimensions USING btree (country_key, dimension_type);
CREATE INDEX IF NOT EXISTS idx_mv_promo_dims_country_type_parent ON public.mv_promo_dimensions USING btree (country_key, dimension_type, parent_category);
CREATE INDEX IF NOT EXISTS idx_mv_promo_dims_country_type_value  ON public.mv_promo_dimensions USING btree (country_key, dimension_type, dimension_value);
