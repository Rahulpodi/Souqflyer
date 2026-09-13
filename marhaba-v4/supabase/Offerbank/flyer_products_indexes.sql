-- flyer_products indexes
-- Covers the "Index flyer products by country…" (Offerbank) and
-- "Indexes for Flyer Product Filtering" (PROMO-FINAL) snippets.
-- Live definitions exported from Supabase on 2026-09-13 (source of truth).
--
-- Record only — every index already exists. IF NOT EXISTS makes re-running
-- harmless, but each CREATE INDEX briefly blocks writes to flyer_products.
--
-- Note: many of these are exact duplicates (e.g. 7 btree indexes on `brand`,
-- 7 on `category`, 5 on `mart_name`). Duplicates slow down pipeline inserts
-- and waste storage without speeding up reads — worth a cleanup pass later.
--
-- Indexes the app's queries rely on most (2026-09-13 EXPLAIN):
--   idx_flyer_cat_normalized         lower(btrim(category))
--   idx_flyer_products_type_norm     btrim(lower(type))
--   idx_fp_lower_country_start_date  lower(country), start_date DESC
--   idx_flyer_products_country_brand_normalized

-- Primary key / uniqueness
CREATE UNIQUE INDEX IF NOT EXISTS flyer_products_product_key_id_pkey ON public.flyer_products USING btree (product_key_id);
CREATE UNIQUE INDEX IF NOT EXISTS unique_dedup_hash ON public.flyer_products USING btree (dedup_hash);

-- Case-insensitive lookups (used by the app's queries)
CREATE INDEX IF NOT EXISTS idx_flyer_cat_normalized ON public.flyer_products USING btree (lower(TRIM(BOTH FROM category)));
CREATE INDEX IF NOT EXISTS idx_flyer_products_category_norm ON public.flyer_products USING btree (TRIM(BOTH FROM lower(category)));
CREATE INDEX IF NOT EXISTS idx_flyer_products_type_norm ON public.flyer_products USING btree (TRIM(BOTH FROM lower(type)));
CREATE INDEX IF NOT EXISTS idx_flyer_brand_normalized ON public.flyer_products USING btree (lower(TRIM(BOTH FROM brand)));
CREATE INDEX IF NOT EXISTS idx_flyer_products_country_brand_normalized ON public.flyer_products USING btree (lower(TRIM(BOTH FROM country)), lower(TRIM(BOTH FROM brand)));
CREATE INDEX IF NOT EXISTS idx_fp_lower_country_start_date ON public.flyer_products USING btree (lower((country)::text), start_date DESC);
CREATE INDEX IF NOT EXISTS idx_fp_lower_trim_country ON public.flyer_products USING btree (lower(btrim((country)::text)));
CREATE INDEX IF NOT EXISTS idx_flyer_products_filtering ON public.flyer_products USING btree (lower((country)::text), category, brand, start_date DESC);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_lower_idx ON public.flyer_products USING btree (lower((country)::text));
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_lower_category_brand_idx ON public.flyer_products USING btree (lower((country)::text), category, brand);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_lower_mart_name_idx ON public.flyer_products USING btree (lower((country)::text), mart_name);

-- Country composites
CREATE INDEX IF NOT EXISTS idx_fp_offerbank_country_start ON public.flyer_products USING btree (country, start_date DESC);
CREATE INDEX IF NOT EXISTS idx_fp_offerbank_country_category ON public.flyer_products USING btree (country, category);
CREATE INDEX IF NOT EXISTS idx_fp_offerbank_country_retailer ON public.flyer_products USING btree (country, mart_name);
CREATE INDEX IF NOT EXISTS idx_fp_offerbank_country_type ON public.flyer_products USING btree (country, type);
CREATE INDEX IF NOT EXISTS idx_flyer_products_country_id ON public.flyer_products USING btree (country, id);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_brand_idx ON public.flyer_products USING btree (country, brand);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_brand_idx1 ON public.flyer_products USING btree (country, brand);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_brand_start_date_end_date_idx ON public.flyer_products USING btree (country, brand, start_date, end_date);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_category_idx ON public.flyer_products USING btree (country, category);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_category_idx1 ON public.flyer_products USING btree (country, category);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_category_mart_name_idx ON public.flyer_products USING btree (country, category, mart_name);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_category_type_mart_name_we_idx ON public.flyer_products USING btree (country, category, type, mart_name, weight_quantity);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_created_at_idx ON public.flyer_products USING btree (country, created_at);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_mart_name_idx ON public.flyer_products USING btree (country, mart_name);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_start_date_idx ON public.flyer_products USING btree (country, start_date);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_start_date_idx1 ON public.flyer_products USING btree (country, start_date) WHERE ((brand IS NOT NULL) AND (start_date IS NOT NULL));
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_start_date_idx2 ON public.flyer_products USING btree (country, start_date DESC);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_type_idx ON public.flyer_products USING btree (country, type);

-- Category / offer matching composites
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_category_type_idx ON public.flyer_products USING btree (category, type);
CREATE INDEX IF NOT EXISTS idx_flyer_products_category_id ON public.flyer_products USING btree (category, id);
CREATE INDEX IF NOT EXISTS idx_flyer_products_match ON public.flyer_products USING btree (category, offer_name, country, mart_name);
CREATE INDEX IF NOT EXISTS idx_flyer_products_match_dates ON public.flyer_products USING btree (category, offer_name, country, mart_name);
CREATE INDEX IF NOT EXISTS idx_flyer_products_valid_dates ON public.flyer_products USING btree (category, offer_name, country, mart_name, start_date, end_date) WHERE ((start_date IS NOT NULL) AND (end_date IS NOT NULL));

-- Single-column btree
CREATE INDEX IF NOT EXISTS idx_fp_country ON public.flyer_products USING btree (country);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_idx ON public.flyer_products USING btree (country);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_country_idx1 ON public.flyer_products USING btree (country);
CREATE INDEX IF NOT EXISTS idx_fp_category ON public.flyer_products USING btree (category);
CREATE INDEX IF NOT EXISTS idx_flyer_category ON public.flyer_products USING btree (category);
CREATE INDEX IF NOT EXISTS idx_flyer_products_category ON public.flyer_products USING btree (category);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_category_idx ON public.flyer_products USING btree (category);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_category_idx1 ON public.flyer_products USING btree (category);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_category_idx2 ON public.flyer_products USING btree (category);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_category_idx3 ON public.flyer_products USING btree (category);
CREATE INDEX IF NOT EXISTS idx_fp_brand ON public.flyer_products USING btree (brand);
CREATE INDEX IF NOT EXISTS idx_flyer_brand ON public.flyer_products USING btree (brand);
CREATE INDEX IF NOT EXISTS idx_flyer_products_brand ON public.flyer_products USING btree (brand);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_brand_idx ON public.flyer_products USING btree (brand);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_brand_idx1 ON public.flyer_products USING btree (brand);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_brand_idx2 ON public.flyer_products USING btree (brand);
CREATE INDEX IF NOT EXISTS idx_fp_mart_name ON public.flyer_products USING btree (mart_name);
CREATE INDEX IF NOT EXISTS idx_flyer_products_retailer ON public.flyer_products USING btree (mart_name);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_mart_name_idx ON public.flyer_products USING btree (mart_name);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_mart_name_idx1 ON public.flyer_products USING btree (mart_name);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_mart_name_idx2 ON public.flyer_products USING btree (mart_name);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_mart_name_idx3 ON public.flyer_products USING btree (mart_name);
CREATE INDEX IF NOT EXISTS idx_fp_type ON public.flyer_products USING btree (type);
CREATE INDEX IF NOT EXISTS idx_flyer_products_subcategory ON public.flyer_products USING btree (type);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_type_idx ON public.flyer_products USING btree (type);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_type_idx1 ON public.flyer_products USING btree (type);
CREATE INDEX IF NOT EXISTS idx_fp_weight_quantity ON public.flyer_products USING btree (weight_quantity);
CREATE INDEX IF NOT EXISTS idx_flyer_products_packsize ON public.flyer_products USING btree (weight_quantity);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_weight_quantity_idx ON public.flyer_products USING btree (weight_quantity);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_weight_quantity_idx1 ON public.flyer_products USING btree (weight_quantity);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_weight_quantity_idx2 ON public.flyer_products USING btree (weight_quantity);
CREATE INDEX IF NOT EXISTS idx_product_name ON public.flyer_products USING btree (product_name);
CREATE INDEX IF NOT EXISTS idx_flyer_product_name ON public.flyer_products USING btree (product_name);
CREATE INDEX IF NOT EXISTS idx_flyer_products_id ON public.flyer_products USING btree (id);

-- Dates
CREATE INDEX IF NOT EXISTS idx_fp_start_date ON public.flyer_products USING btree (start_date DESC);
CREATE INDEX IF NOT EXISTS idx_flyer_products_start_date ON public.flyer_products USING btree (start_date);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_start_date_idx ON public.flyer_products USING btree (start_date);
CREATE INDEX IF NOT EXISTS idx_fp_end_date ON public.flyer_products USING btree (end_date);
CREATE INDEX IF NOT EXISTS idx_flyer_products_end_date ON public.flyer_products USING btree (end_date);
CREATE INDEX IF NOT EXISTS idx_flyer_products_dates ON public.flyer_products USING btree (start_date, end_date);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_extract_end_date_idx ON public.flyer_products USING btree (extract_end_date(offer_timeline));

-- Pipeline bookkeeping (partial indexes)
CREATE INDEX IF NOT EXISTS idx_flyer_dedup_hash ON public.flyer_products USING btree (dedup_hash) WHERE (dedup_hash IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_flyer_needs_recat ON public.flyer_products USING btree (product_key_id) WHERE ((normalization_status = 'FALSE'::text) OR (normalization_status IS NULL));
CREATE INDEX IF NOT EXISTS idx_flyer_source_slot ON public.flyer_products USING btree (source_slot_index) WHERE (source_slot_index IS NOT NULL);

-- Trigram (ILIKE / search)
CREATE INDEX IF NOT EXISTS idx_fp_trgm_brand ON public.flyer_products USING gin (brand gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_brand_trgm ON public.flyer_products USING gin (brand gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fp_trgm_category ON public.flyer_products USING gin (category gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fp_trgm_coverage_regions ON public.flyer_products USING gin (coverage_regions gin_trgm_ops);
CREATE INDEX IF NOT EXISTS flyer_products_duplicate_coverage_regions_idx ON public.flyer_products USING gin (coverage_regions gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fp_trgm_mart_name ON public.flyer_products USING gin (mart_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fp_trgm_product_name ON public.flyer_products USING gin (product_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_product_name_trgm ON public.flyer_products USING gin (product_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fp_trgm_type ON public.flyer_products USING gin (type gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_fp_trgm_weight_quantity ON public.flyer_products USING gin (weight_quantity gin_trgm_ops);
