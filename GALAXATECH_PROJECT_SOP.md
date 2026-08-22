# GalaxaTech AI Software Development Blueprint (SOP)

This Standard Operating Procedure (SOP) defines GalaxaTech's standard architecture and workflow for building multi-platform digital products (Website, Admin Panel, Mobile App, and Serverless Backend).

---

## 🛠️ The Official GalaxaTech Tech Stack

| Domain | Technology / Platform | Purpose |
| :--- | :--- | :--- |
| **Backend & Cloud** | Firebase (Firestore, Auth, Storage, Cloud Functions v2) | Serverless Database, Auth, Storage, API Functions |
| **Website Storefront** | Next.js (React, TypeScript, TailwindCSS) | High-performance, SEO-optimized Web E-Commerce |
| **Admin Panel** | Next.js (React, TypeScript, TailwindCSS) | Internal management dashboard with 3-tier RBAC |
| **Mobile App** | Flutter Native (Dart) | Single codebase for Android, iOS, and Web |
| **DevOps & Source Code** | GitHub (`galaxa-tech` organization) | Version Control & GitHub Actions CI/CD builds |
| **CDN & Web Hosting** | Firebase Hosting (Multi-Site Targets) | Fast global hosting for Website, Admin, and Web App |
| **Domain & DNS** | Namecheap Advanced DNS | Production domain routing with free SSL |
| **AI Collaboration** | Google Antigravity (AGY) / Gemini AI | Autonomous AI Pair Programming & Architecture |

---

## 📋 The 5-Phase GalaxaTech Development Process

```
[ Phase 1: Architecture Setup ] ──> [ Phase 2: Core Development ] ──> [ Phase 3: Firebase Deployment ]
                                                                                   │
[ Phase 5: Handoff & Maintenance ] <── [ Phase 4: CI/CD & QA Testing ] <───────────┘
```

### Phase 1: Repository & Project Initialization
1. Create a single, unified Git repository under `github.com/galaxa-tech/[project-name]`.
2. Initialize Firebase Project (`gcloud` / Firebase Console) with Firestore, Auth, Storage, and Cloud Functions.
3. Structure the monorepo workspace:
   - `/app-web` (Storefront Website)
   - `/admin-panel` (Admin Dashboard)
   - `/app-mobile` (Flutter Mobile App)
   - `/backend` (Cloud Functions v2, Security Rules, Indexes)

### Phase 2: Role-Based Security & Core Features
1. Implement 3-tier Role-Based Access Control (RBAC):
   - `superAdmin`: Full system control & role assignment.
   - `admin`: Operations, inventory, and order management.
   - `employee` / `user`: End-user access.
2. Build reactive Auth Providers (`AuthContext` / `AuthModal`) shared across products.
3. Implement core features (Products, Cart, Cash on Delivery, Profile, Order History).

### Phase 3: Firebase Multi-Site Hosting
1. Configure Firebase Multi-Site hosting in `firebase.json`:
   - Target `web` → Storefront Website (`[project].web.app`)
   - Target `admin` → Admin Panel (`[project]-admin.web.app`)
   - Target `app` → Mobile Web App (`[project]-app.web.app`)
2. Deploy Security Rules (Firestore & Storage) and Composite Indexes.
3. Execute single-command deployment:
   ```bash
   firebase deploy
   ```

### Phase 4: CI/CD Pipeline & Subordinate QA Testing
1. Configure GitHub Actions workflow (`.github/workflows/build_app.yml`) to compile Android `.apk` and `.aab` release binaries automatically on every `git push`.
2. Generate Subordinate QA Guide (`subordinate_qa_guide.md`) with test cases for Web, Admin, and Mobile.
3. Upload release APK to APKPure Developer Console for Android distribution.

### Phase 5: Production Custom Domain & API Key Handoff
1. Add Namecheap Advanced DNS A / CNAME records to bind custom domain & subdomains:
   - `domain.com` → Storefront Website
   - `admin.domain.com` → Admin Panel
   - `app.domain.com` → Mobile Web App
2. Inject live payment & third-party API keys (Stripe, YouTube, Google Maps) into `backend/functions/.env`.
