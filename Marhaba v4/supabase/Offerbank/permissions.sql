-- Offer Bank permissions
-- Live grants exported from Supabase on 2026-09-13 (source of truth).
-- Re-running this is safe: GRANT is idempotent.

GRANT EXECUTE ON FUNCTION public.get_offers_filtered_paged(text, text[], text[], text[], text[], text[], text[], text, date, date, boolean, integer, integer) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_current_user_permissions() TO authenticated, service_role;

-- safe_num is a pure text->number helper (no data access); it is executable by
-- PUBLIC, which is harmless and left as-is.
GRANT EXECUTE ON FUNCTION public.safe_num(text) TO PUBLIC;
