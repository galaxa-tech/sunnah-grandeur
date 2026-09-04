# Architecture — canonical sources

This project previously had duplicate implementations of several things,
and the wrong one was silently the one actually deployed in more than one
case. This file exists so that doesn't happen again. If you're an AI
agent or a new contributor about to touch deploy config, backend logic,
or the storefront: read this first.

## One Firebase config

There is exactly **one** `firebase.json`, at the repo root. There is no
`backend/firebase.json` — it used to exist, pointed the same hosting
target at a different build than the root config, and was deleted.
Don't recreate it.

- **Hosting**
  - `web` → `app-web/out` — the customer storefront (Next.js static export)
  - `admin` → `admin-panel/out` — the admin dashboard (Next.js static export)
  - `app` → `app-mobile/build/web` — the Flutter app's web build
- **Firestore rules/indexes** → `backend/firestore.rules`, `backend/firestore.indexes.json`
- **Storage rules** → `backend/storage.rules`
- **Cloud Functions** → `backend/functions/` (see below)

## One Cloud Functions codebase: `backend/functions/`

There used to be a second, much thinner Cloud Functions implementation at
the repo-root `functions/` (2 functions: Stripe checkout only). It was
what was actually deployed, while `backend/functions/` — the real,
20-function implementation the mobile app and admin panel both expect
(`createOrder`, `createUserMetadata`, `updateOrderStatus`, media sync,
etc.) — sat unused. The root `functions/` stub is deleted. Don't recreate
functions outside `backend/functions/`.

Inside `backend/functions/src/`, functions are organized by domain under
`domains/` (`orders`, `users`, `products`, `payments`, `media`, `hadiths`,
`admin`) and wired up in `backend/functions/index.js`. If you add a new
Cloud Function, put it in the matching domain folder and export it from
`index.js` — don't add flat files to `src/` directly (there used to be a
parallel, unused set of those too; they were deleted).

## One storefront: `app-web/`

`website/` used to be a second, earlier, unwired copy of the storefront
(not referenced by `firebase.json`, missing `output: 'export'`, missing
the Stripe/COD checkout logic `app-web` has). It's deleted. `app-web/` is
the only storefront.

## One admin surface: `admin-panel/`

`app-web` used to have a second, hidden admin surface at
`/admin/orders` with a password bypass (any password over 5 characters
granted access). It's deleted. `admin-panel/` (hosted at the `admin`
target) is the only admin interface, gated by real Firebase Auth + custom
claims (`admin` or `superAdmin` role).

## Writing an order

Never write directly to `/orders` from client code — Firestore rules
block it (`allow create, update, delete: if false`). Order creation goes
through the `createOrder` Cloud Function (prices, tax, and stock are
computed/decremented server-side); order status changes go through
`updateOrderStatus` (admin-only). Both live in
`backend/functions/src/domains/orders/index.js`.
