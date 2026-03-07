#!/bin/bash
source "$(dirname "$0")/lib/scaffold-utils.sh"
ROOT="apps/insighthunter-auth"
echo "🔧 $ROOT"

# ── Create directories ───────────────────────────────────────
mkdir -p $ROOT/src/routes
mkdir -p $ROOT/src/middleware
mkdir -p $ROOT/src/services
mkdir -p $ROOT/src/db/migrations
mkdir -p $ROOT/src/lib
mkdir -p $ROOT/src/types
mkdir -p $ROOT/migrations
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
safe_file $ROOT/src/routes/login.ts
safe_file $ROOT/src/routes/register.ts
safe_file $ROOT/src/routes/logout.ts
safe_file $ROOT/src/routes/refresh.ts
safe_file $ROOT/src/routes/verify.ts
safe_file $ROOT/src/routes/roles.ts

# middleware
echo ""
echo "📄 src/middleware/"
safe_file $ROOT/src/middleware/cors.ts
safe_file $ROOT/src/middleware/rateLimit.ts
safe_file $ROOT/src/middleware/validate.ts

# services
echo ""
echo "📄 src/services/"
safe_file $ROOT/src/services/authService.ts
safe_file $ROOT/src/services/tokenService.ts
safe_file $ROOT/src/services/sessionService.ts
safe_file $ROOT/src/services/roleService.ts
safe_file $ROOT/src/services/emailService.ts

# db
echo ""
echo "📄 src/db/"
safe_file $ROOT/src/db/schema.sql
safe_file $ROOT/src/db/migrations/0001_init.sql
safe_file $ROOT/src/db/migrations/0002_sessions.sql
safe_file $ROOT/src/db/migrations/0003_roles.sql
safe_file $ROOT/src/db/queries.ts

# D1 wrangler migrations (top-level)
echo ""
echo "📄 migrations/"
safe_file $ROOT/migrations/0001_init.sql
safe_file $ROOT/migrations/0002_sessions.sql
safe_file $ROOT/migrations/0003_roles.sql

# lib
echo ""
echo "📄 src/lib/"
safe_file $ROOT/src/lib/jwt.ts
safe_file $ROOT/src/lib/hash.ts
safe_file $ROOT/src/lib/cache.ts
safe_file $ROOT/src/lib/analytics.ts
safe_file $ROOT/src/lib/logger.ts

# types
echo ""
echo "📄 src/types/"
safe_file $ROOT/src/types/env.ts
safe_file $ROOT/src/types/auth.ts
safe_file $ROOT/src/types/index.ts

# ── tests ────────────────────────────────────────────────────
echo ""
echo "📄 tests/"
safe_file $ROOT/tests/routes/login.test.ts
safe_file $ROOT/tests/routes/register.test.ts
safe_file $ROOT/tests/services/tokenService.test.ts
safe_file $ROOT/tests/fixtures/mockUser.ts

# ── root config ──────────────────────────────────────────────
echo ""
echo "📄 root config/"
safe_file $ROOT/wrangler.toml
safe_file $ROOT/package.json
safe_file $ROOT/tsconfig.json
safe_file $ROOT/README.md

# ── Final report ─────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "✅  insighthunter-auth scaffold complete"
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