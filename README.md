# Flyer Analysis

Retail flyer intelligence for GCC markets (Saudi Arabia, UAE, Qatar, Kuwait, Oman). Scraped supermarket flyers are stored as product rows in Supabase; this repo holds the web app customers use to browse offers and analyse promotions.

## Repo layout

```
Flyer_analysis/
├── marhaba-v4/                 # The web app (React + Vite + Express + Supabase)
│   ├── client/                 # React SPA
│   │   ├── App.tsx             # Routes + protected layout
│   │   ├── pages/              # One file per screen (see below)
│   │   ├── components/layout/  # SiteHeader (logo, nav, theme toggle, user menu)
│   │   ├── components/ui/      # Radix/shadcn UI primitives + Marhaba logo SVG
│   │   ├── context/            # Auth, Theme, Layout React contexts
│   │   ├── utils/              # Pure helpers + their *.spec.ts tests
│   │   └── lib/supabaseClient.ts
│   ├── server/                 # Express app, mounted into Vite in dev, Netlify function in prod
│   │   └── routes/image-proxy.ts   # Sharpens low-res flyer images server-side
│   ├── supabase/migrations/    # SQL for RPCs, indexes, RLS lockdown (run in date order)
│   ├── public/                 # Retailer logos, pivot-template.xlsx for Excel export
│   ├── netlify/functions/api.ts    # Wraps server/ as a Netlify function (/api/*)
│   └── README.md               # Setup, env vars, scripts, troubleshooting
└── credentials_and_costs.md    # LOCAL ONLY — never commit
```

## Screens

| Route | File | What it does |
|-------|------|--------------|
| `/login`, `/verify-otp` | `Login.tsx`, `VerifyOtp.tsx` | Email + OTP sign-in (Supabase Auth) |
| `/` | `Index.tsx` | Launch page: Offer Index / Promotion Analysis cards, client stats |
| `/offer-bank` | `OfferBank.tsx` | Offer grid/table with country, retailer, category, date, brand, pack-size filters; compare, favourites, offer detail, Excel pivot export |
| `/promotion-analysis` | `PromotionAnalysis.tsx` | Promo charts; tabs in `AllBrandActivities.tsx`, `CompetitorPricingAnalysis.tsx`, `PriceTrendAnalysis.tsx` |
| `/saved-filters` | `savedFilters.tsx` | Saved filter sets per user |

## Data flow

1. Scraper uploads flyer crops to S3 (`flyer-image-storage`) and writes rows to Supabase `flyer_products`.
2. The browser never reads `flyer_products` directly — `anon` access is revoked. Pages call Supabase RPCs defined in `supabase/migrations/`.
3. Offer images load from S3. UAE images go through `/api/image-proxy` (a Vercel serverless function in `marhaba-v4/api/`), which upscales and sharpens them — their source crops are the softest.
4. Excel export fills `public/pivot-template.xlsx` with the filtered rows (`client/utils/dataExportWorkbook.ts`); Excel rebuilds the pivots on open.

## Quick start

```bash
cd "marhaba-v4"
npm install
# create .env.local with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
npm run dev        # http://localhost:8080
```

See [`marhaba-v4/README.md`](marhaba-v4/README.md) for scripts, deployment and troubleshooting.
