-- get_competitor_pack_aggregations(p_country text, p_region text, p_category text, p_subcategory text, p_retailer text, p_brands text[], p_quantity text, p_distinct_offers boolean, p_period_weeks integer)
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_competitor_pack_aggregations(p_country text, p_region text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_subcategory text DEFAULT NULL::text, p_retailer text DEFAULT NULL::text, p_brands text[] DEFAULT NULL::text[], p_quantity text DEFAULT NULL::text, p_distinct_offers boolean DEFAULT false, p_period_weeks integer DEFAULT 52)
 RETURNS TABLE(brand_name text, weight_qty text, offer_count bigint, min_price numeric, max_price numeric, min_regular numeric, max_regular numeric, min_discount numeric, max_discount numeric, min_perkg numeric, max_perkg numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  cutoff_date DATE := CURRENT_DATE - (p_period_weeks * 7);
  v_category TEXT := CASE WHEN p_category IS NOT NULL AND btrim(p_category) <> '' THEN lower(btrim(p_category)) ELSE NULL END;
BEGIN
  IF p_distinct_offers THEN
    RETURN QUERY
    WITH distinct_products AS (
      SELECT DISTINCT ON (fp.brand, fp.product_name, fp.weight_quantity)
        fp.brand,
        fp.weight_quantity,
        fp.offer_price_num::NUMERIC AS offer_price,
        fp.reg_price_num::NUMERIC   AS reg_price,
        fp.weight_kg_num::NUMERIC   AS weight_kg
      FROM flyer_products fp
      WHERE lower(fp.country) = lower(p_country)
        AND fp.start_date >= cutoff_date
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity)
        AND (p_brands IS NULL OR fp.brand = ANY(p_brands))
      ORDER BY fp.brand, fp.product_name, fp.weight_quantity, fp.start_date DESC
    )
    SELECT
      dp.brand::TEXT,
      COALESCE(dp.weight_quantity, 'N/A')::TEXT,
      COUNT(*)::BIGINT,
      ROUND(COALESCE(MIN(NULLIF(GREATEST(dp.offer_price, 0), 0)), 0), 2),
      ROUND(COALESCE(MAX(NULLIF(GREATEST(dp.offer_price, 0), 0)), 0), 2),
      ROUND(COALESCE(MIN(NULLIF(GREATEST(dp.reg_price, 0), 0)), 0), 2),
      ROUND(COALESCE(MAX(NULLIF(GREATEST(dp.reg_price, 0), 0)), 0), 2),
      ROUND(COALESCE(MIN(CASE WHEN dp.reg_price > dp.offer_price AND dp.offer_price > 0
                              THEN ((dp.reg_price - dp.offer_price) / dp.reg_price) * 100 END), 0), 1),
      ROUND(COALESCE(MAX(CASE WHEN dp.reg_price > dp.offer_price AND dp.offer_price > 0
                              THEN ((dp.reg_price - dp.offer_price) / dp.reg_price) * 100 END), 0), 1),
      ROUND(COALESCE(MIN(CASE WHEN dp.weight_kg > 0 AND dp.offer_price > 0
                              THEN dp.offer_price / dp.weight_kg END), 0), 2),
      ROUND(COALESCE(MAX(CASE WHEN dp.weight_kg > 0 AND dp.offer_price > 0
                              THEN dp.offer_price / dp.weight_kg END), 0), 2)
    FROM distinct_products dp
    GROUP BY dp.brand, dp.weight_quantity
    ORDER BY dp.brand, 3 DESC;
  ELSE
    RETURN QUERY
    SELECT
      fp.brand::TEXT,
      COALESCE(fp.weight_quantity, 'N/A')::TEXT,
      COUNT(*)::BIGINT,
      ROUND(COALESCE(MIN(NULLIF(GREATEST(fp.offer_price_num::NUMERIC, 0), 0)), 0), 2),
      ROUND(COALESCE(MAX(NULLIF(GREATEST(fp.offer_price_num::NUMERIC, 0), 0)), 0), 2),
      ROUND(COALESCE(MIN(NULLIF(GREATEST(fp.reg_price_num::NUMERIC, 0), 0)), 0), 2),
      ROUND(COALESCE(MAX(NULLIF(GREATEST(fp.reg_price_num::NUMERIC, 0), 0)), 0), 2),
      ROUND(COALESCE(MIN(CASE WHEN fp.reg_price_num::NUMERIC > fp.offer_price_num::NUMERIC AND fp.offer_price_num::NUMERIC > 0
                              THEN ((fp.reg_price_num::NUMERIC - fp.offer_price_num::NUMERIC) / fp.reg_price_num::NUMERIC) * 100 END), 0), 1),
      ROUND(COALESCE(MAX(CASE WHEN fp.reg_price_num::NUMERIC > fp.offer_price_num::NUMERIC AND fp.offer_price_num::NUMERIC > 0
                              THEN ((fp.reg_price_num::NUMERIC - fp.offer_price_num::NUMERIC) / fp.reg_price_num::NUMERIC) * 100 END), 0), 1),
      ROUND(COALESCE(MIN(CASE WHEN fp.weight_kg_num::NUMERIC > 0 AND fp.offer_price_num::NUMERIC > 0
                              THEN fp.offer_price_num::NUMERIC / fp.weight_kg_num::NUMERIC END), 0), 2),
      ROUND(COALESCE(MAX(CASE WHEN fp.weight_kg_num::NUMERIC > 0 AND fp.offer_price_num::NUMERIC > 0
                              THEN fp.offer_price_num::NUMERIC / fp.weight_kg_num::NUMERIC END), 0), 2)
    FROM flyer_products fp
    WHERE lower(fp.country) = lower(p_country)
      AND fp.start_date >= cutoff_date
      AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
      AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
      AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
      AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
      AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity)
      AND (p_brands IS NULL OR fp.brand = ANY(p_brands))
    GROUP BY fp.brand, fp.weight_quantity
    ORDER BY fp.brand, 3 DESC;
  END IF;
END;
$function$;
