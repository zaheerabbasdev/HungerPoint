# HungerPoint — Project Context for Agents

> Read this first. It is a verified map of the whole monorepo (checked against the code on 2026-10-19).
> For deeper detail see `PROJECT_DOCUMENTATION.md` (root) — but note the caveats in §12: parts of it are stale.

## 1. What this is

HungerPoint is a multi-branch fast-food ordering, delivery, dine-in and restaurant-operations platform
(Islamabad, Pakistan; currency **PKR**; phone numbers in `+92…` format).

**One backend, four clients:**

| Folder | Tech | Users | Purpose |
|---|---|---|---|
| `hpbackend/` | Node 22, TypeScript 5.9, Express 5, Prisma 6.4, MySQL 8, Socket.IO 4.8 | — | REST API `/api/v1`, all business rules, real-time push |
| `hpadmin/` | React 19 + **Vite 8** + react-router 7 + Tailwind 4 + lucide-react | Customers (storefront) + all web staff | Storefront, admin console, Kitchen Display (KDU), POS, reports, settings |
| `hpcustomer/` | Flutter (Dart ^3.10) | Customers | Browse menu, order (delivery/pickup), vouchers, tracking, loyalty, reviews |
| `hprider/` | Flutter | Riders | Claim orders, delivery lifecycle, GPS streaming, handover PIN |
| `hpwaiter/` | Flutter | Waiters | Floor/table view, dine-in orders, reservations, payment & close table |

The web app is **`hpadmin`** (Vite SPA). There is **no `hpweb` / Next.js folder** in the repo,
even though the docs and requirements mention one.

## 2. Repository layout

```
HungerPoint/
├── package.json               # Root delegator: build/start → hpbackend (for hosts needing root package.json)
├── .htaccess                  # Apache SPA rewrite + HTTPS + caching for the built web app (cPanel)
├── build-mobile-release.ps1   # Builds release APK/AAB of all 3 Flutter apps → release/
├── generate_icons.ps1, update_icons.ps1   # App icon generation helpers
├── HUNGERPOINT_REQUIRMENTS.md # Original master spec (aspirational; architecture has since diverged)
├── PROJECT_DOCUMENTATION.md   # Long-form docs: flows, API, DB, deployment, audit, known issues
├── docs/bugs/                 # bugs.md index + BUG-00X-*.md reports (template inside bugs.md)
├── screenshots/               # Customer app UI reference screenshots (jpeg)
├── req/hungerpointdb.sql      # MySQL dump (untracked)
├── .agents/rules/             # Agent rules (see §11)
├── hpbackend/
├── hpadmin/                   # the Vite web app (+ hpadmin-dist.zip = built bundle for upload)
├── hpcustomer/  hprider/  hpwaiter/   # Flutter apps (android/ ios/ web/ lib/ test/; waiter also windows/)
```

## 3. Backend — `hpbackend/`

### Layout
```
src/
├── index.ts              # HTTP server + initSocket + startUnclaimedOrderWatcher, graceful shutdown
├── app.ts                # helmet, /uploads, CORS, rate limits, body parsing, routes, POST /upload, errors
├── config/database.ts    # Prisma singleton; composes DATABASE_URL from DB_* vars when DB_HOST is set
├── config/cors.ts        # apiOrigins()/socketOrigins(): env list + hard-coded production origins
├── middleware/           # auth.middleware.ts (authenticate, optionalAuth, authorize, role shorthands),
│                         # error.middleware.ts (AppError, errorHandler), notFound.middleware.ts
├── sockets/index.ts      # Socket.IO rooms/events + emitTo* helpers
├── jobs/unclaimed-orders.ts  # every 30s: alert admins/branch about READY delivery orders with no rider
├── utils/                # response.ts (sendSuccess/sendError/…), eta.ts, routing.ts (OSRM/TPL), identity.ts
├── prisma/seed.ts        # demo data (not idempotent)
└── modules/<feature>/    # <name>.routes.ts → <name>.controller.ts → <name>.service.ts
prisma/schema.prisma      # 43 models, ~16 enums (MySQL)
scripts/prepare-db.js     # runs before `npm start`: SUPER_ADMIN→ADMIN migration, `prisma db push`, bootstrap admin
uploads/                  # legacy on-disk images (new uploads go to DB table uploaded_files)
```

### Module pattern (follow it for new features)
- **routes**: declare `authenticate` / `authorize(UserRole.X, …)` guards.
- **controller**: read `req`, apply request-level rules (ownership, branch scoping via `req.user.branchId`), call service, respond with `utils/response.ts` helpers.
- **service**: static class methods; business logic + all Prisma access; throw `new AppError(message, status)` for business errors.
- Register new routers in `src/app.ts` under `${API}/<name>`.
- `req.user` = `{ userId, role, branchId? }` (it is **`userId`**, not `id` — see BUG-002).
- Response shape: `{ success: true, message, data, meta? }` / `{ success: false, message, errors? }`.
- Records the user may not see return **404**, not 403.
- `req.body` is normalised to `{}` when empty.

### Modules (mounted at `/api/v1/...`)
`auth, users, customers, branches, categories, products, cart, orders, payments (empty stub), kitchen,
riders, deliveries (folder: delivery), inventory, promotions (empty stub), coupons, reviews, favorites,
settings, loyalty, notifications, reports, tables, reservations` + `POST /upload` (in app.ts).

### Key endpoints (verified from route files)
| Area | Endpoints |
|---|---|
| Auth | `POST /auth/register`, `/login`, `/refresh`, `/logout`; `GET /auth/me`; `PUT /auth/change-password` |
| Users (staff) | `GET/POST /users`, `PUT /users/:id` — ADMIN |
| Branches | `GET /branches[/:id]` public; `GET /branches/nearest?latitude&longitude` public (sorted, with `distanceKm` + `delivers`); `POST`/`DELETE` ADMIN; `PUT` ADMIN, BM |
| Menu | `GET /categories`, `/products`, `/products/addons/all` public; writes ADMIN (+BM for products/variants/addons); deletes ADMIN |
| Orders | `POST/GET /orders`, `GET /orders/:id`, `PATCH /orders/:id/status` (AD,BM,BS,KS,WT — **not riders**), `PATCH /:id/served`, `PATCH /:id/payment` (dine-in finish) |
| Kitchen | `GET /kitchen/queue`, `PATCH /kitchen/orders/:id/prepare` · `/extend` · `/ready` |
| Riders | `GET /riders/me`, `PATCH /riders/status`, `POST /riders/location` (RIDER); `GET/POST/PUT /riders`, `POST /riders/assign` (AD,BM) |
| Deliveries (RIDER) | `GET /deliveries/me/active`, `/me/history`, `/available`; `POST /deliveries/claim/:orderId`; `PATCH /deliveries/:id/release` · `/accept` · `/pickup` · `/out-for-delivery` · `/delivered` · `/failed` |
| Tables / Reservations | `GET /tables`, `/tables/floors`, `/tables/:id`; `POST/PUT` AD,BM; `DELETE` AD; `GET/POST /reservations`, `PATCH /:id/seat`, `/:id/cancel` |
| Customer | `/customers/profile`, `/customers/account`, `/customers/addresses[/:id]`, `GET /customers/search?phone=` (staff) |
| Cart / Favorites | `/cart`, `/cart/items[/:itemId]`; `/favorites[/:productId]` |
| Coupons | `GET /coupons` public (only currently usable ones), `POST /coupons/validate` (optionalAuth — signed-in customer's per-user limit is checked too); `/coupons/admin` + CRUD (AD, BM) |
| Reviews | `GET /reviews/mine`, `GET /reviews/product/:productId`, `POST /reviews` (needs delivered/completed `orderId`), `GET /reviews` + `PATCH /:id/approval` staff |
| Loyalty | `GET /loyalty/me`; staff: `GET /loyalty`, `/loyalty/:customerId`, `POST /loyalty/adjust` |
| Inventory | `GET /inventory/items`, `/inventory/branch/:branchId`; `POST /inventory/items`, `/inventory/stock` |
| Reports | `GET /reports/overview`, `/orders-by-status`, `/orders-by-source`, `/revenue-by-payment`, `/top-products`, `/orders` (`?branchId&from&to&page&pageSize`). Revenue = DELIVERED + COMPLETED orders |
| Upload | `POST /upload` (auth, multipart `image`, stored in DB in 256 KB chunks); `GET /upload/status` (ADMIN: table + MySQL `max_allowed_packet`) |
| Settings | `GET /settings`, `PUT /settings/:key` — ADMIN |
| Notifications | `GET /notifications` (optionalAuth), `PATCH /read-all`, `PATCH /:id/read` |
| Misc | `GET /` and `GET /health` (outside `/api/v1`); `GET /uploads/:filename` (disk first, then DB) |

### Roles (`UserRole` enum) — 7, no SUPER_ADMIN anymore
`ADMIN` (everything, all branches, staff + settings), `BRANCH_MANAGER` (own branch), `BRANCH_STAFF` (POS/orders),
`KITCHEN_STAFF` (KDU only, separate login at web `/kitchen`), `RIDER` (hprider), `WAITER` (hpwaiter), `CUSTOMER`.
SUPER_ADMIN was removed (commit 30c79ef); `prepare-db.js` converts old rows. Docs tables still say "SA" — read as ADMIN.

### Auth
- Email + password everywhere (web admin also accepts phone). **No OTP/SMS** (removed 2026-10-02; Twilio vars in env.example are leftovers).
- JWT access + rotating refresh (stored SHA-256 hashed in `refresh_tokens`). bcrypt 12 rounds.
- `authenticate` reloads the user each request (deactivation is immediate).
- ⚠️ Expired access tokens are still accepted if the user is active (`TokenExpiredError` fallback in `auth.middleware.ts`). Only `hprider` (and the web) refresh on 401; `hpcustomer`/`hpwaiter` do not, so don't remove the fallback without adding refresh there first.
- Rate limits (app.ts): `/api` 1000 (prod) / 2000 (dev) per 15 min; failed logins 20/15 min prod; registrations 30/h prod. Keyed on `CF-Connecting-IP` or `req.ip`.

### Order model & flows
- `OrderType`: DELIVERY, PICKUP, DINE_IN. `OrderSource`: MOBILE_APP, WEBSITE, POS, PHONE, WAITER_APP.
- `OrderStatus`: PENDING, CONFIRMED, ACCEPTED, PREPARING, READY, ASSIGNED, PICKED_UP, OUT_FOR_DELIVERY, DELIVERED, COMPLETED, CANCELLED, REJECTED, PAYMENT_FAILED, REFUNDED.
- Final/locked: DELIVERED, COMPLETED, CANCELLED, REJECTED, REFUNDED (further changes → 400).
- **Delivery:** customer orders (PENDING) → staff confirms (CONFIRMED) → kitchen Start with prep minutes (PREPARING, sets `promisedAt`) → Ready (READY; riders notified `rider.pool_updated`) → a rider **claims** (`/deliveries/claim/:orderId`, first wins via unique `deliveries.orderId`) or admin assigns → accept → pickup → out-for-delivery → delivered (rider enters `cashCollected` and the customer's **4-digit `handoverPin`**). Failed → CANCELLED.
  - `Order.handoverPin` is generated for DELIVERY orders in `order.service.ts`; returned only by `GET /orders/:id` to the customer/admin, **stripped from every rider response** (`sanitizeDeliveryForRider`, `stripPinForRider`) and from **every socket payload** (`stripSecrets` in `sockets/index.ts`).
  - PIN guessing guard: 5 wrong PINs → handover locked 10 min (`handoverPinAttempts`, `handoverPinLockedUntil`), 429, socket `delivery.pin_locked` to admins + branch.
  - Once a delivery exists, `PATCH /orders/:id/status` is blocked; status moves only via `/deliveries`.
  - **Location rules** (`checkDeliveryAddress` in `order.service.ts`): customer DELIVERY orders need an `addressId` owned by that customer; if the address has coordinates it must be within the branch's `deliveryRadius` (haversine km), otherwise 400 naming a branch that does deliver. The customer app picks the nearest delivering branch itself (`BranchService.bestBranchFor`).
  - Admin/BM assignment refuses a rider already ON_DELIVERY; a BM can only assign own-branch orders/riders.
- **Pickup:** same until READY, no fee, no rider; staff mark COMPLETED.
- **Dine-in (waiter):** created CONFIRMED (straight to kitchen; table must belong to the order's branch, branch staff can only order for their own branch), table → OCCUPIED → READY (kitchen sends `waiter.order_ready` to the waiter's `user:` room + saves a Notification; hpwaiter shows a banner on any screen via `ReadyAlertService`) → `PATCH /:id/served` (sets `servedAt`) → `PATCH /:id/payment` (PAID, COMPLETED, frees table, loyalty).
- **Vouchers:** created only by Admin/BM (no runtime demo vouchers — those are in `seed.ts` only). Use is claimed atomically at order time (`CouponService.claimUse`) and given back when the order is CANCELLED/REJECTED.
- **ETA:** `orders/eta.service.ts` + `utils/routing.ts` (OSRM default, TPL optional, straight-line fallback); `orders/calibration.service.ts` self-corrects per branch from last 30 days (median ratios, ≥10 samples, factor 0.8–2x, `ETA_CALIBRATION=off`).
- **Pricing (server only — clients never send prices):** `subtotal = Σ(basePrice + variant.price offset + addons) × qty`; coupon discount; `deliveryFee` = setting `default_delivery_fee` (50, DELIVERY only); `tax = subtotal × default_tax_percent` (5%); `total = subtotal − discount + fee + tax`.
- **Loyalty:** `floor(total/100)` points on DELIVERED/COMPLETED.
- Every status change → `order_status_history` (`changedBy`) + Socket.IO emit.

### Database
- MySQL `hungerpointdb`, Prisma schema in `prisma/schema.prisma`. Schema changes are applied with **`prisma db push`** (no migrations folder); `npm start` pushes automatically without `--accept-data-loss`.
- Money = `Decimal(10,2)` → serialized as **strings**; clients must parse (BUG-007 froze the customer app).
- Domains: Identity (User, RefreshToken, Customer, Address, Favorite, AuditLog), Branches (Branch, BranchHours, DeliveryZone, RestaurantTable, TableReservation), Menu (Category, Product, ProductVariant, ProductFlavour, Addon, ProductAddon, BranchProduct), Cart (Cart, CartItem, CartItemAddon), Orders (Order, OrderItem, OrderItemAddon, OrderStatusHistory), Payments (Payment, PaymentTransaction), Delivery (Rider, RiderLocation, Delivery), Inventory (InventoryItem, InventoryStock, InventoryTransaction, Recipe, RecipeItem, StockTransfer), Marketing (Coupon, Promotion, Review, LoyaltyAccount, LoyaltyTransaction, Notification), System (SystemSetting, UploadedFile).
- `Order.customerId` null = walk-in. `User 1–1 Customer 1–1 LoyaltyAccount`. `Delivery → Rider → User`.

### Real-time (Socket.IO, `src/sockets/index.ts`)
- Connect to API origin (base URL minus `/api/v1`) with `auth: { token }`.
- Auto rooms: `user:{id}`, `role:{ROLE}`; non-riders with a branch also `branch:{branchId}` + `kitchen:{branchId}`; riders only `riders:{branchId}`. `order:{id}` joined via `order:track` **only if allowed** (own order / assigned rider / same-branch staff / admin) — clients must re-emit it on reconnect.
- Client → server: `order:track {orderId}`, `rider:location {latitude, longitude, orderId?}`.
- Server → client: `order.created`, `kitchen.queue_updated`, `order.<status>`, `order.served`, `order.eta_updated`, `order.unclaimed`, `rider.assignment_created`, `rider.pool_updated`, `rider.location_updated` (admins only), `waiter.order_ready`, `delivery.pin_locked`.
- All emit helpers strip `handoverPin`/`password` from payloads; clients re-fetch the order on events.
- Helpers: `emitToUser`, `emitToOrder`, `emitToKitchen`, `emitToBranch`, `emitToAdmins`, `emitToBranchRiders`, `emitToRiders`.

### Commands
```bash
cd hpbackend
npm install            # postinstall → prisma generate
npx prisma db push     # sync schema
npm run prisma:seed    # demo data (re-running fails at sample order)
npm run dev            # tsx watch, http://localhost:5000
npm run build          # prisma generate && tsc → dist/
npm start              # scripts/prepare-db.js && node dist/index.js
npx tsc --noEmit       # type check (no test suite exists)
```
Seed accounts: `+923000000001`…`07` / `Admin@123456` (staff), `+923009999999` / `Customer@123456` (customer). Dev only.

### Env vars (`hpbackend/.env`, template `.env.example`)
`NODE_ENV`, `PORT`, `DATABASE_URL` **or** `DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD` (DB_* win), `JWT_SECRET`, `JWT_REFRESH_SECRET`,
`JWT_EXPIRES_IN`/`JWT_REFRESH_EXPIRES_IN` (30d), `CORS_ORIGIN`, `SOCKET_CORS_ORIGIN`, `RATE_LIMIT_*`, `AUTH_RATE_LIMIT_MAX`, `REGISTER_RATE_LIMIT_MAX`,
`BOOTSTRAP_ADMIN_PHONE/PASSWORD/EMAIL/NAME`, `ROUTING_PROVIDER`, `ROUTING_OSRM_URL`, `TPL_MAPS_API_KEY`, `ROUTING_DAILY_LIMIT_TPL`, `ETA_LIVE_REFRESH_SECONDS`, `ETA_CALIBRATION`, `ETA_CALIBRATION_MIN_SAMPLES`.
- `dotenv` only loads a file named **`.env`**. The untracked `hpbackend/env`, `env.example`, `env.godaddy`, `env.production` (no leading dot) are **not** read by the app. Never print or commit their secrets.
- Production origins always allowed (cors.ts): `https://hungerpoint.eaglesoft.org`, `https://eaglesoft.org`. API: `https://api.eaglesoft.org/api/v1`.

## 4. Web app — `hpadmin/`

- Vite SPA: `src/main.tsx`, `src/App.tsx` (routes, staff pages lazy-loaded), `src/pages/*Page.tsx`,
  `src/components/` (Navbar, CartDrawer, ProductModal, AuthModal, HeroBanner), `src/context/` (AuthContext, CartContext, BranchContext),
  `src/lib/api.ts` (fetch wrapper, token refresh on 401, `resolveImageUrl`, separate `SessionKeys` for admin vs kitchen sessions), `src/lib/socket.ts`.
- Routes: `/` storefront, `/orders/:id` tracking, `/admin` (big: `AdminPage.tsx` ~2800 lines — menu, orders, rider assign, branches), `/kitchen` (KDU, own login), `/pos`, `/branch`, `/inventory`, `/loyalty`, `/promotions` (coupons), `/reports`, `/reviews`, `/riders`, `/tables`, `/settings`.
- Page-level role checks are UX only; backend enforces everything.
- Env: `VITE_API_URL` (default `http://localhost:5000/api/v1`), `VITE_BASE` (`/` or `/hungerpoint/`). Production values in `.env.production`.
- Commands: `npm run dev` (http://localhost:5173), `npm run build` (`tsc -b && vite build` → `dist/`), `npm run lint`.
- Deploy: upload `dist/` contents (incl. `.htaccess`) to cPanel; `hpadmin-dist.zip` is a committed built bundle.
- Styling: Tailwind 4, dark stone/amber theme; colors in `src/index.css`.

## 5. Flutter apps (shared conventions)

- Structure: `lib/main.dart`, `lib/screens/`, `lib/services/` (`api_service.dart` = REST + token storage, `socket_service.dart`), `lib/widgets/`, `lib/constants/app_colors.dart`.
- State: plain services/singletons + `shared_preferences` (no Provider/Bloc). HTTP via `http` package.
- API host via `--dart-define`: `API_BASE_URL` (full URL, wins) or `API_HOST` (default `10.252.184.234`) + `API_PORT` (5000). Socket URL derived from it.
  - Phone on LAN: `flutter run --dart-define=API_HOST=<PC LAN IP>`; emulator: `API_HOST=10.0.2.2`.
  - Release: `.\build-mobile-release.ps1 -ApiUrl https://api.eaglesoft.org/api/v1 [-AppBundle]` (HTTPS required; signed with debug key).
- Token keys: customer `hp_access_token`/`hp_refresh_token`; waiter `hpw_*`.
- Check: `flutter analyze`, `flutter pub get`.

**hpcustomer** — screens: splash, welcome, email_auth, main_navigation (home/explore/branches/vouchers tabs), explore_search, item_detail, cart, payment, order_tracking (shows handover PIN + countdown), order_history, ratings_feedback, favorites, profile/edit_profile_field, saved_addresses/add_address/new_address_form/location_picker (`flutter_map`, `geolocator`), notifications, pickup_branches. Services: address, api, branch (`isPickupMode`), cart, favorites, geocoding, order_payload (builds order lines: productId, variantId, addonIds, quantity, notes), profile, socket. Bill on payment screen is an estimate; server total is authoritative.

**hprider** — screens: splash, login, home (online/offline, upcoming/available orders, claim), active_delivery (lifecycle, navigate via `url_launcher`, cash + PIN entry), history, profile. `location_tracking_service.dart`: 15 m distance filter → socket `rider:location`, `POST /riders/location` every 30 s. Refreshes token on 401.

**hpwaiter** — screens: splash, login, home (floors + table grid), table_order (served → confirm payment & close), menu, item_detail, cart_review, reservation_form/detail, order_history, profile. `table_cart_service.dart` holds per-table carts. Has a `windows/` target.

## 6. Deployment summary
- **Backend:** GoDaddy Node.js app (or Docker: `hpbackend/Dockerfile`, node:22-alpine). Root `package.json` delegates `npm run build`/`npm start` to hpbackend. No terminal on host — `prepare-db.js` syncs schema + bootstraps admin at start. Behind Cloudflare (`trust proxy` in prod).
- **Web:** static build on cPanel (`.htaccess` SPA rewrite).
- **Mobile:** APK/AAB via `build-mobile-release.ps1`.
- `prisma generate` downloads engines from `binaries.prisma.sh`; a transient failure shows as many `TS2305 @prisma/client` errors → just retry.
- TypeScript is pinned to 5.x in backend on purpose. On Windows, a running dev server locks the Prisma engine DLL (EPERM) — stop it before regenerating.

## 7. Known issues / gaps (still open as of 2026-10-20)
1. Expired-token fallback in `auth.middleware.ts`; hpcustomer/hpwaiter lack refresh-on-401.
2. Payments module is a stub (no gateway); `/promotions` empty (coupons used instead).
3. Inventory not deducted by orders (Recipe models unused; `inventory.low_stock` never emitted).
4. Customer app pricing estimate mirrors defaults (5% / PKR 50) and drifts if settings change. Delivery fee is flat (not distance-based).
5. Broadcast notifications share one `isRead` flag. No push notifications (alerts only while an app is open).
6. Seed is not idempotent. No automated test suite in the repo (an end-to-end API script was run manually on 2026-10-20: 86/86 flows passed).

Fixed 2026-10-20: socket `order:track` ownership, PIN leaks over sockets, PIN brute force, voucher cancel/atomic limit/preview mismatch, delivery-radius check, nearest-branch routing, waiter "food ready" alert, revenue missing dine-in/pickup, BM cross-branch rider assignment, manager-without-branch reports.

## 8. Where to look for common tasks
| Task | Start here |
|---|---|
| Change order lifecycle / pricing | `hpbackend/src/modules/orders/order.service.ts`, `order.controller.ts` |
| Kitchen behaviour | `modules/kitchen/kitchen.service.ts`, web `pages/KitchenPage.tsx` |
| Rider / delivery logic, PIN | `modules/delivery/delivery.service.ts`, `modules/riders/rider.service.ts`, `hprider/lib/screens/active_delivery_screen.dart` |
| ETA / routing | `modules/orders/eta.service.ts`, `calibration.service.ts`, `utils/eta.ts`, `utils/routing.ts` |
| Permissions | the module's `*.routes.ts` + controller scoping; `middleware/auth.middleware.ts` |
| Account/identity rules (duplicate email/phone, phone normalisation) | `modules/users/account-identity.ts`, `utils/identity.ts` |
| Branch access checks | `modules/branches/branch-guard.ts` |
| System settings (tax, fee, alert minutes) | `modules/settings/setting.service.ts` (`SettingService.getNumber`) |
| Add a DB field | `prisma/schema.prisma` → `npx prisma db push` → `npx prisma generate` |
| Web admin UI | `hpadmin/src/pages/AdminPage.tsx` |
| Customer ordering UI | `hpcustomer/lib/screens/payment_screen.dart`, `services/order_payload.dart` |
| Brand colours | `*/lib/constants/app_colors.dart`, `hpadmin/src/index.css` |

## 9. Conventions
- TypeScript backend: file banner comments `// ====… // HungerPoint — <Name>`, section comments `// ─── Title ───`, static-class services, `AppError` for 4xx.
- Comments explain *why* (often referencing a past incident). Match that style.
- Keep server as source of truth for prices/status/permissions; clients only display.
- When fixing a bug of note, add `docs/bugs/BUG-XXX-<name>.md` using the template in `docs/bugs/bugs.md` and add a row to the index.
- Update `PROJECT_DOCUMENTATION.md` when behaviour/API changes.

## 10. Recent history (for context)
- 2026-10-19: handover PIN for deliveries ("the pin code fun"), brand colour change across apps, web subfolder/HTTPS fixes (`.htaccess`, `resolveImageUrl`).
- 2026-10-16: app icons. 2026-10-12: reviews feature (order-linked).
- 2026-10-10: kitchen separated from admin (own `/kitchen` login), SUPER_ADMIN removed, waiter app fixes.
- 2026-10-02: OTP/SMS sign-in removed → email + password everywhere.

## 11. Agent rules (from `.agents/rules/`)
- **Do NOT run `git commit` or `git add`.** The user manages all commits.
- Don't print, copy or commit secrets from `env*` / `.env*` files.
- Platform is Windows (PowerShell primary; Git Bash available).

## 12. Doc caveats (PROJECT_DOCUMENTATION.md is partly stale)
- Says `hpweb/` Next.js 16 → actual web app is `hpadmin/` Vite + React Router; `NEXT_PUBLIC_API_URL` → `VITE_API_URL`; kitchen route is `/kitchen`, not `/admin/kitchen`.
- "SA" / Super Admin in its tables → now just `ADMIN`.
- Says uploads are on local disk (§14/§17) → now stored in DB (`UploadedFile`), disk only for legacy files.
- Rider tracking: docs mention a rider map for customers in one place; current flow shows countdown + PIN, rider position is not sent to customers.
- `HUNGERPOINT_REQUIRMENTS.md` describes the original plan (single Next.js `hpweb`, no hpadmin); treat it as product intent, not current architecture.
