-- get_competitor_pricing_aggregations(p_country text, p_region text, p_category text, p_subcategory text, p_retailer text, p_brands text[], p_quantity text, p_distinct_offers boolean, p_period_weeks integer)
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_competitor_pricing_aggregations(p_country text, p_region text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_subcategory text DEFAULT NULL::text, p_retailer text DEFAULT NULL::text, p_brands text[] DEFAULT NULL::text[], p_quantity text DEFAULT NULL::text, p_distinct_offers boolean DEFAULT false, p_period_weeks integer DEFAULT 52)
 RETURNS TABLE(brand_name text, offer_count bigint, offer_avg numeric, reg_avg numeric, discount_avg numeric, perkg_avg numeric)
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
        fp.offer_price_num::NUMERIC AS offer_price,
        fp.reg_price_num::NUMERIC AS reg_price,
        fp.weight_kg_num::NUMERIC AS weight_kg
      FROM flyer_products fp
      WHERE lower(fp.country) = lower(p_country)
        AND fp.start_date >= cutoff_date
        AND fp.offer_price_num IS NOT NULL AND fp.offer_price_num::NUMERIC > 0
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity)
        AND (p_brands IS NULL OR fp.brand = ANY(p_brands))
      ORDER BY fp.brand, fp.product_name, fp.weight_quantity, fp.start_date DESC
    )
    SELECT
      dp.brand::TEXT AS brand_name,
      COUNT(*)::BIGINT AS offer_count,
      ROUND(COALESCE(AVG(CASE WHEN dp.offer_price > 0 THEN dp.offer_price ELSE NULL END), 0::NUMERIC), 2) AS offer_avg,
      ROUND(COALESCE(AVG(CASE WHEN dp.reg_price > 0 THEN dp.reg_price ELSE NULL END), 0::NUMERIC), 2) AS reg_avg,
      ROUND(COALESCE(AVG(
        CASE WHEN dp.reg_price > 0 AND dp.offer_price > 0 AND dp.reg_price >= dp.offer_price
          THEN ((dp.reg_price - dp.offer_price) / dp.reg_price) * 100
          ELSE NULL END
      ), 0), 1) AS discount_avg,
      ROUND(COALESCE(AVG(
        CASE WHEN dp.weight_kg > 0 AND dp.offer_price > 0
          THEN dp.offer_price / dp.weight_kg
          ELSE NULL END
      ), 0), 2) AS perkg_avg
    FROM distinct_products dp
    GROUP BY dp.brand
    ORDER BY offer_count DESC;
  ELSE
    RETURN QUERY
    SELECT
      fp.brand::TEXT AS brand_name,
      COUNT(*)::BIGINT AS offer_count,
      ROUND(COALESCE(AVG(CASE WHEN fp.offer_price_num > 0 THEN fp.offer_price_num::NUMERIC ELSE NULL END), 0::NUMERIC), 2) AS offer_avg,
      ROUND(COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 THEN fp.reg_price_num::NUMERIC ELSE NULL END), 0::NUMERIC), 2) AS reg_avg,
      ROUND(COALESCE(AVG(
        CASE WHEN fp.reg_price_num > 0 AND fp.offer_price_num > 0 AND fp.reg_price_num::NUMERIC >= fp.offer_price_num::NUMERIC
          THEN ((fp.reg_price_num::NUMERIC - fp.offer_price_num::NUMERIC) / fp.reg_price_num::NUMERIC) * 100
          ELSE NULL END
      ), 0), 1) AS discount_avg,
      ROUND(COALESCE(AVG(
        CASE WHEN fp.weight_kg_num > 0 AND fp.offer_price_num > 0
          THEN fp.offer_price_num::NUMERIC / fp.weight_kg_num::NUMERIC
          ELSE NULL END
      ), 0), 2) AS perkg_avg
    FROM flyer_products fp
    WHERE lower(fp.country) = lower(p_country)
      AND fp.start_date >= cutoff_date
      AND fp.offer_price_num IS NOT NULL AND fp.offer_price_num::NUMERIC > 0
      AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
      AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
      AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
      AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
      AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity)
      AND (p_brands IS NULL OR fp.brand = ANY(p_brands))
    GROUP BY fp.brand
    ORDER BY offer_count DESC;
  END IF;
END;
$function$;
