-- get_retailer_activity(target_brand text, selected_country text, p_regions text[], p_categories text[], p_subcategories text[], p_pack_sizes text[], p_distinct_only boolean)
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_retailer_activity(target_brand text, selected_country text, p_regions text[] DEFAULT '{}'::text[], p_categories text[] DEFAULT '{}'::text[], p_subcategories text[] DEFAULT '{}'::text[], p_pack_sizes text[] DEFAULT '{}'::text[], p_distinct_only boolean DEFAULT false)
 RETURNS TABLE(retailer text, offer_count bigint, avg_offer_price numeric, avg_regular_price numeric, avg_discount numeric, latest_date date)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  v_categories TEXT[];
BEGIN
  IF p_categories IS NOT NULL AND array_length(p_categories, 1) > 0 THEN
    SELECT array_agg(lower(btrim(x)))
    INTO v_categories
    FROM unnest(p_categories) AS x
    WHERE btrim(x) <> '';
  ELSE
    v_categories := '{}';
  END IF;

  IF p_distinct_only THEN
    RETURN QUERY
    WITH distinct_products AS (
      SELECT DISTINCT ON (fp.mart_name, fp.product_name, fp.weight_quantity)
        fp.mart_name,
        fp.offer_price_num::NUMERIC AS offer_price,
        fp.reg_price_num::NUMERIC AS reg_price,
        fp.start_date
      FROM flyer_products fp
      WHERE fp.brand = target_brand
        AND lower(fp.country) = lower(selected_country)
        AND fp.offer_price_num IS NOT NULL AND fp.offer_price_num::NUMERIC > 0
        AND (array_length(p_regions, 1) IS NULL OR array_length(p_regions, 1) = 0
             OR EXISTS (SELECT 1 FROM unnest(p_regions) r WHERE fp.coverage_regions ILIKE '%' || r || '%'))
        AND (array_length(v_categories, 1) IS NULL OR array_length(v_categories, 1) = 0
             OR lower(btrim(fp.category)) = ANY(v_categories))
        AND (array_length(p_subcategories, 1) IS NULL OR array_length(p_subcategories, 1) = 0
             OR btrim(lower(fp.type)) = ANY(ARRAY(SELECT lower(btrim(s)) FROM unnest(p_subcategories) s)))
        AND (array_length(p_pack_sizes, 1) IS NULL OR array_length(p_pack_sizes, 1) = 0
             OR fp.weight_quantity = ANY(p_pack_sizes))
      ORDER BY fp.mart_name, fp.product_name, fp.weight_quantity, fp.start_date DESC
    )
    SELECT
      dp.mart_name::TEXT AS retailer,
      COUNT(*)::BIGINT AS offer_count,
      ROUND(COALESCE(AVG(CASE WHEN dp.offer_price > 0 THEN dp.offer_price ELSE NULL END), 0::NUMERIC), 2) AS avg_offer_price,
      ROUND(COALESCE(AVG(CASE WHEN dp.reg_price > 0 THEN dp.reg_price ELSE NULL END), 0::NUMERIC), 2) AS avg_regular_price,
      ROUND(COALESCE(AVG(
        CASE WHEN dp.reg_price > 0 AND dp.offer_price > 0 AND dp.reg_price >= dp.offer_price
          THEN ((dp.reg_price - dp.offer_price) / dp.reg_price) * 100
          ELSE NULL END
      ), 0), 1) AS avg_discount,
      MAX(dp.start_date) AS latest_date
    FROM distinct_products dp
    WHERE dp.mart_name IS NOT NULL
    GROUP BY dp.mart_name
    ORDER BY offer_count DESC;
  ELSE
    RETURN QUERY
    SELECT
      fp.mart_name::TEXT AS retailer,
      COUNT(*)::BIGINT AS offer_count,
      ROUND(COALESCE(AVG(CASE WHEN fp.offer_price_num > 0 THEN fp.offer_price_num::NUMERIC ELSE NULL END), 0::NUMERIC), 2) AS avg_offer_price,
      ROUND(COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 THEN fp.reg_price_num::NUMERIC ELSE NULL END), 0::NUMERIC), 2) AS avg_regular_price,
      ROUND(COALESCE(AVG(
        CASE WHEN fp.reg_price_num > 0 AND fp.offer_price_num > 0 AND fp.reg_price_num::NUMERIC >= fp.offer_price_num::NUMERIC
          THEN ((fp.reg_price_num::NUMERIC - fp.offer_price_num::NUMERIC) / fp.reg_price_num::NUMERIC) * 100
          ELSE NULL END
      ), 0), 1) AS avg_discount,
      MAX(fp.start_date) AS latest_date
    FROM flyer_products fp
    WHERE fp.brand = target_brand
      AND lower(fp.country) = lower(selected_country)
      AND fp.mart_name IS NOT NULL
      AND fp.offer_price_num IS NOT NULL AND fp.offer_price_num::NUMERIC > 0
      AND (array_length(p_regions, 1) IS NULL OR array_length(p_regions, 1) = 0
           OR EXISTS (SELECT 1 FROM unnest(p_regions) r WHERE fp.coverage_regions ILIKE '%' || r || '%'))
      AND (array_length(v_categories, 1) IS NULL OR array_length(v_categories, 1) = 0
           OR lower(btrim(fp.category)) = ANY(v_categories))
      AND (array_length(p_subcategories, 1) IS NULL OR array_length(p_subcategories, 1) = 0
           OR btrim(lower(fp.type)) = ANY(ARRAY(SELECT lower(btrim(s)) FROM unnest(p_subcategories) s)))
      AND (array_length(p_pack_sizes, 1) IS NULL OR array_length(p_pack_sizes, 1) = 0
           OR fp.weight_quantity = ANY(p_pack_sizes))
    GROUP BY fp.mart_name
    ORDER BY offer_count DESC;
  END IF;
END;
$function$;
