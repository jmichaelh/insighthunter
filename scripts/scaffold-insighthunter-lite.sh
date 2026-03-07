#!/bin/bash
# ============================================================
# Scaffold apps/insighthunter-lite
# - Moves misplaced existing files to correct locations
# - Creates .filename placeholders for missing files only
# - NEVER overwrites existing content
# ============================================================
set -e

ROOT="apps/insighthunter-lite"

# ── Helpers ─────────────────────────────────────────────────

# Try to find a file anywhere inside $ROOT and move it to $target
find_and_move() {
  local target="$1"
  local base=$(basename "$target")
  local found

  # Search anywhere in the app folder for the filename
  found=$(find "$ROOT" -name "$base" -not -path "$target" 2>/dev/null | head -1)

  if [ -n "$found" ]; then
    mkdir -p "$(dirname "$target")"
    mv "$found" "$target"
    echo "  → moved:      $found  →  $target"
    return 0
  fi
  return 1
}

# Safe file: skip if exists, try to move if misplaced, else create placeholder
safe_file() {
  local target="$1"
  local base=$(basename "$target")
  local dir=$(dirname "$target")
  local dot_target="$dir/.$base"

  # Already in the right place — do nothing
  if [ -f "$target" ]; then
    echo "  ✓ exists:     $target"
    return
  fi

  # Dot-prefixed placeholder already exists — do nothing
  if [ -f "$dot_target" ]; then
    echo "  ✓ placeholder:$dot_target"
    return
  fi

  # Try to find & move a misplaced copy
  if find_and_move "$target"; then
    return
  fi

  # Truly missing — create dot-prefixed placeholder
  mkdir -p "$dir"
  echo "." > "$dot_target"
  echo "  + new:        $dot_target"
}

# ── Create directory structure ───────────────────────────────
echo ""
echo "📁 Creating directories..."
mkdir -p "$ROOT/src/routes"
mkdir -p "$ROOT/src/middleware"
mkdir -p "$ROOT/src/services"
mkdir -p "$ROOT/src/db/migrations"
mkdir -p "$ROOT/src/lib"
mkdir -p "$ROOT/src/types"
mkdir -p "$ROOT/public/assets/icons"
mkdir -p "$ROOT/tests/routes"
mkdir -p "$ROOT/tests/services" 
mkdir -p "$ROOT/tests/fixtures"

# ── src ──────────────────────────────────────────────────────
echo ""
echo "📄 src/"
safe_file "$ROOT/src/index.ts"

# routes
echo ""
echo "📄 src/routes/"
safe_file "$ROOT/src/routes/dashboard.ts"
safe_file "$ROOT/src/routes/upload.ts"
safe_file "$ROOT/src/routes/reports.ts"
safe_file "$ROOT/src/routes/insights.ts"
safe_file "$ROOT/src/routes/upgrade.ts"

# middleware
echo ""
echo "📄 src/middleware/"
safe_file "$ROOT/src/middleware/auth.ts"
safe_file "$ROOT/src/middleware/rateLimit.ts"
safe_file "$ROOT/src/middleware/cors.ts"
safe_file "$ROOT/src/middleware/usageCap.ts"

# services
echo ""
echo "📄 src/services/"
safe_file "$ROOT/src/services/uploadService.ts"
safe_file "$ROOT/src/services/dashboardService.ts"
safe_file "$ROOT/src/services/reportService.ts"
safe_file "$ROOT/src/services/insightService.ts"
safe_file "$ROOT/src/services/upgradeService.ts"

# db
echo ""
echo "📄 src/db/"
safe_file "$ROOT/src/db/schema.sql"
safe_file "$ROOT/src/db/migrations/0001_init.sql"
safe_file "$ROOT/src/db/migrations/0002_usage.sql"
safe_file "$ROOT/src/db/queries.ts"

# lib
echo ""
echo "📄 src/lib/"
safe_file "$ROOT/src/lib/csvParser.ts"
safe_file "$ROOT/src/lib/usageTracker.ts"
safe_file "$ROOT/src/lib/cache.ts"
safe_file "$ROOT/src/lib/analytics.ts"
safe_file "$ROOT/src/lib/logger.ts"

# types
echo ""
echo "📄 src/types/"
safe_file "$ROOT/src/types/env.ts"
safe_file "$ROOT/src/types/upload.ts"
safe_file "$ROOT/src/types/usage.ts"
safe_file "$ROOT/src/types/index.ts"

# ── public ───────────────────────────────────────────────────
echo ""
echo "📄 public/"
safe_file "$ROOT/public/index.html"
safe_file "$ROOT/public/assets/app.js"
safe_file "$ROOT/public/assets/styles.css"

# ── tests ────────────────────────────────────────────────────
echo ""
echo "📄 tests/"
safe_file "$ROOT/tests/routes/upload.test.ts"
safe_file "$ROOT/tests/routes/dashboard.test.ts"
safe_file "$ROOT/tests/services/csvParser.test.ts"
safe_file "$ROOT/tests/fixtures/mockCsv.ts"
safe_file "$ROOT/tests/fixtures/mockUser.ts"

# ── root config ──────────────────────────────────────────────
echo ""
echo "📄 root config/"
safe_file "$ROOT/wrangler.jsonc"
safe_file "$ROOT/package.json"
safe_file "$ROOT/tsconfig.json"
safe_file "$ROOT/README.md"

# ── Final report ─────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "✅  insighthunter-lite scaffold complete"
echo ""
echo "Legend:"
echo "  ✓ exists      → already in correct place, untouched"
echo "  ✓ placeholder → dot-file already existed, untouched"
echo "  → moved       → found elsewhere in app, moved to correct location"
echo "  + new         → missing, created as .filename placeholder"
echo "════════════════════════════════════════"

# ── Show final tree ──────────────────────────────────────────
echo ""
echo "📁 Final structure:"
if command -v tree &> /dev/null; then
  tree "$ROOT" -a
else
  find "$ROOT" | sort | sed "s|$ROOT||" | sed 's|/[^/]*$|  &|'
fi
#!/bin/bash
source "$(dirname "$0")/lib/scaffold-utils.sh"
ROOT="apps/insighthunter-bookkeeping"
echo "🔧 $ROOT"

mkdir -p $ROOT/public/icons
mkdir -p $ROOT/src/backend/{ai,durable-objects,integrations,utils}
mkdir -p $ROOT/src/{styles,types,utils,hooks,layouts,pages}
mkdir -p $ROOT/src/components/{auth,banking,bookkeeping,onboarding,payment,quickbooks,shared,upload}

# root config
safe_file $ROOT/astro.config.mjs
safe_file $ROOT/wrangler.toml
safe_file $ROOT/package.json
safe_file $ROOT/tsconfig.json

# public
safe_file $ROOT/public/manifest.webmanifest
safe_file $ROOT/public/robots.txt
safe_file $ROOT/public/sw.js

# src root
safe_file $ROOT/src/env.d.ts

# backend
safe_file $ROOT/src/backend/ai/reconciliation-engine.ts
safe_file $ROOT/src/backend/durable-objects/BankConnectionManager.ts
safe_file $ROOT/src/backend/durable-objects/BookkeepingLedger.ts
safe_file $ROOT/src/backend/durable-objects/InvoiceManager.ts
safe_file $ROOT/src/backend/durable-objects/SubscriptionManager.ts
safe_file $ROOT/src/backend/integrations/quickbooks.ts
safe_file $ROOT/src/backend/utils/pricing.ts
safe_file $ROOT/src/backend/enhanced-ledger.ts
safe_file $ROOT/src/backend/index.ts
safe_file $ROOT/src/backend/invoice-management.ts

# styles
safe_file $ROOT/src/styles/bookkeeping.css
safe_file $ROOT/src/styles/tables.css

# types
safe_file $ROOT/src/types/auth.ts
safe_file $ROOT/src/types/banking.ts
safe_file $ROOT/src/types/bookkeeping.ts
safe_file $ROOT/src/types/invoice.ts
safe_file $ROOT/src/types/subscriptions.ts
safe_file $ROOT/src/types/index.ts

# utils
safe_file $ROOT/src/utils/dateUtils.ts
safe_file $ROOT/src/utils/ledgerMath.ts

# hooks (svelte stores)
safe_file $ROOT/src/hooks/books.store.ts
safe_file $ROOT/src/hooks/reconciliation.store.ts
safe_file $ROOT/src/hooks/reports.store.ts

# layouts
safe_file $ROOT/src/layouts/AppLayout.astro

# pages
safe_file $ROOT/src/pages/clients.astro
safe_file $ROOT/src/pages/dashboard.astro
safe_file $ROOT/src/pages/onboarding.astro
safe_file $ROOT/src/pages/pricing.astro
safe_file $ROOT/src/pages/reconciliations.astro
safe_file $ROOT/src/pages/reports.astro
safe_file $ROOT/src/pages/settings.astro
safe_file $ROOT/src/pages/signup.astro

# components
safe_file $ROOT/src/components/auth/SignupForm.svelte
safe_file $ROOT/src/components/banking/PlaidLink.svelte
safe_file $ROOT/src/components/bookkeeping/AccountSelector.svelte
safe_file $ROOT/src/components/bookkeeping/AIReconciliation.svelte
safe_file $ROOT/src/components/bookkeeping/BudgetTracker.svelte
safe_file $ROOT/src/components/bookkeeping/InsightsPanel.svelte
safe_file $ROOT/src/components/bookkeeping/InvoiceManager.svelte
safe_file $ROOT/src/components/bookkeeping/LedgerTable.svelte
safe_file $ROOT/src/components/bookkeeping/MetricsDashboard.svelte
safe_file $ROOT/src/components/bookkeeping/ReportCard.svelte
safe_file $ROOT/src/components/bookkeeping/TransactionRow.svelte
safe_file $ROOT/src/components/onboarding/CompanySetup.svelte
safe_file $ROOT/src/components/onboarding/OnboardingWizard.svelte
safe_file $ROOT/src/components/payment/PricingCards.svelte
safe_file $ROOT/src/components/quickbooks/QuickBooksConnect.svelte
safe_file $ROOT/src/components/shared/NavBar.svelte
safe_file $ROOT/src/components/upload/SpreadsheetUploader.svelte
safe_file $ROOT/src/components/ReconciliationCard.svelte
safe_file $ROOT/src/components/ReconciliationWizard.svelte

finish

