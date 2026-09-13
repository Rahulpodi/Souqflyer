# Supabase SQL

Everything the app needs in the database, exported live on 2026-09-13. Folder names match the Supabase SQL editor. **Edit here first, then paste into the matching Supabase snippet** so the two never drift.

`migrations/` is history only — older files there no longer match live.

To rebuild the Supabase folders: create one snippet per file below and paste the file in. **Don't run them** — the database already has all of this. (Running is harmless: functions are `CREATE OR REPLACE`, grants and `IF NOT EXISTS` indexes are idempotent — but `REFRESH` and index creation take time.)

## Offerbank/

| File | What it is | Used by |
|---|---|---|
| `get_offers_filtered_paged.sql` | Offer search + paging | Offer Bank |
| `get_current_user_permissions.sql` | User's allowed categories/regions | Offer Bank, Promo |
| `safe_num.sql` | Text → number helper | Called by `get_offers_filtered_paged` |
| `permissions.sql` | Who may run the functions above | — |
| `flyer_products_indexes.sql` | All 90 indexes on `flyer_products` (record) | All queries |

## PROMO-FINAL/

| File | What it is | Used by |
|---|---|---|
| `get_promotion_analysis_stats_multi.sql` | Share of activity, averages | Promo Analysis |
| `get_per_competitor_stats.sql` | Per-brand breakdown | Promo Analysis |
| `get_market_totals.sql` | Market totals (7-input version) | Promo Analysis |
| `get_promo_brands_by_category.sql` | Brand dropdown | Promo Analysis |
| `get_promo_subcategories_by_category.sql` | Subcategory dropdown | Promo Analysis |
| `get_promo_pack_sizes_by_category.sql` | Pack size dropdown | Promo Analysis |
| `get_flyer_products_detail.sql` | Offer rows (version with `p_from_date`) | Promo sub-tabs, Price Trend |
| `mv_promo_dimensions.sql` | Dropdown view + its indexes (reference — don't recreate) | All filter dropdowns |
| `refresh_mv_promo_dimensions.sql` | **Run after every pipeline ingestion** | — |
| `permissions.sql` | Who may run the functions / read the view | — |

## COMPETITOR/

| File | What it is | Used by |
|---|---|---|
| `get_competitor_pricing_aggregations.sql` | Average prices per brand | Competitor Pricing |
| `get_competitor_pack_aggregations.sql` | Price ranges per pack | Competitor Pricing |
| `get_retailer_activity.sql` | Offers per retailer | Competitor Pricing |
| `permissions.sql` | Who may run the functions above | — |

## Old snippets not needed any more

`get_offerbank_filters_remast`, "Drop Competitor Stats Functions", "Drop and Recreate Public Functions" (**never re-run** — restores the old broken versions), and the duplicate "Competitor Pack Price Aggregations" in PROMO-FINAL.

## ⚠️ Security notes (found in live grants, not changed)

1. `get_competitor_pack_aggregations` can be run **without logging in** (granted to `PUBLIC`/`anon`). Fix is commented at the bottom of `COMPETITOR/permissions.sql`.
2. `mv_promo_dimensions` lets anyone trigger an expensive `REFRESH` (`MAINTAIN` privilege for `anon`/`authenticated`). Fix is commented at the bottom of `PROMO-FINAL/permissions.sql`.

## What changed on 2026-09-13

The pipeline now stores `category`, `type` and `country` in sentence case (`Cheese`, `Saudi arabia`, `Uae`). Only comparisons inside the queries changed, so they match any casing:

```sql
fp.category = v_category   ->  lower(btrim(fp.category)) = v_category
fp.type = p_subcategory    ->  btrim(lower(fp.type)) = lower(btrim(p_subcategory))
fp.country = v_country     ->  lower(fp.country) = v_country
```

No table data was changed.
