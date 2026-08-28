# Follow-ups — things deliberately deferred or worked around

Running list from the full-stack reconciliation pass. Nothing here is
secretly broken — each item is either genuinely blocked on something only
you (or another human with account access) can provide, or was
consciously scoped out to keep that pass focused. Review before showing
this to a client.

## Blocked on you — cannot be done by an AI agent, no way around it

- **Firebase billing.** The project shows Billing Enabled: No. Cloud
  Functions v2 (the entire `backend/functions/` codebase) requires the
  Blaze plan. Nothing deploys until this is on — Firebase Console →
  Usage and billing → upgrade to Blaze.
- **Firebase CLI login.** Needed to actually deploy. This requires a
  human clicking through a Google OAuth consent screen in a real
  browser — there is no non-interactive way around it, and no service
  account can substitute for a first-time interactive login on a
  developer's own tooling.
- **Anonymous Authentication.** Still needs enabling in Firebase Console
  → Authentication → Sign-in method. This is the original "Continue as
  Guest" bug's root cause.
- **Google Maps / Places API key**, and rotating the two keys that were
  leaked in source (a YouTube Data API key hardcoded in
  `youtube_api_service.dart`, and a Places key that was exposed in a code
  comment in `places_service.dart`, now redacted from the comment but the
  actual key value should be revoked/rotated in Google Cloud Console
  regardless). Masjid Finder shows a "coming soon" state until a real key
  is wired in — it no longer shows a broken map.
- **Adhan audio files.** `assets/audio/` has no `.mp3` files, and this
  sandbox has no way to produce or fetch real audio (the only `ffmpeg`
  available here is a video-only build with zero audio codecs; no network
  fetch tool returns binary audio). Preview now tells the user the sound
  isn't available yet instead of silently buzzing, but playback is still
  a no-op until real files are added. You also asked for other small UI
  sounds (tap/success/notification) beyond just the Azan — same blocker,
  not started.
- **Stripe live keys.** Card checkout is deferred per your decision — COD
  is the working path for now. The Stripe UI in `app-web`'s checkout is
  disabled/labeled "Coming soon" rather than removed, so re-enabling it
  later is just flipping that back on once real keys exist.

## Scoped out of this pass — real, but lower priority

- **`admin-panel` is on Next.js 16 while `app-web` is on Next.js 14**
  (also React 18 vs 19, Tailwind 3 vs 4). Not broken, just inconsistent —
  `admin-panel/AGENTS.md` even warns that Next 16 deviates from typical
  AI training data, which is a plausible reason a prior agent's edits to
  that app misbehaved. Worth reconciling versions at some point.
- **No image upload in the admin panel** — products are added via pasted
  image URLs; Storage rules block all client writes and no upload flow
  was ever built. Not broken, just an unbuilt feature.
- **The "Purge Dummy Data" and "Seed Database" buttons in
  `admin-panel/src/app/dashboard/shop/page.tsx`** are wired directly to
  production Firestore behind only a `window.confirm()`. Left as-is since
  it's clearly dev/demo tooling, but worth removing or gating harder
  before this is a real client's day-to-day tool.
- **Silent-failure pattern still exists in a few lower-traffic spots** —
  e.g. `AuthProvider.deleteAccount()`, some `cart_provider.dart` error
  paths — that weren't on the critical demo path. The Adhan/Masjid/Hadith
  ones (the most visible) are fixed; a full sweep of every `catch (e) {
  debugPrint(...) }` site wasn't done.
- **Categories tab and Inventory tab in `admin-panel`'s shop management
  page are hardcoded**, not backed by real Firestore queries. Products
  and Orders tabs are real; these two aren't.
- **`admin-panel`'s order table doesn't display the phone/email now
  captured on each order** — the data is there (backend schema was
  extended for it), just not surfaced in that UI yet.

## Verified fine — no action needed

- `just_audio`, `flutter_local_notifications`, and other native-only
  plugins already degrade correctly (silent no-op on web) except where
  called out above.
- Firestore security rules, Storage rules, and the Cloud Functions
  transactional/idempotent logic (stock decrement, Stripe webhook
  handling) were reviewed and are solid — kept as-is.
