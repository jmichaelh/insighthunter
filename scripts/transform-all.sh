#!/bin/bash
# ============================================================
# transform-all.sh
# Transforms all apps/ into the Astro + Svelte target structure
# - Never overwrites existing files
# - Moves misplaced files to correct locations
# - Creates .filename placeholders for missing files
# Run from monorepo root: bash scripts/transform-all.sh
# ============================================================
set -e

# ── Helpers ──────────────────────────────────────────────────

find_and_move() {
  local target="$1"
  local base=$(basename "$target")
  local search_root="$2"
  local found
  found=$(find "$search_root" -name "$base" -not -path "$target" 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    mkdir -p "$(dirname "$target")"
    mv "$found" "$target"
    echo "  → moved:  $found → $target"
    return 0
  fi
  return 1
}

sf() {
  local target="$1"
  local search_root="$2"
  local base=$(basename "$target")
  local dir=$(dirname "$target")

  if [ -f "$target" ]; then
    echo "  ✓ exists: $target"
    return
  fi
  if [ -f "$dir/.$base" ]; then
    echo "  ✓ dotfile:$dir/.$base"
    return
  fi
  if find_and_move "$target" "$search_root"; then
    return
  fi
  mkdir -p "$dir"
  echo "." > "$dir/.$base"
  echo "  + new:    $dir/.$base"
}

header() { echo ""; echo "══════════════════════════════════"; echo "🔧 $1"; echo "══════════════════════════════════"; }

# ── ROOT ─────────────────────────────────────────────────────
header "monorepo root"
sf package.json .
sf .gitignore .
sf README.md .
sf sitemap.xml .
sf robots.txt .

# ── insighthunter-main ───────────────────────────────────────
header "apps/insighthunter-main"
R="apps/insighthunter-main"
mkdir -p $R/public/icons
mkdir -p $R/src/styles $R/src/layouts
mkdir -p $R/src/pages/{auth,dashboard,admin,account,shop,features,marketing/blog,marketing/legal,api/auth,api/quickbooks}
mkdir -p $R/src/components/ui
mkdir -p $R/src/components/islands/{auth,dashboard,shop,shared}

sf $R/astro.config.mjs $R
sf $R/wrangler.toml $R
sf $R/svelte.config.js $R
sf $R/package.json $R
sf $R/tsconfig.json $R
sf $R/public/.assetsignore $R
sf $R/public/favicon.ico $R
sf $R/public/manifest.webmanifest $R
sf $R/public/robots.txt $R
sf $R/public/icons/icon-192.png $R
sf $R/public/icons/icon-512.png $R
sf $R/src/env.d.ts $R
sf $R/src/styles/styles.css $R
sf $R/src/styles/marketing.css $R
sf $R/src/styles/dashboard.css $R
sf $R/src/layouts/Layout.astro $R
sf $R/src/layouts/DashboardLayout.astro $R
sf $R/src/layouts/MarketingLayout.astro $R
sf $R/src/pages/index.astro $R
sf $R/src/pages/about.astro $R
sf $R/src/pages/features.astro $R
sf $R/src/pages/pricing.astro $R
sf $R/src/pages/docs.astro $R
sf $R/src/pages/support.astro $R
sf $R/src/pages/auth/login.astro $R
sf $R/src/pages/auth/signup.astro $R
sf $R/src/pages/auth/logout.astro $R
sf $R/src/pages/dashboard/index.astro $R
sf $R/src/pages/dashboard/bookkeeping.astro $R
sf $R/src/pages/dashboard/clients.astro $R
sf $R/src/pages/dashboard/compliance.astro $R
sf $R/src/pages/dashboard/reconciliation.astro $R
sf $R/src/pages/dashboard/reports.astro $R
sf $R/src/pages/dashboard/settings.astro $R
sf $R/src/pages/admin/index.astro $R
sf $R/src/pages/admin/compliance.astro $R
sf $R/src/pages/account/index.astro $R
sf $R/src/pages/account/billing.astro $R
sf $R/src/pages/shop/index.astro $R
sf $R/src/pages/shop/checkout.astro $R
sf $R/src/pages/shop/success.astro $R
sf $R/src/pages/features/bizforma.astro $R
sf $R/src/pages/features/bookkeeping.astro $R
sf $R/src/pages/features/insight-lite.astro $R
sf $R/src/pages/features/insight-pro.astro $R
sf $R/src/pages/features/insight-standard.astro $R
sf $R/src/pages/features/pbx.astro $R
sf $R/src/pages/features/scout.astro $R
sf $R/src/pages/features/website-services.astro $R
sf $R/src/pages/marketing/index.astro $R
sf $R/src/pages/marketing/about.astro $R
sf $R/src/pages/marketing/contact.astro $R
sf $R/src/pages/marketing/faq.astro $R
sf $R/src/pages/marketing/pricing.astro $R
sf $R/src/pages/marketing/blog/index.astro $R
sf "$R/src/pages/marketing/blog/[slug].astro" $R
sf $R/src/pages/marketing/legal/privacy.astro $R
sf $R/src/pages/marketing/legal/terms.astro $R
sf $R/src/pages/api/auth/signup.ts $R
sf $R/src/pages/api/auth/login.ts $R
sf $R/src/pages/api/auth/logout.ts $R
sf $R/src/pages/api/revenue.ts $R
sf $R/src/pages/api/reports.ts $R
sf $R/src/pages/api/quickbooks/connect.ts $R
sf $R/src/pages/api/quickbooks/callback.ts $R
sf $R/src/components/ui/Nav.astro $R
sf $R/src/components/ui/Footer.astro $R
sf $R/src/components/ui/Hero.astro $R
sf $R/src/components/ui/PricingCard.astro $R
sf $R/src/components/ui/FeatureCard.astro $R
sf $R/src/components/islands/auth/SignupForm.svelte $R
sf $R/src/components/islands/auth/LoginForm.svelte $R
sf $R/src/components/islands/dashboard/RevenueChart.svelte $R
sf $R/src/components/islands/dashboard/CashFlowChart.svelte $R
sf $R/src/components/islands/dashboard/ForecastWidget.svelte $R
sf $R/src/components/islands/dashboard/TransactionTable.svelte $R
sf $R/src/components/islands/shop/PlanSelector.svelte $R
sf $R/src/components/islands/shop/StripeCheckout.svelte $R
sf $R/src/components/islands/shared/Notification.svelte $R
sf $R/src/components/islands/shared/LoadingSpinner.svelte $R

# ── insighthunter-bookkeeping ────────────────────────────────
header "apps/insighthunter-bookkeeping"
R="apps/insighthunter-bookkeeping"
mkdir -p $R/public/icons
mkdir -p $R/src/backend/{ai,durable-objects,integrations,utils}
mkdir -p $R/src/{styles,types,utils,hooks,layouts}
mkdir -p $R/src/pages
mkdir -p $R/src/components/{auth,banking,bookkeeping,onboarding,payment,quickbooks,shared,upload}

sf $R/astro.config.mjs $R
sf $R/wrangler.toml $R
sf $R/package.json $R
sf $R/tsconfig.json $R
sf $R/public/manifest.webmanifest $R
sf $R/public/robots.txt $R
sf $R/public/sw.js $R
sf $R/src/env.d.ts $R
sf $R/src/backend/ai/reconciliation-engine.ts $R
sf $R/src/backend/durable-objects/BankConnectionManager.ts $R
sf $R/src/backend/durable-objects/BookkeepingLedger.ts $R
sf $R/src/backend/durable-objects/InvoiceManager.ts $R
sf $R/src/backend/durable-objects/SubscriptionManager.ts $R
sf $R/src/backend/integrations/quickbooks.ts $R
sf $R/src/backend/utils/pricing.ts $R
sf $R/src/backend/enhanced-ledger.ts $R
sf $R/src/backend/index.ts $R
sf $R/src/backend/invoice-management.ts $R
sf $R/src/styles/bookkeeping.css $R
sf $R/src/styles/tables.css $R
sf $R/src/types/auth.ts $R
sf $R/src/types/banking.ts $R
sf $R/src/types/bookkeeping.ts $R
sf $R/src/types/index.ts $R
sf $R/src/types/invoice.ts $R
sf $R/src/types/subscriptions.ts $R
sf $R/src/utils/dateUtils.ts $R
sf $R/src/utils/ledgerMath.ts $R
sf $R/src/hooks/books.store.ts $R
sf $R/src/hooks/reconciliation.store.ts $R
sf $R/src/hooks/reports.store.ts $R
sf $R/src/layouts/AppLayout.astro $R
sf $R/src/pages/clients.astro $R
sf $R/src/pages/dashboard.astro $R
sf $R/src/pages/onboarding.astro $R
sf $R/src/pages/pricing.astro $R
sf $R/src/pages/reconciliations.astro $R
sf $R/src/pages/reports.astro $R
sf $R/src/pages/settings.astro $R
sf $R/src/pages/signup.astro $R
sf $R/src/components/auth/SignupForm.svelte $R
sf $R/src/components/banking/PlaidLink.svelte $R
sf $R/src/components/bookkeeping/AccountSelector.svelte $R
sf $R/src/components/bookkeeping/AIReconciliation.svelte $R
sf $R/src/components/bookkeeping/BudgetTracker.svelte $R
sf $R/src/components/bookkeeping/InsightsPanel.svelte $R
sf $R/src/components/bookkeeping/InvoiceManager.svelte $R
sf $R/src/components/bookkeeping/LedgerTable.svelte $R
sf $R/src/components/bookkeeping/MetricsDashboard.svelte $R
sf $R/src/components/bookkeeping/ReportCard.svelte $R
sf $R/src/components/bookkeeping/TransactionRow.svelte $R
sf $R/src/components/onboarding/CompanySetup.svelte $R
sf $R/src/components/onboarding/OnboardingWizard.svelte $R
sf $R/src/components/payment/PricingCards.svelte $R
sf $R/src/components/quickbooks/QuickBooksConnect.svelte $R
sf $R/src/components/shared/NavBar.svelte $R
sf $R/src/components/upload/SpreadsheetUploader.svelte $R
sf $R/src/components/ReconciliationCard.svelte $R
sf $R/src/components/ReconciliationWizard.svelte $R

# ── insighthunter-auth (keep as-is) ──────────────────────────
header "apps/insighthunter-auth (keep as-is)"
R="apps/insighthunter-auth"
mkdir -p $R/migrations $R/src
sf $R/src/index.ts $R
sf $R/package.json $R
sf $R/wrangler.toml $R

# ── insighthunter-lite ───────────────────────────────────────
header "apps/insighthunter-lite"
R="apps/insighthunter-lite"
mkdir -p $R/public
mkdir -p $R/src/pages
mkdir -p $R/src/components/islands

sf $R/astro.config.mjs $R
sf $R/wrangler.toml $R
sf $R/package.json $R
sf $R/public/manifest.json $R
sf $R/public/sample-transactions.csv $R
sf $R/public/sw.js $R
sf $R/src/pages/index.astro $R
sf $R/src/pages/upload.astro $R
sf $R/src/components/islands/CSVUploader.svelte $R

# ── insighthunter-pbx ────────────────────────────────────────
header "apps/insighthunter-pbx"
R="apps/insighthunter-pbx"
mkdir -p $R/src/pages $R/src/backend

sf $R/astro.config.mjs $R
sf $R/wrangler.toml $R
sf $R/schema.sql $R
sf $R/package.json $R
sf $R/src/pages/index.astro $R
sf $R/src/pages/dashboard.astro $R
sf $R/src/backend/index.ts $R

# ── bizforma ─────────────────────────────────────────────────
header "apps/bizforma"
R="apps/bizforma"
mkdir -p $R/src/pages

sf $R/astro.config.mjs $R
sf $R/wrangler.toml $R
sf $R/package.json $R
sf $R/src/pages/index.astro $R

# ── insighthunter-marketing ──────────────────────────────────
header "apps/insighthunter-marketing"
R="apps/insighthunter-marketing"
mkdir -p $R

sf $R/astro.config.mjs $R
sf $R/wrangler.toml $R
sf $R/package.json $R

# ── insighthunter-mobile ─────────────────────────────────────
header "apps/insighthunter-mobile"
R="apps/insighthunter-mobile"
mkdir -p $R
sf $R/package.json $R
sf $R/tsconfig.json $R

# ── Future stubs ─────────────────────────────────────────────
header "future stubs"
for stub in insighthunter-scout insighthunter-standard insighthunter-pro-services; do
  mkdir -p apps/$stub
  sf apps/$stub/package.json apps/$stub
done

# ── packages/ ────────────────────────────────────────────────
header "packages/types"
mkdir -p packages/types/src
sf packages/types/package.json packages/types
sf packages/types/src/user.ts packages/types
sf packages/types/src/bookkeeping.ts packages/types
sf packages/types/src/invoice.ts packages/types
sf packages/types/src/banking.ts packages/types
sf packages/types/src/subscriptions.ts packages/types
sf packages/types/src/index.ts packages/types

header "packages/utils"
mkdir -p packages/utils/src
sf packages/utils/package.json packages/utils
sf packages/utils/src/formatCurrency.ts packages/utils
sf packages/utils/src/dateUtils.ts packages/utils
sf packages/utils/src/ledgerMath.ts packages/utils
sf packages/utils/src/index.ts packages/utils

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  🎉 Transform complete                   ║"
echo "║  ✓ exists  → untouched                   ║"
echo "║  → moved   → relocated to correct path   ║"
echo "║  + new     → .filename placeholder       ║"
echo "╚══════════════════════════════════════════╝"
echo ""
if command -v tree &> /dev/null; then
  tree apps packages -a --dirsfirst -I node_modules
else
  find apps packages -not -path "*/node_modules/*" | sort
fi
