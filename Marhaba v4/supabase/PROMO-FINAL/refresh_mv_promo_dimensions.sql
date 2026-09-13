-- Refresh Promotion Dimensions
-- Rebuilds the saved copy of dropdown values (categories, brands, subcategories,
-- pack sizes, regions, retailers) from the current flyer_products data.
-- Does not modify any table data.
--
-- Run after EVERY post_ingestion_pipeline.py run, otherwise the dropdowns show
-- stale values. Takes a few seconds; avoid running during an ingestion.

REFRESH MATERIALIZED VIEW public.mv_promo_dimensions;
