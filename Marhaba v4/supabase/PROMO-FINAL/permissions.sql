-- Promo Analytics Permissions
-- Live grants exported from Supabase on 2026-09-13 (source of truth).
-- Re-running this is safe: GRANT is idempotent.

GRANT EXECUTE ON FUNCTION public.get_promotion_analysis_stats_multi(text, text, text[], text, text, text, text, text, boolean) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_per_competitor_stats(text, text[], text, text, text, text, text, boolean)                  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_market_totals(text, text, text, text, text, text, boolean)                                 TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_promo_brands_by_category(text, text)                                                        TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_promo_subcategories_by_category(text, text)                                                 TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_promo_pack_sizes_by_category(text, text)                                                    TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_flyer_products_detail(text, text, text, text, text, text, date, integer)                    TO authenticated, service_role;

-- Dropdown view: the app only needs SELECT for logged-in users.
GRANT SELECT ON public.mv_promo_dimensions TO authenticated, service_role;

-- ⚠️ SECURITY NOTE (not applied): live, anon and authenticated also hold
-- MAINTAIN on this view (Postgres 17), which lets any caller — even without
-- logging in — run REFRESH MATERIALIZED VIEW (an expensive full-table rebuild).
-- Recommended fix; review, then run manually:
--
-- REVOKE ALL ON public.mv_promo_dimensions FROM anon;
-- REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN
--   ON public.mv_promo_dimensions FROM authenticated;
