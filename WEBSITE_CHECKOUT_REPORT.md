# Website Checkout Report (2026-10-19)

## A. Root cause
- **Complaint 3 (sent to Stripe's website): confirmed and fixed.** The storefront build never received the Stripe public key (the deploy workflow did not pass it; the live JavaScript contained no `pk_` key). With no key, the checkout code fell back to `createCheckoutSession` and ran `window.location.href = <Stripe hosted page>` (found in the old live `checkout/page-29f78016...js`). That fallback is removed, and the workflow now passes the existing GitHub secret `STRIPE_PUBLISHABLE_KEY` at build time.
- **Complaint 2 (ad / shipping-site redirects): not reproducible and no cause found in our site.** Playwright on the live site (Chromium desktop and WebKit iPhone 14), typing the address character by character, showed 0 off-site navigations, 0 popups and 1 tab. Contacted hosts were only our domain, Stripe (+ Stripe's own hCaptcha), Google/Firebase APIs and Google Fonts. The live HTML and all 16 JS chunks contain no ad, tag-manager, chat or shipping-widget code, no `window.open`, and the only `location.href` write was the Stripe fallback above. Most likely the tester's own phone or browser (ad-injecting app, VPN or DNS filter, adware), or the earlier jump to Stripe's page. I could not prove which. If it happens again, ask for the phone model, browser, and a screen recording.
- **Complaint 1 (COD):** Cash on Delivery was already gone from the storefront after commit cd2eadc (live pages deployed 2026-10-19 21:16 UTC). Crawl of live FAQ, Payment Info, Shipping, Returns, Terms, Privacy and Cancellation pages plus the built output: 0 mentions of COD / Cash on Delivery / Pay on delivery. The backend rejects "cod" (deployed earlier). If the tester still saw it, it was a cached page or an old Flutter/iOS build.

## B. Live vs repo
Live matched the repo for the COD text (deployed by the workflow), but the live build lacked the Stripe key, so the on-page card form never appeared. Now fixed and live (run: https://github.com/galaxa-tech/sunnah-grandeur/actions/runs/39335011313).

## C. Files changed
- `app-web/src/app/checkout/page.tsx` (no redirect to Stripe, card form always on page, default billing country US)
- `app-web/src/components/AppDownloadBanner.tsx` (hidden on every /checkout path)
- `.github/workflows/deploy_storefront.yml` (passes the Stripe key)
- `firebase.json` (security headers on the web target)

## D. How checkout works now
Shipping form (US-only, state list, ZIP/phone/email validation, no country field) -> "Continue to Payment" creates the order (createOrder, card) and a Stripe payment -> Stripe's Payment Element appears on the same page (card first, Apple Pay / Google Pay / Link inside Stripe's own sheet) with "Pay $X.XX". `confirmPayment` uses `redirect: "if_required"`, so 3-D Secure is an in-page Stripe modal; then our own success page. PayPal/Venmo buttons appear only if a PayPal client ID is configured at build time; none is configured today, so they do not show (they were not live before either).

## E. Test results (live site, Playwright)
- Chromium desktop and WebKit iPhone 14: main-frame navigations stayed on sunnahgrandeur.us (only /shop and /checkout), popups = 0, pages = 1, COD text = none.
- Stripe Payment Element mounted on-page in both browsers (before and after the new headers, tested on a preview channel and again live).
- Bad ZIP / phone / name / email are rejected with messages; there is no way to pick a non-US country.
- **No payment was made.** The Stripe key on the site is a LIVE key (`pk_live`); I have no test key, so I did not pay with 4242. Not tested: completing a payment, the success page, and the admin view of a paid order.
- Test orders: my runs created 4 unpaid orders for test@example.com. 3 were deleted. One (`a4af6444d222c141f698`) is still "pending_payment" and will be auto-cancelled by the system within 60 minutes (it also releases the reserved stock); you can delete it in the admin panel after that.
- Temporary preview channel `csp-test` was deleted.

## F. Headers added (web target, all pages)
Content-Security-Policy (default-src self; scripts only from self, js.stripe.com, apis.google.com, gstatic, google recaptcha, paypal; frames only Stripe, Firebase auth, recaptcha, paypal; connect only Stripe, Google/Firebase, cloudfunctions, paypal; object-src none; base-uri self; frame-ancestors none), X-Content-Type-Options nosniff, Referrer-Policy strict-origin-when-cross-origin, Permissions-Policy (camera, mic, geolocation off; payment only self/Stripe/PayPal), X-Frame-Options DENY. Note: script-src still needs `'unsafe-inline'` because the Next.js static export injects inline bootstrap scripts; no wildcard script sources. Remaining external links already use rel="noopener noreferrer".

## G. Suspicious items
Nothing suspicious: package.json is standard, all 527 lockfile packages resolve from registry.npmjs.org, no unknown scripts in source or the built output. Nothing to rotate. (Stripe publishable keys are public by design.)

## H. Live URL checked
https://sunnahgrandeur.us (headers also confirmed on .com). Deploy run: https://github.com/galaxa-tech/sunnah-grandeur/actions/runs/39335011313 (success).

## I. Assumptions
- Admin-panel COD filters: none exist in the admin source. Old COD orders are untouched.
- PayPal left as is (not configured). Admin panel and Flutter app were not changed.
- The Facebook and "Get App / APK" links open in a new tab by design (user-clicked, noopener); the app banner is hidden on checkout.
