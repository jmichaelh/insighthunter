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
