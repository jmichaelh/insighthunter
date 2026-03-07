#!/bin/bash
source "$(dirname "$0")/lib/scaffold-utils.sh"
ROOT="apps/insighthunter-main"
echo "🔧 $ROOT"

# ── Create directories ───────────────────────────────────────
mkdir -p $ROOT/src/routes
mkdir -p $ROOT/src/middleware
mkdir -p $ROOT/src/services
mkdir -p $ROOT/src/db/migrations
mkdir -p $ROOT/src/lib
mkdir -p $ROOT/src/types
mkdir -p $ROOT/public/assets/icons
mkdir -p $ROOT/tests/routes
mkdir -p $ROOT/tests/services
mkdir -p $ROOT/tests/fixtures

# ── src ──────────────────────────────────────────────────────
echo ""
echo "📄 src/"
safe_file $ROOT/src/index.ts

# routes
echo ""
echo "📄 src/routes/"
safe_file $ROOT/src/routes/dashboard.ts
safe_file $ROOT/src/routes/reports.ts
safe_file $ROOT/src/routes/forecasts.ts
safe_file $ROOT/src/routes/insights.ts
safe_file $ROOT/src/routes/transactions.ts
safe_file $ROOT/src/routes/clients.ts
safe_file $ROOT/src/routes/settings.ts

# middleware
echo ""
echo "📄 src/middleware/"
safe_file $ROOT/src/middleware/auth.ts
safe_file $ROOT/src/middleware/rateLimit.ts
safe_file $ROOT/src/middleware/cors.ts
safe_file $ROOT/src/middleware/featureFlags.ts

# services
echo ""
echo "📄 src/services/"
safe_file $ROOT/src/services/dashboardService.ts
safe_file $ROOT/src/services/reportService.ts
safe_file $ROOT/src/services/forecastService.ts
safe_file $ROOT/src/services/insightService.ts
safe_file $ROOT/src/services/bookkeepingService.ts
safe_file $ROOT/src/services/notificationService.ts

# db
echo ""
echo "📄 src/db/"
safe_file $ROOT/src/db/schema.sql
safe_file $ROOT/src/db/migrations/0001_init.sql
safe_file $ROOT/src/db/migrations/0002_clients.sql
safe_file $ROOT/src/db/migrations/0003_reports.sql
safe_file $ROOT/src/db/migrations/0004_forecasts.sql
safe_file $ROOT/src/db/queries.ts

# lib
echo ""
echo "📄 src/lib/"
safe_file $ROOT/src/lib/pdf.ts
safe_file $ROOT/src/lib/cache.ts
safe_file $ROOT/src/lib/analytics.ts
safe_file $ROOT/src/lib/logger.ts

# types
echo ""
echo "📄 src/types/"
safe_file $ROOT/src/types/env.ts
safe_file $ROOT/src/types/financial.ts
safe_file $ROOT/src/types/index.ts

# ── public ───────────────────────────────────────────────────
echo ""
echo "📄 public/"
safe_file $ROOT/public/index.html
safe_file $ROOT/public/assets/app.js
safe_file $ROOT/public/assets/styles.css

# ── tests ────────────────────────────────────────────────────
echo ""
echo "📄 tests/"
safe_file $ROOT/tests/routes/dashboard.test.ts
safe_file $ROOT/tests/routes/reports.test.ts
safe_file $ROOT/tests/services/forecastService.test.ts
safe_file $ROOT/tests/fixtures/mockUser.ts
safe_file $ROOT/tests/fixtures/mockFinancials.ts

# ── root config ──────────────────────────────────────────────
echo ""
echo "📄 root config/"
safe_file $ROOT/wrangler.jsonc
safe_file $ROOT/package.json
safe_file $ROOT/tsconfig.json
safe_file $ROOT/README.md

# ── Final report ─────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "✅  insighthunter-main scaffold complete"
echo ""
echo "Legend:"
echo "  ✓ exists      → already correct, untouched"
echo "  ✓ placeholder → dot-file already existed, skipped"
echo "  → moved       → found elsewhere, relocated"
echo "  + new         → missing, created as .filename"
echo "════════════════════════════════════════"
echo ""
if command -v tree &> /dev/null; then
  tree "$ROOT" -a
else
  find "$ROOT" | sort
fi
