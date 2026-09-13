-- get_promo_subcategories_by_category(p_country text, p_category text)
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_promo_subcategories_by_category(p_country text, p_category text)
 RETURNS TABLE(subcategory_name text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
  RETURN QUERY
  SELECT DISTINCT dimension_value
  FROM mv_promo_dimensions
  WHERE country_key = lower(p_country)
    AND dimension_type = 'subcategory'
    AND lower(btrim(parent_category)) = lower(btrim(p_category))
  ORDER BY dimension_value;
END;
$function$;
