# hpadmin — HungerPoint Web (React + Vite)

React + Vite version of `hpweb`: the customer storefront and the full staff console (admin, KDU, POS, branch, riders, inventory, promotions, reviews, loyalty, reports, settings). It talks to the same backend API.

## Develop

```bash
npm install
npm run dev          # http://localhost:5173 — uses the local backend (http://localhost:5000/api/v1)
```

The local backend must run with `NODE_ENV=development`, because production mode only allows the configured web domains (CORS).

## Build

```bash
npm run build        # → dist/
```

Settings come from `.env.production`:

| Variable | Meaning |
|---|---|
| `VITE_API_URL` | Backend API, e.g. `https://api.eaglesoft.org/api/v1` |
| `VITE_BASE` | Where the site is hosted: `/` for its own (sub)domain, `/hungerpoint/` for a subfolder |

## Deploy (GoDaddy cPanel / any static host)

1. Set `VITE_BASE` to match where you'll upload, then run `npm run build`.
2. Upload the **contents** of `dist/` into that folder. This includes `.htaccess`, which forces HTTPS and sends every page URL (`/admin`, `/pos`, …) to `index.html`. Turn on "Show hidden files" in File Manager to see it.
3. The site's origin must be in the backend's `CORS_ORIGIN` and `SOCKET_CORS_ORIGIN` secrets:
   - `https://hungerpoint.eaglesoft.org` for the subdomain
   - `https://eaglesoft.org` for the `/hungerpoint/` subfolder

## Routes

| Path | Page |
|---|---|
| `/` | Storefront |
| `/orders/:id` | Live order tracking |
| `/admin` | Staff login + admin console |
| `/admin/kitchen` | Kitchen Display Unit |
| `/pos`, `/branch`, `/riders`, `/inventory`, `/promotions`, `/reviews`, `/loyalty`, `/reports`, `/settings` | Staff modules |

Every page except the storefront is lazy-loaded, so customers don't download the admin console.
