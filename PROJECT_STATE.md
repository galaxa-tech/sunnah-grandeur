# Sunnah Grandeur — Master Project State & Recovery Guide

**Conversation ID**: `f9cc25c9-27e6-457f-9a78-7b1c191da802`  
**Workspace Root**: `c:\Users\Admin\.antigravity\Sunnah Grandeur`  
**Official GitHub Repository**: `https://github.com/galaxa-tech/sunnah-grandeur`  
**Firebase Project ID**: `sunnah-grandeur`  
**Last Updated**: Saturday, August 22, 2026

---

## 🌐 Live Firebase Hosting URLs
- **Storefront Website**: [https://sunnah-grandeur.web.app](https://sunnah-grandeur.web.app) (Target: `sunnahgrandeur.com` / `www.sunnahgrandeur.com`)
- **Admin Panel**: [https://sunnah-grandeur-admin.web.app](https://sunnah-grandeur-admin.web.app) (Target: `admin.sunnahgrandeur.com`)
- **Mobile Web App**: [https://sunnah-grandeur-app.web.app](https://sunnah-grandeur-app.web.app) (Target: `app.sunnahgrandeur.com`)

---

## 🔑 Pending Production API Keys (To Be Integrated When Provided)
1. **Stripe Payment Gateway API**:
   - `STRIPE_SECRET_KEY` (Production Stripe Secret Key)
   - `STRIPE_WEBHOOK_SECRET` (Stripe Webhook Endpoint Secret)
   - *Note*: Cash on Delivery (COD) is live. Card checkout functions are built & deployed, awaiting live keys in `backend/functions/.env`.
2. **YouTube Data API v3**:
   - `YOUTUBE_API_KEY` (Google Cloud YouTube API Key for auto-syncing Islamic media/lectures)
   - *Note*: Functions `sync.js` and `getMedia` are built & deployed, awaiting live key in `backend/functions/.env`.
3. **Google Maps SDK**:
   - `MAPS_ANDROID_KEY` (Google Maps API Key for location lookup & Masjid Finder)

---

## 👑 Team User Roles & Accounts
- **`sunnahgrandeur.nyc@gmail.com`** → **`superAdmin`** (Firebase Auth custom claim + Firestore user document)
- **`talharrc@gmail.com`** → **`admin`**
- **`rihadhamid20@gmail.com`** → **`admin`**

---

## 📁 Repository & Directory Layout
```
c:\Users\Admin\.antigravity\Sunnah Grandeur\
├── admin-panel/        # Admin Panel Dashboard (Next.js 16)
├── app-mobile/         # Flutter Native Mobile App & Web Release
├── app-web/            # Storefront Website (Next.js 14)
├── backend/            # Cloud Functions v2, Firestore Rules, Storage Rules, Indexes
├── firebase.json       # Root Multi-Site Hosting Configuration
└── .github/workflows/  # build_app.yml (Automated Mobile APK / AAB builds)
```

---

## 🔄 How to Resume Work in Antigravity IDE
If Antigravity IDE closes or restarts:
1. Open this workspace folder (`Sunnah Grandeur`).
2. Start a new chat prompt and say:
   > *"Read `PROJECT_STATE.md` and resume from conversation `f9cc25c9-27e6-457f-9a78-7b1c191da802`."*
3. The AI assistant will instantly read this file and the saved transcript, restoring 100% of the project context!
