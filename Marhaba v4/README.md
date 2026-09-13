# Marhaba v4 — Offer index & analytics (React + Vite)

**Marhaba v4** is the main **customer-facing** web app: **Supabase-backed** pages for flyer offers, promotion analysis, saved filters, and **email OTP login**. The dev server runs **Vite** and mounts a small **Express** app as middleware so API routes like `/api/ping` and `/api/demo` work on the **same origin** as the SPA during development.

---

## What the app does (high level)

- **Authentication** — `/login` and `/verify-otp` use Supabase Auth (OTP). Most routes are behind a **protected** layout.
- **Home (`/`)** — Landing cards that link into the main tools.
- **Offer Bank (`/offer-bank`)** — Browse/filter offers; uses Supabase RPCs and tables (e.g. offer bank helpers, `flyer_products`-related flows).
- **Promotion analysis (`/promotion-analysis`)** — Charts and comparisons; heavy use of Supabase RPCs and `flyer_products`.
- **Saved filters (`/saved-filters`)** — Persisted filter UX for logged-in users.

Client code lives under **`client/`** (React, React Router, TanStack Query, Tailwind, Radix UI). Shared types/utilities can live under **`shared/`**. Server entry for dev middleware is **`server/`** (`createServer()` used from `vite.config.ts`).

---

## Prerequisites

- **Node.js** (LTS; **v20+** is a safe choice for modern Vite)
- **pnpm** is declared in `package.json` (`packageManager` field). You can use **npm** instead if you adjust install commands.
- A **Supabase** project with the same schema/RPCs the pages expect (anon key on the client; RLS policies must allow your users to run the RPCs you call).

---

## Configuration

Create **`.env`** in **`Marhaba v4/`** (project root, next to `package.json`). The client reads **Vite** variables:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

Optional server-side demo/config (used by `server/index.ts`):

```env
PING_MESSAGE=ping
```

Restart the dev server after changing `.env`.

> Do **not** commit real keys. Keep `.env` gitignored.

---

## How to run (local)

From **`Frontend/Marhaba v4`** (this folder):

**Using pnpm (recommended by package.json):**

```bash
pnpm install
pnpm dev
```

**Using npm:**

```bash
npm install
npm run dev
```

- Dev server: **port 8080** (see `vite.config.ts`, `host: "::"`).
- Express middleware is only wired in **serve** mode (`expressPlugin` in `vite.config.ts`), so **`pnpm dev` / `npm run dev`** gives you Vite + API on one port.

Open **`http://localhost:8080`** (or the URL Vite prints).

---

## Other scripts

| Command | Purpose |
|---------|---------|
| `npm run build` / `pnpm build` | Builds client (`dist/spa`) and server bundle (`dist/server`). |
| `npm run start` / `pnpm start` | Runs production Node server: `node dist/server/node-build.mjs`. |
| `npm run typecheck` | TypeScript check. |
| `npm run test` | Vitest once. |

For production, build first, then start; serve `dist/spa` static files according to your hosting (the exact deployment shape depends on how you host the server bundle).

---

## Folder map

| Path | Role |
|------|------|
| **`client/`** | React app entry (`App.tsx`, `pages/`, `components/`, `lib/supabaseClient.ts`). |
| **`client/utils/`** | Pure helpers with Vitest specs: `offerBankUtils` (filters, currency, `enhancedImageUrl`), `promotionAnalysisUtils`, `dataExportWorkbook` (Excel pivot export). |
| **`server/`** | Express `createServer()` — routes `/api/ping`, `/api/demo`, `/api/image-proxy`. |
| **`server/routes/image-proxy.ts`** | Fetches a flyer image from the allow-listed S3 bucket, upscales + sharpens it with `sharp`. Used for all non-Saudi offer images. |
| **`supabase/Offerbank/`, `supabase/PROMO-FINAL/`, `supabase/COMPETITOR/`** | **Current live definition of every query the app calls**, one file per function. Folder names match the Supabase SQL editor. See [`supabase/README.md`](supabase/README.md) for which snippet maps to which file. Edit here first, then paste into Supabase. |
| **`supabase/migrations/`** | Historical change log (RPCs, indexes, RLS/grant lockdown). Older files had drifted from live — trust `PROMO-FINAL/` for the current query text. |
| **`public/pivot-template.xlsx`** | Template workbook for Data Export — its 5 pivot tables are refreshed from the exported rows on open. |
| **`netlify/functions/api.ts`** | Runs the same Express app as a Netlify function; `netlify.toml` routes `/api/*` to it. |
| **`shared/`** | Code shared between client and server (types, helpers). |
| **`vite.config.ts`** | Vite + React; dev-only Express plugin. |
| **`vite.config.server.ts`** | Separate build for the server entry. |

---

## Troubleshooting

| Issue | What to check |
|--------|----------------|
| Blank app / Supabase errors | `VITE_SUPABASE_*` set? Restart dev server after editing `.env`. |
| Login works but data empty | RLS policies and RPC grants on Supabase for the logged-in user. |
| Port already in use | Change port in `vite.config.ts` `server.port` or stop the other process. |
| Offer images broken / not sharpened | `/api/image-proxy` needs the Express server: works in `npm run dev` and on Netlify (`sharp` listed in `external_node_modules`). Vercel has no `/api` wiring. |
| "canceling statement due to statement timeout" | Offer Bank query too broad for the DB timeout — narrow filters, check `20260711_flyer_products_indexes.sql` is applied. |
| All Countries export returns nothing | Run `supabase/migrations/20260802_detail_rpc_all_countries.sql` on the live DB. |

This README describes **Marhaba v4** as laid out in **`Frontend/Marhaba v4`**. Backend RPC and table names must match your Supabase project.
