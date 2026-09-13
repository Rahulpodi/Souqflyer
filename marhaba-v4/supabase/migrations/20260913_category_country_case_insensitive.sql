-- ============================================================
-- Category normalization pipeline: make live RPCs case-insensitive
--
-- The pipeline rewrote flyer_products.category / type / country to sentence
-- case ("Cheese", "Saudi arabia", "Uae"). Live RPCs compared against lowercase
-- or exact values, so Promo Analysis returned zeros and Offer Bank hash-joined
-- category (seq scan -> statement timeout on Saudi Arabia).
--
-- This patches the LIVE function definitions in place (read from
-- pg_get_functiondef, not from this repo — the repo copies had drifted).
-- Only comparison expressions change; bodies, signatures and grants are
-- preserved via CREATE OR REPLACE. No tables, rows or indexes are touched.
--
-- Dry run 2026-09-13: all 10 functions patched, 0 case-sensitive comparisons
-- left. Offer Bank Saudi+Cheese plan: seq scan (cost 88k) -> bitmap index
-- scans on idx_flyer_cat_normalized + country index (cost 25.7k).
--
-- After every post_ingestion_pipeline.py run:
--   REFRESH MATERIALIZED VIEW public.mv_promo_dimensions;
-- ============================================================

DO $patch$
DECLARE
  r record;
  v_new text;
  v_raw constant text := '(?<!btrim\()fp\.category = |(?<!lower\()fp\.type = |(?<!lower\()fp\.country = v_country|(?<!btrim\()parent_category = p_category|lower\(fp\.(category|type)\) = ANY\(SELECT';
BEGIN
  FOR r IN
    SELECT p.oid,
           p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')' AS sig,
           pg_get_functiondef(p.oid) AS def
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname IN ('get_offers_filtered_paged','get_promotion_analysis_stats_multi','get_per_competitor_stats',
                        'get_market_totals','get_competitor_pricing_aggregations','get_competitor_pack_aggregations',
                        'get_retailer_activity','get_promo_brands_by_category','get_promo_subcategories_by_category',
                        'get_promo_pack_sizes_by_category')
      AND NOT ('p_base_pack' = ANY(coalesce(p.proargnames, '{}')))   -- unused 8-arg get_market_totals overload
  LOOP
    v_new := r.def;
    v_new := regexp_replace(v_new, '(?<!btrim\()fp\.category = v_category', 'lower(btrim(fp.category)) = v_category', 'g');
    v_new := regexp_replace(v_new, '(?<!btrim\()fp\.category = p_category', 'lower(btrim(fp.category)) = lower(btrim(p_category))', 'g');
    v_new := regexp_replace(v_new, '(?<!btrim\()fp\.category = ANY\(v_categories\)', 'lower(btrim(fp.category)) = ANY(v_categories)', 'g');
    v_new := regexp_replace(v_new, 'lower\(fp\.category\) = ANY\(SELECT lower\(unnest\(p_categories\)\)\)', 'lower(btrim(fp.category)) = ANY(ARRAY(SELECT lower(btrim(c)) FROM unnest(p_categories) c))', 'g');
    v_new := regexp_replace(v_new, '(?<!lower\()fp\.type = p_subcategory', 'btrim(lower(fp.type)) = lower(btrim(p_subcategory))', 'g');
    v_new := regexp_replace(v_new, '(?<!lower\()fp\.type = ANY\(p_subcategories\)', 'btrim(lower(fp.type)) = ANY(ARRAY(SELECT lower(btrim(s)) FROM unnest(p_subcategories) s))', 'g');
    v_new := regexp_replace(v_new, 'lower\(fp\.type\) = ANY\(SELECT lower\(unnest\(p_subcategories\)\)\)', 'btrim(lower(fp.type)) = ANY(ARRAY(SELECT lower(btrim(s)) FROM unnest(p_subcategories) s))', 'g');
    v_new := regexp_replace(v_new, '(?<!lower\()fp\.country = v_country', 'lower(fp.country) = v_country', 'g');
    v_new := regexp_replace(v_new, '(?<!btrim\()parent_category = p_category', 'lower(btrim(parent_category)) = lower(btrim(p_category))', 'g');

    IF regexp_count(v_new, v_raw) > 0 THEN
      RAISE EXCEPTION 'unpatched comparison left in %', r.sig;
    END IF;

    IF v_new <> r.def THEN
      EXECUTE v_new;
      RAISE NOTICE 'patched %', r.sig;
    END IF;
  END LOOP;
END
$patch$;

-- Dropdown source still held pre-pipeline category names. Values keep the
-- table's own casing (UI capitals unchanged).
REFRESH MATERIALIZED VIEW public.mv_promo_dimensions;

