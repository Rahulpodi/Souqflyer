-- get_current_user_permissions()
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Mirrors the PROMO-FINAL folder in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.get_current_user_permissions()
 RETURNS TABLE(allowed_categories text[], allowed_regions text[])
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.categories,
        p.regions
    FROM public.permissions p
    JOIN public.client_users cu ON cu.id = p.client_user_id
    WHERE lower(btrim(cu.email)) = lower(btrim(auth.jwt() ->> 'email'))
    LIMIT 1;
END;
$function$;
