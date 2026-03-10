apps/insighthunter-main/
│
├── src/
│   ├── pages/
│   │   ├── index.astro                     # Marketing homepage — "Stop Flying Blind"
│   │   ├── pricing.astro                   # Pricing tiers page
│   │   ├── about.astro
│   │   ├── contact.astro
│   │   ├── 404.astro
│   │   │
│   │   ├── features/
│   │   │   ├── index.astro                 # Features overview
│   │   │   ├── bookkeeping.astro
│   │   │   ├── bizforma.astro
│   │   │   ├── insight-lite.astro
│   │   │   ├── insight-standard.astro
│   │   │   ├── insight-pro.astro
│   │   │   ├── scout.astro
│   │   │   ├── pbx.astro
│   │   │   ├── payroll.astro
│   │   │   └── website-services.astro
│   │   │
│   │   ├── dashboard/
│   │   │   ├── index.astro                 # Dashboard home — KPI overview
│   │   │   ├── reports.astro               # P&L, cash flow reports
│   │   │   ├── forecast.astro              # Cash flow forecasting
│   │   │   ├── bookkeeping.astro           # Bookkeeping module entry
│   │   │   ├── bizforma.astro              # BizForma entry (formation cases)
│   │   │   ├── insights.astro              # AI CFO insights feed
│   │   │   ├── settings.astro              # Org & account settings
│   │   │   └── upgrade.astro               # Upsell / tier management
│   │   │
│   │   └── auth/
│   │       ├── login.astro
│   │       ├── register.astro
│   │       ├── forgot-password.astro
│   │       └── callback.astro              # OAuth callback handler
│   │
│   ├── layouts/
│   │   ├── MarketingLayout.astro           # Public pages — meta, CF analytics, nav, footer
│   │   ├── DashboardLayout.astro           # Auth-gated — sidebar, topbar, session check
│   │   └── AuthLayout.astro               # Login/register wrapper
│   │
│   ├── components/
│   │   ├── marketing/
│   │   │   ├── Hero.astro
│   │   │   ├── FeatureGrid.astro
│   │   │   ├── PricingTable.astro
│   │   │   ├── Testimonials.astro
│   │   │   ├── CTABanner.astro
│   │   │   ├── AppCard.astro               # Individual product card (sand/taupe theme)
│   │   │   └── Nav.astro
│   │   │
│   │   ├── dashboard/
│   │   │   ├── Sidebar.svelte
│   │   │   ├── TopBar.svelte
│   │   │   ├── KPICard.svelte
│   │   │   ├── RevenueChart.svelte
│   │   │   ├── CashFlowChart.svelte
│   │   │   ├── InsightCard.svelte
│   │   │   ├── ActivityFeed.svelte
│   │   │   └── QuickActions.svelte
│   │   │
│   │   ├── auth/
│   │   │   ├── LoginForm.svelte
│   │   │   ├── RegisterForm.svelte
│   │   │   └── ForgotPasswordForm.svelte
│   │   │
│   │   └── shared/
│   │       ├── Button.astro
│   │       ├── Badge.astro
│   │       ├── Modal.svelte
│   │       ├── Toast.svelte
│   │       ├── Spinner.svelte
│   │       └── EmptyState.astro
│   │
│   ├── data/
│   │   ├── apps.ts                         # App registry — name, slug, description, tier, route
│   │   ├── pricing.ts                      # Tier definitions, feature flags, prices
│   │   ├── features.ts                     # Feature list per tier
│   │   └── navigation.ts                   # Sidebar nav config
│   │
│   ├── lib/
│   │   ├── auth.ts                         # Client-side session helpers, token storage
│   │   ├── api.ts                          # Typed fetch wrapper → insighthunter-auth / workers
│   │   ├── analytics.ts                    # CF Analytics Engine + page view helpers
│   │   └── pwa.ts                          # Service worker registration
│   │
│   ├── types/
│   │   ├── index.ts                        # Re-exports
│   │   ├── auth.ts                         # AuthUser, Session, OrgContext
│   │   ├── apps.ts                         # AppDefinition, Tier, FeatureFlag
│   │   └── api.ts                          # API response shapes
│   │
│   ├── styles/
│   │   ├── globals.scss                    # CSS reset, root variables
│   │   ├── theme.scss                      # Sand/taupe color palette, typography
│   │   ├── dashboard.scss
│   │   └── marketing.scss
│   │
│   └── middleware/
│       └── index.ts                        # Astro middleware — session validation, redirects
│
├── public/
│   ├── favicon.ico
│   ├── favicon.svg
│   ├── logo.svg
│   ├── manifest.webmanifest               # PWA manifest
│   ├── icons/                             # PWA icon sizes (72→512)
│   ├── og/                                # Open Graph images per page
│   ├── fonts/
│   └── features/                          # Legacy static HTML feature pages
│       ├── bizforma.html
│       ├── bookkeeping.html
│       ├── insight-lite.html
│       ├── insight-pro.html
│       ├── insight-standard.html
│       ├── pbx.html
│       ├── scout.html
│       └── website-services.html
│
├── functions/
│   └── api/
│       └── [[path]].ts                    # Cloudflare Pages Function — proxies to Workers
│
├── sw/
│   ├── sw.ts                              # Service worker — offline, background sync
│   └── precache.ts                        # PWA precache manifest
│
├── tests/
│   ├── pages/
│   │   ├── index.test.ts
│   │   └── dashboard.test.ts
│   ├── lib/
│   │   └── auth.test.ts
│   └── fixtures/
│       └── mockSession.ts
│
├── astro.config.mjs                       # Astro config — Cloudflare adapter, Svelte, Sitemap
├── wrangler.jsonc                         # Cloudflare Pages + Worker bindings
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.ts                     # (if using Tailwind alongside SCSS)
└── README.md
