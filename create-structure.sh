#!/usr/bin/env bash

# =============================================================================
# InsightHunter Project Structure Setup
# Creates blank files/folders and moves existing files safely.
# Will NOT delete or overwrite existing files.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$SCRIPT_DIR/apps/insighthunter-main"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

make_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "  📁 Created dir:  $1"
    fi
}

make_file() {
    if [ ! -f "$1" ]; then
        mkdir -p "$(dirname "$1")"
        touch "$1"
        echo "  📄 Created file: $1"
    else
        echo "  ⏭  Exists, skip: $1"
    fi
}

move_file() {
    local src="$1"
    local dst="$2"

    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        mv "$src" "$dst"
        echo "  🚚 Moved: $src → $dst"
    elif [ -f "$src" ] && [ -f "$dst" ]; then
        echo "  ⚠️  Both exist, keeping both: $src (dst: $dst)"
    fi
}

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  InsightHunter — Project Structure Setup"
echo "  Base: $BASE"
echo "════════════════════════════════════════════════════════════"
echo ""

# =============================================================================
# DIRECTORIES
# =============================================================================

echo "── Creating directories ──────────────────────────────────────"

dirs=(
"$BASE/src/pages/features"
"$BASE/src/pages/dashboard"
"$BASE/src/pages/auth"
"$BASE/src/layouts"
"$BASE/src/components/marketing"
"$BASE/src/components/dashboard"
"$BASE/src/components/auth"
"$BASE/src/components/shared"
"$BASE/src/data"
"$BASE/src/lib"
"$BASE/src/types"
"$BASE/src/styles"
"$BASE/src/middleware"
"$BASE/public/icons"
"$BASE/public/og"
"$BASE/public/fonts"
"$BASE/public/features"
"$BASE/functions/api"
"$BASE/sw"
"$BASE/tests/pages"
"$BASE/tests/lib"
"$BASE/tests/fixtures"
)

for d in "${dirs[@]}"; do
    make_dir "$d"
done

# =============================================================================
# FILES — src/pages
# =============================================================================

echo ""
echo "── src/pages ─────────────────────────────────────────────────"

pages=(
"$BASE/src/pages/index.astro"
"$BASE/src/pages/pricing.astro"
"$BASE/src/pages/about.astro"
"$BASE/src/pages/contact.astro"
"$BASE/src/pages/404.astro"

"$BASE/src/pages/features/index.astro"
"$BASE/src/pages/features/bookkeeping.astro"
"$BASE/src/pages/features/bizforma.astro"
"$BASE/src/pages/features/insight-lite.astro"
"$BASE/src/pages/features/insight-standard.astro"
"$BASE/src/pages/features/insight-pro.astro"
"$BASE/src/pages/features/scout.astro"
"$BASE/src/pages/features/pbx.astro"
"$BASE/src/pages/features/payroll.astro"
"$BASE/src/pages/features/website-services.astro"

"$BASE/src/pages/dashboard/index.astro"
"$BASE/src/pages/dashboard/reports.astro"
"$BASE/src/pages/dashboard/forecast.astro"
"$BASE/src/pages/dashboard/bookkeeping.astro"
"$BASE/src/pages/dashboard/bizforma.astro"
"$BASE/src/pages/dashboard/insights.astro"
"$BASE/src/pages/dashboard/settings.astro"
"$BASE/src/pages/dashboard/upgrade.astro"

"$BASE/src/pages/auth/login.astro"
"$BASE/src/pages/auth/register.astro"
"$BASE/src/pages/auth/forgot-password.astro"
"$BASE/src/pages/auth/callback.astro"
)

for f in "${pages[@]}"; do
    make_file "$f"
done

# =============================================================================
# FILES — layouts
# =============================================================================

echo ""
echo "── src/layouts ───────────────────────────────────────────────"

layouts=(
"$BASE/src/layouts/MarketingLayout.astro"
"$BASE/src/layouts/DashboardLayout.astro"
"$BASE/src/layouts/AuthLayout.astro"
)

for f in "${layouts[@]}"; do
    make_file "$f"
done

# =============================================================================
# FILES — components
# =============================================================================

echo ""
echo "── src/components ────────────────────────────────────────────"

components=(

"$BASE/src/components/marketing/Hero.astro"
"$BASE/src/components/marketing/FeatureGrid.astro"
"$BASE/src/components/marketing/PricingTable.astro"
"$BASE/src/components/marketing/Testimonials.astro"
"$BASE/src/components/marketing/CTABanner.astro"
"$BASE/src/components/marketing/AppCard.astro"
"$BASE/src/components/marketing/Nav.astro"

"$BASE/src/components/dashboard/Sidebar.svelte"
"$BASE/src/components/dashboard/TopBar.svelte"
"$BASE/src/components/dashboard/KPICard.svelte"
"$BASE/src/components/dashboard/RevenueChart.svelte"
"$BASE/src/components/dashboard/CashFlowChart.svelte"
"$BASE/src/components/dashboard/InsightCard.svelte"
"$BASE/src/components/dashboard/ActivityFeed.svelte"
"$BASE/src/components/dashboard/QuickActions.svelte"

"$BASE/src/components/auth/LoginForm.svelte"
"$BASE/src/components/auth/RegisterForm.svelte"
"$BASE/src/components/auth/ForgotPasswordForm.svelte"

"$BASE/src/components/shared/Button.astro"
"$BASE/src/components/shared/Badge.astro"
"$BASE/src/components/shared/Modal.svelte"
"$BASE/src/components/shared/Toast.svelte"
"$BASE/src/components/shared/Spinner.svelte"
"$BASE/src/components/shared/EmptyState.astro"
)

for f in "${components[@]}"; do
    make_file "$f"
done

# =============================================================================
# MISC SRC
# =============================================================================

echo ""
echo "── src/data / lib / types / styles / middleware ──────────────"

misc_src=(
"$BASE/src/data/apps.ts"
"$BASE/src/data/pricing.ts"
"$BASE/src/data/features.ts"
"$BASE/src/data/navigation.ts"
"$BASE/src/lib/auth.ts"
"$BASE/src/lib/api.ts"
"$BASE/src/lib/analytics.ts"
"$BASE/src/lib/pwa.ts"
"$BASE/src/types/index.ts"
"$BASE/src/types/auth.ts"
"$BASE/src/types/apps.ts"
"$BASE/src/types/api.ts"
"$BASE/src/styles/globals.scss"
"$BASE/src/styles/theme.scss"
"$BASE/src/styles/dashboard.scss"
"$BASE/src/styles/marketing.scss"
"$BASE/src/middleware/index.ts"
)

for f in "${misc_src[@]}"; do
    make_file "$f"
done

# =============================================================================
# PUBLIC
# =============================================================================

echo ""
echo "── public ────────────────────────────────────────────────────"

public_files=(
"$BASE/public/favicon.ico"
"$BASE/public/favicon.svg"
"$BASE/public/logo.svg"
"$BASE/public/manifest.webmanifest"

"$BASE/public/features/bizforma.html"
"$BASE/public/features/bookkeeping.html"
"$BASE/public/features/insight-lite.html"
"$BASE/public/features/insight-pro.html"
"$BASE/public/features/insight-standard.html"
"$BASE/public/features/pbx.html"
"$BASE/public/features/scout.html"
"$BASE/public/features/website-services.html"
)

for f in "${public_files[@]}"; do
    make_file "$f"
done

# =============================================================================
# FUNCTIONS / SW / TESTS
# =============================================================================

echo ""
echo "── functions / sw / tests ────────────────────────────────────"

other_files=(
"$BASE/functions/api/[[path]].ts"
"$BASE/sw/sw.ts"
"$BASE/sw/precache.ts"
"$BASE/tests/pages/index.test.ts"
"$BASE/tests/pages/dashboard.test.ts"
"$BASE/tests/lib/auth.test.ts"
"$BASE/tests/fixtures/mockSession.ts"
)

for f in "${other_files[@]}"; do
    make_file "$f"
done

# =============================================================================
# ROOT CONFIG
# =============================================================================

echo ""
echo "── Root config files ─────────────────────────────────────────"

root_files=(
"$BASE/astro.config.mjs"
"$BASE/wrangler.jsonc"
"$BASE/package.json"
"$BASE/tsconfig.json"
"$BASE/vite.config.ts"
"$BASE/tailwind.config.ts"
"$BASE/README.md"
)

for f in "${root_files[@]}"; do
    make_file "$f"
done

# =============================================================================
# MOVE MISPLACED FILES
# =============================================================================

echo ""
echo "── Checking for misplaced files to relocate ──────────────────"

move_file "$BASE/src/pages/login.astro" "$BASE/src/pages/auth/login.astro"
move_file "$BASE/src/pages/register.astro" "$BASE/src/pages/auth/register.astro"
move_file "$BASE/src/pages/forgot-password.astro" "$BASE/src/pages/auth/forgot-password.astro"
move_file "$BASE/src/pages/callback.astro" "$BASE/src/pages/auth/callback.astro"

move_file "$BASE/src/pages/reports.astro" "$BASE/src/pages/dashboard/reports.astro"
move_file "$BASE/src/pages/forecast.astro" "$BASE/src/pages/dashboard/forecast.astro"
move_file "$BASE/src/pages/insights.astro" "$BASE/src/pages/dashboard/insights.astro"
move_file "$BASE/src/pages/upgrade.astro" "$BASE/src/pages/dashboard/upgrade.astro"

move_file "$BASE/src/pages/bookkeeping.astro" "$BASE/src/pages/features/bookkeeping.astro"
move_file "$BASE/src/pages/bizforma.astro" "$BASE/src/pages/features/bizforma.astro"
move_file "$BASE/src/pages/insight-lite.astro" "$BASE/src/pages/features/insight-lite.astro"
move_file "$BASE/src/pages/insight-standard.astro" "$BASE/src/pages/features/insight-standard.astro"
move_file "$BASE/src/pages/insight-pro.astro" "$BASE/src/pages/features/insight-pro.astro"

move_file "$BASE/sw.ts" "$BASE/sw/sw.ts"
move_file "$BASE/precache.ts" "$BASE/sw/precache.ts"

for page in bizforma bookkeeping insight-lite insight-pro insight-standard pbx scout website-services; do
    move_file "$BASE/public/${page}.html" "$BASE/public/features/${page}.html"
done

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ Structure setup complete."

FILES=$(find "$BASE" -type f | wc -l | tr -d ' ')
DIRS=$(find "$BASE" -type d | wc -l | tr -d ' ')

echo "  Total files: $FILES"
echo "  Total dirs:  $DIRS"
echo "════════════════════════════════════════════════════════════"
echo ""