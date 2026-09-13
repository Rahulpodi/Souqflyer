-- get_market_totals(p_country text, p_region text, p_retailer text, p_category text, p_subcategory text, p_quantity text, p_distinct_offers boolean)
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_market_totals(p_country text, p_region text DEFAULT NULL::text, p_retailer text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_subcategory text DEFAULT NULL::text, p_quantity text DEFAULT NULL::text, p_distinct_offers boolean DEFAULT false)
 RETURNS TABLE(total_4w bigint, total_12w bigint, total_ytd bigint, total_52w bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  today DATE := CURRENT_DATE;
BEGIN
  IF p_distinct_offers THEN
    RETURN QUERY
    SELECT
      COUNT(DISTINCT CASE WHEN fp.start_date >= today - 27  THEN fp.product_name END)::bigint,
      COUNT(DISTINCT CASE WHEN fp.start_date >= today - 84  THEN fp.product_name END)::bigint,
      COUNT(DISTINCT CASE WHEN fp.start_date >= date_trunc('year', today)::date THEN fp.product_name END)::bigint,
      COUNT(DISTINCT CASE WHEN fp.start_date >= today - 364 THEN fp.product_name END)::bigint
    FROM flyer_products fp
    WHERE lower(fp.country) = lower(p_country)
      AND fp.start_date >= today - 364
      AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
      AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
      AND (p_category IS NULL OR lower(btrim(fp.category)) = lower(btrim(p_category)))
      AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
      AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
  ELSE
    RETURN QUERY
    SELECT
      COUNT(CASE WHEN fp.start_date >= today - 27  THEN 1 END)::bigint,
      COUNT(CASE WHEN fp.start_date >= today - 84  THEN 1 END)::bigint,
      COUNT(CASE WHEN fp.start_date >= date_trunc('year', today)::date THEN 1 END)::bigint,
      COUNT(CASE WHEN fp.start_date >= today - 364 THEN 1 END)::bigint
    FROM flyer_products fp
    WHERE lower(fp.country) = lower(p_country)
      AND fp.start_date >= today - 364
      AND (p_region IS NULL OR fp.coverage_regions ILIKE '%' || p_region || '%')
      AND (p_retailer IS NULL OR fp.mart_name = p_retailer)
      AND (p_category IS NULL OR lower(btrim(fp.category)) = lower(btrim(p_category)))
      AND (p_subcategory IS NULL OR btrim(lower(fp.type)) = lower(btrim(p_subcategory)))
      AND (p_quantity IS NULL OR fp.weight_quantity = p_quantity);
  END IF;
END;
$function$;
