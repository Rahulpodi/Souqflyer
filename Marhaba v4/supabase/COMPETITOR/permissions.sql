-- Permission Grants for Pricing
-- Live grants exported from Supabase on 2026-09-13 (source of truth).
-- Re-running this is safe: GRANT is idempotent.

GRANT EXECUTE ON FUNCTION public.get_competitor_pricing_aggregations(text, text, text, text, text, text[], text, boolean, integer) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_retailer_activity(text, text, text[], text[], text[], text[], boolean)                       TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_competitor_pack_aggregations(text, text, text, text, text, text[], text, boolean, integer)    TO authenticated, service_role;

-- ⚠️ SECURITY NOTE (not applied): live, get_competitor_pack_aggregations is ALSO
-- executable by PUBLIC and anon — anyone with the public API key can call it
-- without logging in and read pricing data. Every other app query is locked to
-- logged-in users. Recommended fix; review, then run manually:
--
-- REVOKE EXECUTE ON FUNCTION public.get_competitor_pack_aggregations(text, text, text, text, text, text[], text, boolean, integer) FROM PUBLIC, anon;
