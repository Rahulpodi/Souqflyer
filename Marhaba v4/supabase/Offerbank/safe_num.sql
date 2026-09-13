-- safe_num(val text)  —  Supabase snippet: "Safe Text-to-Numeric Conversion"
-- Live definition exported from Supabase on 2026-09-13 (source of truth).
-- Unchanged by the 2026-09-13 category fix.

CREATE OR REPLACE FUNCTION public.safe_num(val text)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
    cleaned text;
BEGIN
    IF val IS NULL OR trim(val) = '' THEN
        RETURN NULL;
    END IF;
    -- Remove commas, currency symbols, and other non-numeric text except dot and digits
    cleaned := regexp_replace(val, '[^\d.]', '', 'g');
    RETURN cleaned::numeric;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$function$;
