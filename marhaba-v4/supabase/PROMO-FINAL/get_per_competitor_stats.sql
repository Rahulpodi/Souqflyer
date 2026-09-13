-- get_per_competitor_stats(p_country text, p_brands text[], p_region text, p_retailer text, p_category text, p_subcategory text, p_quantity text, p_distinct_offers boolean)
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_per_competitor_stats(p_country text, p_brands text[], p_region text DEFAULT NULL::text, p_retailer text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_subcategory text DEFAULT NULL::text, p_quantity text DEFAULT NULL::text, p_distinct_offers boolean DEFAULT false)
 RETURNS TABLE(brand_name text, period_key text, offer_count bigint, category_total bigint, share_pct numeric, avg_offer numeric, avg_regular numeric, avg_discount numeric, avg_price_per_kg numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  today DATE := CURRENT_DATE;
  pkeys TEXT[] := ARRAY['latest4Weeks','latest12Weeks','ytd','latest52Weeks'];
  pfroms DATE[] := ARRAY[today - 27, today - 84, date_trunc('year', today)::date, today - 364];
  i INT;
  cat_total BIGINT;

  -- Only lowercase country + category (stored lowercase in DB)
  v_country TEXT := lower(btrim(coalesce(p_country, '')));
  v_category TEXT := CASE WHEN p_category IS NOT NULL AND btrim(p_category) <> '' THEN lower(btrim(p_category)) ELSE NULL END;
BEGIN
  FOR i IN 1..4 LOOP
    IF p_distinct_offers THEN
      SELECT COUNT(DISTINCT fp.product_name) INTO cat_total
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.start_date >= pfroms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    ELSE
      SELECT COUNT(*) INTO cat_total
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.start_date >= pfroms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    END IF;

    IF p_distinct_offers THEN
      RETURN QUERY
      SELECT fp.brand, pkeys[i],
        COUNT(DISTINCT fp.product_name)::bigint, cat_total,
        CASE WHEN cat_total > 0 THEN ROUND((COUNT(DISTINCT fp.product_name)::numeric / cat_total) * 100, 1) ELSE 0 END,
        ROUND(COALESCE(AVG(CASE WHEN fp.offer_price_num > 0 THEN fp.offer_price_num ELSE NULL END), 0::NUMERIC), 2),
        ROUND(COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 THEN fp.reg_price_num ELSE NULL END), 0::NUMERIC), 2),
        ROUND(COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 AND fp.offer_price_num > 0 AND fp.reg_price_num >= fp.offer_price_num THEN ((fp.reg_price_num - fp.offer_price_num) / fp.reg_price_num) * 100 ELSE NULL END), 0::NUMERIC), 1),
        ROUND(COALESCE(AVG(CASE WHEN fp.weight_kg_num > 0 AND fp.offer_price_num > 0 THEN fp.offer_price_num / fp.weight_kg_num ELSE NULL END), 0::NUMERIC), 2)
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.brand = ANY(p_brands)
        AND fp.start_date >= pfroms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity)
      GROUP BY fp.brand;
    ELSE
      RETURN QUERY
      SELECT fp.brand, pkeys[i],
        COUNT(*)::bigint, cat_total,
        CASE WHEN cat_total > 0 THEN ROUND((COUNT(*)::numeric / cat_total) * 100, 1) ELSE 0 END,
        ROUND(COALESCE(AVG(CASE WHEN fp.offer_price_num > 0 THEN fp.offer_price_num ELSE NULL END), 0::NUMERIC), 2),
        ROUND(COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 THEN fp.reg_price_num ELSE NULL END), 0::NUMERIC), 2),
        ROUND(COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 AND fp.offer_price_num > 0 AND fp.reg_price_num >= fp.offer_price_num THEN ((fp.reg_price_num - fp.offer_price_num) / fp.reg_price_num) * 100 ELSE NULL END), 0::NUMERIC), 1),
        ROUND(COALESCE(AVG(CASE WHEN fp.weight_kg_num > 0 AND fp.offer_price_num > 0 THEN fp.offer_price_num / fp.weight_kg_num ELSE NULL END), 0::NUMERIC), 2)
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.brand = ANY(p_brands)
        AND fp.start_date >= pfroms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity)
      GROUP BY fp.brand;
    END IF;
  END LOOP;
END;
$function$;
