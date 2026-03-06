#!/bin/bash
source "$(dirname "$0")/lib/scaffold-utils.sh"
ROOT="apps/insighthunter-lite"

echo "🔧 Scaffolding $ROOT..."

mkdir -p $ROOT/src/{routes,middleware,services,db/migrations,lib,types}
mkdir -p $ROOT/public/assets/icons
mkdir -p $ROOT/tests/{routes,services,fixtures}

safe_file $ROOT/src/index.ts

safe_file $ROOT/src/routes/dashboard.ts
safe_file $ROOT/src/routes/upload.ts
safe_file $ROOT/src/routes/reports.ts
safe_file $ROOT/src/routes/insights.ts
safe_file $ROOT/src/routes/upgrade.ts

safe_file $ROOT/src/middleware/auth.ts
safe_file $ROOT/src/middleware/rateLimit.ts
safe_file $ROOT/src/middleware/cors.ts
safe_file $ROOT/src/middleware/usageCap.ts

safe_file $ROOT/src/services/uploadService.ts
safe_file $ROOT/src/services/dashboardService.ts
safe_file $ROOT/src/services/reportService.ts
safe_file $ROOT/src/services/insightService.ts
safe_file $ROOT/src/services/upgradeService.ts

safe_file $ROOT/src/db/schema.sql
safe_file $ROOT/src/db/migrations/0001_init.sql
safe_file $ROOT/src/db/migrations/0002_usage.sql
safe_file $ROOT/src/db/queries.ts

safe_file $ROOT/src/lib/csvParser.ts
safe_file $ROOT/src/lib/usageTracker.ts
safe_file $ROOT/src/lib/cache.ts
safe_file $ROOT/src/lib/analytics.ts
safe_file $ROOT/src/lib/logger.ts

safe_file $ROOT/src/types/env.ts
safe_file $ROOT/src/types/upload.ts
safe_file $ROOT/src/types/usage.ts
safe_file $ROOT/src/types/index.ts

safe_file $ROOT/public/index.html
safe_file $ROOT/public/assets/app.js
safe_file $ROOT/public/assets/styles.css

safe_file $ROOT/tests/routes/upload.test.ts
safe_file $ROOT/tests/routes/dashboard.test.ts
safe_file $ROOT/tests/services/csvParser.test.ts
safe_file $ROOT/tests/fixtures/mockCsv.ts
safe_file $ROOT/tests/fixtures/mockUser.ts

safe_file $ROOT/wrangler.jsonc
safe_file $ROOT/package.json
safe_file $ROOT/tsconfig.json
safe_file $ROOT/README.md

echo "✅ insighthunter-lite done"
