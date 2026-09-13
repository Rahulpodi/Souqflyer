-- get_promotion_analysis_stats_multi(p_country text, p_my_brand text, p_competitors text[], p_region text, p_retailer text, p_category text, p_subcategory text, p_quantity text, p_distinct_offers boolean)
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_promotion_analysis_stats_multi(p_country text, p_my_brand text, p_competitors text[] DEFAULT NULL::text[], p_region text DEFAULT NULL::text, p_retailer text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_subcategory text DEFAULT NULL::text, p_quantity text DEFAULT NULL::text, p_distinct_offers boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  result JSONB := '{}'::jsonb;
  period_keys TEXT[] := ARRAY['latest4Weeks','latest12Weeks','ytd','latest52Weeks'];
  period_froms DATE[];
  today DATE := CURRENT_DATE;
  i INT;
  my_count BIGINT;
  comp_count BIGINT;
  total_ct BIGINT;
  avg_offer_my NUMERIC; avg_offer_comp NUMERIC;
  avg_reg_my NUMERIC; avg_reg_comp NUMERIC;
  avg_disc_my NUMERIC; avg_disc_comp NUMERIC;
  avg_pkg_my NUMERIC; avg_pkg_comp NUMERIC;
  use_specific_competitors BOOLEAN;
  period_result JSONB;

  -- Only lowercase country + category (stored lowercase in DB)
  v_country TEXT := lower(btrim(coalesce(p_country, '')));
  v_category TEXT := CASE WHEN p_category IS NOT NULL AND btrim(p_category) <> '' THEN lower(btrim(p_category)) ELSE NULL END;
BEGIN
  period_froms := ARRAY[
    today - 27,
    today - 84,
    date_trunc('year', today)::date,
    today - 364
  ];

  use_specific_competitors := (p_competitors IS NOT NULL AND array_length(p_competitors, 1) > 0);

  FOR i IN 1..4 LOOP

    -- MY BRAND COUNT
    IF p_distinct_offers THEN
      SELECT COUNT(DISTINCT product_name) INTO my_count
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.brand = p_my_brand
        AND fp.start_date >= period_froms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    ELSE
      SELECT COUNT(*) INTO my_count
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.brand = p_my_brand
        AND fp.start_date >= period_froms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    END IF;

    -- COMPETITOR COUNT
    IF use_specific_competitors THEN
      IF p_distinct_offers THEN
        SELECT COUNT(DISTINCT product_name) INTO comp_count
        FROM flyer_products fp
        WHERE lower(fp.country) = v_country
          AND fp.brand = ANY(p_competitors)
          AND fp.start_date >= period_froms[i]
          AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
          AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
          AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
          AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
          AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
      ELSE
        SELECT COUNT(*) INTO comp_count
        FROM flyer_products fp
        WHERE lower(fp.country) = v_country
          AND fp.brand = ANY(p_competitors)
          AND fp.start_date >= period_froms[i]
          AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
          AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
          AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
          AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
          AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
      END IF;
    ELSE
      IF p_distinct_offers THEN
        SELECT COUNT(DISTINCT product_name) INTO comp_count
        FROM flyer_products fp
        WHERE lower(fp.country) = v_country
          AND fp.brand != p_my_brand
          AND fp.start_date >= period_froms[i]
          AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
          AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
          AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
          AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
          AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
      ELSE
        SELECT COUNT(*) INTO comp_count
        FROM flyer_products fp
        WHERE lower(fp.country) = v_country
          AND fp.brand != p_my_brand
          AND fp.start_date >= period_froms[i]
          AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
          AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
          AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
          AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
          AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
      END IF;
    END IF;

    -- TOTAL MARKET COUNT
    IF p_distinct_offers THEN
      SELECT COUNT(DISTINCT product_name) INTO total_ct
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.start_date >= period_froms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    ELSE
      SELECT COUNT(*) INTO total_ct
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.start_date >= period_froms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    END IF;

    -- AVG PRICES: MY BRAND
    SELECT
      COALESCE(AVG(CASE WHEN fp.offer_price_num > 0 THEN fp.offer_price_num ELSE NULL END), 0::NUMERIC),
      COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 THEN fp.reg_price_num ELSE NULL END), 0::NUMERIC),
      COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 AND fp.offer_price_num > 0 AND fp.reg_price_num >= fp.offer_price_num THEN ((fp.reg_price_num - fp.offer_price_num) / fp.reg_price_num) * 100 ELSE NULL END), 0::NUMERIC),
      COALESCE(AVG(CASE WHEN fp.weight_kg_num > 0 AND fp.offer_price_num > 0 THEN fp.offer_price_num / fp.weight_kg_num ELSE NULL END), 0::NUMERIC)
    INTO avg_offer_my, avg_reg_my, avg_disc_my, avg_pkg_my
    FROM flyer_products fp
    WHERE lower(fp.country) = v_country
      AND fp.brand = p_my_brand
      AND fp.start_date >= period_froms[i]
      AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
      AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
      AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
      AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
      AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);

    -- AVG PRICES: COMPETITORS
    IF use_specific_competitors THEN
      SELECT
        COALESCE(AVG(CASE WHEN fp.offer_price_num > 0 THEN fp.offer_price_num ELSE NULL END), 0::NUMERIC),
        COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 THEN fp.reg_price_num ELSE NULL END), 0::NUMERIC),
        COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 AND fp.offer_price_num > 0 AND fp.reg_price_num >= fp.offer_price_num THEN ((fp.reg_price_num - fp.offer_price_num) / fp.reg_price_num) * 100 ELSE NULL END), 0::NUMERIC),
        COALESCE(AVG(CASE WHEN fp.weight_kg_num > 0 AND fp.offer_price_num > 0 THEN fp.offer_price_num / fp.weight_kg_num ELSE NULL END), 0::NUMERIC)
      INTO avg_offer_comp, avg_reg_comp, avg_disc_comp, avg_pkg_comp
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.brand = ANY(p_competitors)
        AND fp.start_date >= period_froms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    ELSE
      SELECT
        COALESCE(AVG(CASE WHEN fp.offer_price_num > 0 THEN fp.offer_price_num ELSE NULL END), 0::NUMERIC),
        COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 THEN fp.reg_price_num ELSE NULL END), 0::NUMERIC),
        COALESCE(AVG(CASE WHEN fp.reg_price_num > 0 AND fp.offer_price_num > 0 AND fp.reg_price_num >= fp.offer_price_num THEN ((fp.reg_price_num - fp.offer_price_num) / fp.reg_price_num) * 100 ELSE NULL END), 0::NUMERIC),
        COALESCE(AVG(CASE WHEN fp.weight_kg_num > 0 AND fp.offer_price_num > 0 THEN fp.offer_price_num / fp.weight_kg_num ELSE NULL END), 0::NUMERIC)
      INTO avg_offer_comp, avg_reg_comp, avg_disc_comp, avg_pkg_comp
      FROM flyer_products fp
      WHERE lower(fp.country) = v_country
        AND fp.brand != p_my_brand
        AND fp.start_date >= period_froms[i]
        AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
        AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
        AND (v_category IS NULL OR lower(btrim(fp.category)) = v_category)
        AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
        AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
    END IF;

    period_result := jsonb_build_object(
      'myBrandCount', my_count,
      'competitorCount', comp_count,
      'totalCount', total_ct,
      'myBrandShare', CASE WHEN total_ct > 0 THEN ROUND((my_count::numeric / total_ct) * 100, 1) ELSE 0 END,
      'competitorShare', CASE WHEN total_ct > 0 THEN ROUND((comp_count::numeric / total_ct) * 100, 1) ELSE 0 END,
      'avgOfferPrice', jsonb_build_object('myBrand', ROUND(avg_offer_my, 2), 'competitor', ROUND(avg_offer_comp, 2)),
      'avgRegularPrice', jsonb_build_object('myBrand', ROUND(avg_reg_my, 2), 'competitor', ROUND(avg_reg_comp, 2)),
      'avgDiscount', jsonb_build_object('myBrand', ROUND(avg_disc_my, 1), 'competitor', ROUND(avg_disc_comp, 1)),
      'avgPricePerKg', jsonb_build_object('myBrand', ROUND(avg_pkg_my, 2), 'competitor', ROUND(avg_pkg_comp, 2))
    );

    result := result || jsonb_build_object(period_keys[i], period_result);
  END LOOP;

  RETURN result;
END;
$function$;
