#!/bin/bash
source "$(dirname "$0")/lib/scaffold-utils.sh"
ROOT="apps/insighthunter-main"
echo "🔧 $ROOT"

mkdir -p $ROOT/public/icons
mkdir -p $ROOT/src/styles
mkdir -p $ROOT/src/layouts
mkdir -p $ROOT/src/pages/{auth,dashboard,admin,account,shop,features,marketing/blog,marketing/legal,api/auth,api/quickbooks}
mkdir -p $ROOT/src/components/ui
mkdir -p $ROOT/src/components/islands/{auth,dashboard,shop,shared}

# root config
safe_file $ROOT/astro.config.mjs
safe_file $ROOT/wrangler.toml
safe_file $ROOT/svelte.config.js
safe_file $ROOT/package.json
safe_file $ROOT/tsconfig.json

# public
safe_file $ROOT/public/.assetsignore
safe_file $ROOT/public/favicon.ico
safe_file $ROOT/public/manifest.webmanifest
safe_file $ROOT/public/robots.txt
safe_file $ROOT/public/icons/icon-192.png
safe_file $ROOT/public/icons/icon-512.png

# src root
safe_file $ROOT/src/env.d.ts

# styles
safe_file $ROOT/src/styles/styles.css
safe_file $ROOT/src/styles/marketing.css
safe_file $ROOT/src/styles/dashboard.css

# layouts
safe_file $ROOT/src/layouts/Layout.astro
safe_file $ROOT/src/layouts/DashboardLayout.astro
safe_file $ROOT/src/layouts/MarketingLayout.astro

# pages — top level
safe_file $ROOT/src/pages/index.astro
safe_file $ROOT/src/pages/about.astro
safe_file $ROOT/src/pages/features.astro
safe_file $ROOT/src/pages/pricing.astro
safe_file $ROOT/src/pages/docs.astro
safe_file $ROOT/src/pages/support.astro

# pages — auth
safe_file $ROOT/src/pages/auth/login.astro
safe_file $ROOT/src/pages/auth/signup.astro
safe_file $ROOT/src/pages/auth/logout.astro

# pages — dashboard
safe_file $ROOT/src/pages/dashboard/index.astro
safe_file $ROOT/src/pages/dashboard/bookkeeping.astro
safe_file $ROOT/src/pages/dashboard/clients.astro
safe_file $ROOT/src/pages/dashboard/compliance.astro
safe_file $ROOT/src/pages/dashboard/reconciliation.astro
safe_file $ROOT/src/pages/dashboard/reports.astro
safe_file $ROOT/src/pages/dashboard/settings.astro

# pages — admin
safe_file $ROOT/src/pages/admin/index.astro
safe_file $ROOT/src/pages/admin/compliance.astro

# pages — account
safe_file $ROOT/src/pages/account/index.astro
safe_file $ROOT/src/pages/account/billing.astro

# pages — shop
safe_file $ROOT/src/pages/shop/index.astro
safe_file $ROOT/src/pages/shop/checkout.astro
safe_file $ROOT/src/pages/shop/success.astro

# pages — features
safe_file $ROOT/src/pages/features/bizforma.astro
safe_file $ROOT/src/pages/features/bookkeeping.astro
safe_file $ROOT/src/pages/features/insight-lite.astro
safe_file $ROOT/src/pages/features/insight-pro.astro
safe_file $ROOT/src/pages/features/insight-standard.astro
safe_file $ROOT/src/pages/features/pbx.astro
safe_file $ROOT/src/pages/features/scout.astro
safe_file $ROOT/src/pages/features/website-services.astro

# pages — marketing
safe_file $ROOT/src/pages/marketing/index.astro
safe_file $ROOT/src/pages/marketing/about.astro
safe_file $ROOT/src/pages/marketing/contact.astro
safe_file $ROOT/src/pages/marketing/faq.astro
safe_file $ROOT/src/pages/marketing/pricing.astro
safe_file $ROOT/src/pages/marketing/blog/index.astro
safe_file "$ROOT/src/pages/marketing/blog/[slug].astro"
safe_file $ROOT/src/pages/marketing/legal/privacy.astro
safe_file $ROOT/src/pages/marketing/legal/terms.astro

# pages — api
safe_file $ROOT/src/pages/api/auth/signup.ts
safe_file $ROOT/src/pages/api/auth/login.ts
safe_file $ROOT/src/pages/api/auth/logout.ts
safe_file $ROOT/src/pages/api/revenue.ts
safe_file $ROOT/src/pages/api/reports.ts
safe_file $ROOT/src/pages/api/quickbooks/connect.ts
safe_file $ROOT/src/pages/api/quickbooks/callback.ts

# components — ui (pure Astro)
safe_file $ROOT/src/components/ui/Nav.astro
safe_file $ROOT/src/components/ui/Footer.astro
safe_file $ROOT/src/components/ui/Hero.astro
safe_file $ROOT/src/components/ui/PricingCard.astro
safe_file $ROOT/src/components/ui/FeatureCard.astro

# components — islands (Svelte)
safe_file $ROOT/src/components/islands/auth/SignupForm.svelte
safe_file $ROOT/src/components/islands/auth/LoginForm.svelte
safe_file $ROOT/src/components/islands/dashboard/RevenueChart.svelte
safe_file $ROOT/src/components/islands/dashboard/CashFlowChart.svelte
safe_file $ROOT/src/components/islands/dashboard/ForecastWidget.svelte
safe_file $ROOT/src/components/islands/dashboard/TransactionTable.svelte
safe_file $ROOT/src/components/islands/shop/PlanSelector.svelte
safe_file $ROOT/src/components/islands/shop/StripeCheckout.svelte
safe_file $ROOT/src/components/islands/shared/Notification.svelte
safe_file $ROOT/src/components/islands/shared/LoadingSpinner.svelte

finish

