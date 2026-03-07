#!/bin/bash
ROOT="apps/insighthunter-agents"

mkdir -p $ROOT/src/{agents,tools,prompts,db/migrations,queues,workflows,lib,types}
mkdir -p $ROOT/public/assets
mkdir -p $ROOT/tests/{agents,fixtures}

# src
echo "." > $ROOT/src/index.ts

# agents
echo "." > $ROOT/src/agents/CfoAgent.ts
echo "." > $ROOT/src/agents/ForecastAgent.ts
echo "." > $ROOT/src/agents/ReportAgent.ts
echo "." > $ROOT/src/agents/OnboardingAgent.ts

# tools
echo "." > $ROOT/src/tools/financialTools.ts
echo "." > $ROOT/src/tools/reportTools.ts
echo "." > $ROOT/src/tools/integrationTools.ts

# prompts
echo "." > $ROOT/src/prompts/cfoSystemPrompt.ts
echo "." > $ROOT/src/prompts/forecastPrompt.ts
echo "." > $ROOT/src/prompts/reportPrompt.ts

# db
echo "." > $ROOT/src/db/schema.sql
echo "." > $ROOT/src/db/migrations/0001_init.sql
echo "." > $ROOT/src/db/migrations/0002_reports.sql
echo "." > $ROOT/src/db/migrations/0003_insights.sql
echo "." > $ROOT/src/db/queries.ts

# queues
echo "." > $ROOT/src/queues/reportQueue.ts
echo "." > $ROOT/src/queues/forecastQueue.ts

# workflows
echo "." > $ROOT/src/workflows/OnboardingWorkflow.ts
echo "." > $ROOT/src/workflows/ReportWorkflow.ts

# lib
echo "." > $ROOT/src/lib/auth.ts
echo "." > $ROOT/src/lib/rateLimit.ts
echo "." > $ROOT/src/lib/cache.ts
echo "." > $ROOT/src/lib/logger.ts

# types
echo "." > $ROOT/src/types/env.ts
echo "." > $ROOT/src/types/agents.ts
echo "." > $ROOT/src/types/financial.ts
echo "." > $ROOT/src/types/index.ts

# public
echo "." > $ROOT/public/index.html
echo "." > $ROOT/public/assets/app.js
echo "." > $ROOT/public/assets/styles.css

# tests
echo "." > $ROOT/tests/agents/CfoAgent.test.ts
echo "." > $ROOT/tests/agents/ForecastAgent.test.ts
echo "." > $ROOT/tests/fixtures/mockFinancials.ts
echo "." > $ROOT/tests/fixtures/mockUser.ts

# config
echo "." > $ROOT/wrangler.jsonc
echo "." > $ROOT/package.json
echo "." > $ROOT/tsconfig.json
echo "." > $ROOT/README.md

echo "✅ insighthunter-agents scaffolded"
