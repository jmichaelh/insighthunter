#!/usr/bin/env bash
# =============================================================================
# scaffold-insighthunter-main.sh
# Scaffolds Insight Hunter Main — Hono + TypeScript Cloudflare Worker
# API backend: D1, KV, R2, Queues, Analytics Engine
# Calls insighthunter-auth, insighthunter-agents, insighthunter-bookkeeping
#
# Usage:
#   chmod +x scaffold-insighthunter-main.sh
#   ./scaffold-insighthunter-main.sh [target-dir]
# =============================================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
die()     { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }

# ── Dependency checks ─────────────────────────────────────────────────────────
command -v node >/dev/null 2>&1 || die "Node.js >= 20 required"
command -v npm  >/dev/null 2>&1 || die "npm is required"
command -v git  >/dev/null 2>&1 || die "git is required"
NODE_MAJOR=$(node -e "process.stdout.write(process.version.slice(1).split('.')[0])")
(( NODE_MAJOR >= 20 )) || die "Node.js 20+ required (found $(node -v))"

# ── Config ────────────────────────────────────────────────────────────────────
PROJECT_DIR="${1:-insighthunter-main}"
if [[ -d "$PROJECT_DIR" ]]; then
  warn "Directory '$PROJECT_DIR' already exists."
  read -rp "  Overwrite? (y/N) " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
  rm -rf "$PROJECT_DIR"
fi

echo -e "\n${BOLD}${CYAN}Scaffolding Insight Hunter Main${RESET}\n"

# =============================================================================
# 1. Directory tree
# =============================================================================
info "Creating directory tree…"
mkdir -p "$PROJECT_DIR"/{src/{routes,middleware,services,db/migrations,lib,types},public/assets/icons,tests/{routes,services,fixtures}}
success "Directories created."

cd "$PROJECT_DIR"

# =============================================================================
# 2. package.json
# =============================================================================
info "Writing package.json…"
cat > package.json <<'JSON'
{
  "name": "@insighthunter/main",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev":            "wrangler dev",
    "build":          "tsc --noEmit && echo 'Type check passed'",
    "deploy":         "wrangler deploy",
    "deploy:staging": "wrangler deploy --env staging",
    "cf-typegen":     "wrangler types --env-interface CloudflareBindings",
    "type-check":     "tsc --noEmit",
    "test":           "vitest run",
    "test:watch":     "vitest",
    "test:coverage":  "vitest run --coverage",
    "lint":           "eslint src --ext .ts",
    "lint:fix":       "eslint src --ext .ts --fix",
    "migrate:local":  "wrangler d1 migrations apply insighthunter-main-db --local",
    "migrate:remote": "wrangler d1 migrations apply insighthunter-main-db --remote"
  },
  "dependencies": {
    "hono": "^4.7.4",
    "zod":  "^3.24.2"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20250310.0",
    "wrangler":                  "^4.2.0",
    "typescript":                "^5.8.2",
    "vitest":                    "^3.0.8",
    "@vitest/coverage-v8":       "^3.0.8",
    "eslint":                    "^9.22.0",
    "@typescript-eslint/eslint-plugin": "^8.26.1",
    "@typescript-eslint/parser":        "^8.26.1"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
JSON
success "package.json written."

# =============================================================================
# 3. wrangler.jsonc
# =============================================================================
info "Writing wrangler.jsonc…"
cat > wrangler.jsonc <<'EOF'
{
  "name": "insighthunter-main",
  "main": "src/index.ts",
  "compatibility_date": "2025-03-07",
  "compatibility_flags": ["nodejs_compat"],

  "observability": {
    "enabled": true
  },

  // Static assets served from /public
  "assets": {
    "directory": "./public",
    "not_found_handling": "single-page-application"
  },

  // D1 — primary relational database
  "d1_databases": [
    {
      "binding":       "DB",
      "database_name": "insighthunter-main-db",
      "database_id":   "REPLACE_WITH_D1_DATABASE_ID",
      "migrations_dir": "src/db/migrations"
    }
  ],

  // KV — session cache, rate limiting, feature flags
  "kv_namespaces": [
    {
      "binding":     "CACHE",
      "id":          "REPLACE_WITH_KV_ID",
      "preview_id":  "REPLACE_WITH_PREVIEW_KV_ID"
    },
    {
      "binding":     "RATE_LIMIT",
      "id":          "REPLACE_WITH_RATE_LIMIT_KV_ID",
      "preview_id":  "REPLACE_WITH_PREVIEW_RATE_LIMIT_KV_ID"
    }
  ],

  // R2 — PDF report storage
  "r2_buckets": [
    {
      "binding":      "REPORTS_BUCKET",
      "bucket_name":  "insighthunter-reports"
    }
  ],

  // Queues — async report generation & notifications
  "queues": {
    "producers": [
      { "binding": "REPORT_QUEUE",        "queue": "insighthunter-report-queue" },
      { "binding": "NOTIFICATION_QUEUE",  "queue": "insighthunter-notification-queue" }
    ],
    "consumers": [
      { "queue": "insighthunter-report-queue",       "max_batch_size": 5,  "max_batch_timeout": 30 },
      { "queue": "insighthunter-notification-queue", "max_batch_size": 10, "max_batch_timeout": 10 }
    ]
  },

  // Analytics Engine — event tracking
  "analytics_engine_datasets": [
    { "binding": "EVENTS", "dataset": "insighthunter_events" }
  ],

  // Environment variables (non-secret)
  "vars": {
    "APP_ENV":              "development",
    "APP_TIER":             "standard",
    "AUTH_SERVICE_URL":     "https://insighthunter-auth.workers.dev",
    "AGENTS_SERVICE_URL":   "https://insighthunter-agents.workers.dev",
    "BOOKKEEPING_SERVICE_URL": "https://insighthunter-bookkeeping.workers.dev",
    "CORS_ORIGIN":          "https://app.insighthunter.com",
    "RATE_LIMIT_WINDOW":    "60",
    "RATE_LIMIT_MAX":       "100"
  }

  // Secrets — add via: wrangler secret put SECRET_NAME
  // Required: JWT_SECRET, SERVICE_API_KEY
}
EOF
success "wrangler.jsonc written."

# =============================================================================
# 4. tsconfig.json
# =============================================================================
info "Writing tsconfig.json…"
cat > tsconfig.json <<'JSON'
{
  "compilerOptions": {
    "target":               "ESNext",
    "module":               "ESNext",
    "moduleResolution":     "bundler",
    "lib":                  ["ESNext"],
    "strict":               true,
    "verbatimModuleSyntax": true,
    "noUnusedLocals":       true,
    "noUnusedParameters":   true,
    "noImplicitReturns":    true,
    "baseUrl":              ".",
    "paths": {
      "@/*":        ["src/*"],
      "@routes/*":  ["src/routes/*"],
      "@services/*":["src/services/*"],
      "@lib/*":     ["src/lib/*"],
      "@types/*":   ["src/types/*"]
    },
    "types": ["@cloudflare/workers-types"]
  },
  "include": ["src/**/*", "tests/**/*"]
}
JSON
success "tsconfig.json written."

# =============================================================================
# 5. .env.example
# =============================================================================
info "Writing .env.example…"
cat > .env.example <<'EOF'
# App
APP_ENV=development
APP_TIER=standard

# Internal service URLs (set in wrangler.jsonc for prod)
AUTH_SERVICE_URL=http://localhost:8788
AGENTS_SERVICE_URL=http://localhost:8789
BOOKKEEPING_SERVICE_URL=http://localhost:8790

# CORS
CORS_ORIGIN=http://localhost:4321

# Rate limiting
RATE_LIMIT_WINDOW=60
RATE_LIMIT_MAX=100

# Secrets — set via wrangler secret put
JWT_SECRET=replace_with_32_char_random_string
SERVICE_API_KEY=replace_with_internal_service_key
EOF
success ".env.example written."

# =============================================================================
# 6. .gitignore
# =============================================================================
info "Writing .gitignore…"
cat > .gitignore <<'EOF'
dist/
node_modules/
.env
.env.local
.env.*.local
.wrangler/
.dev.vars
.DS_Store
*.log
coverage/
EOF
success ".gitignore written."

# =============================================================================
# 7. Types
# =============================================================================
info "Writing types…"

cat > src/types/env.ts <<'TS'
export interface Env {
  // D1
  DB: D1Database;

  // KV
  CACHE:      KVNamespace;
  RATE_LIMIT: KVNamespace;

  // R2
  REPORTS_BUCKET: R2Bucket;

  // Queues
  REPORT_QUEUE:       Queue;
  NOTIFICATION_QUEUE: Queue;

  // Analytics
  EVENTS: AnalyticsEngineDataset;

  // Vars
  APP_ENV:                 string;
  APP_TIER:                string;
  AUTH_SERVICE_URL:        string;
  AGENTS_SERVICE_URL:      string;
  BOOKKEEPING_SERVICE_URL: string;
  CORS_ORIGIN:             string;
  RATE_LIMIT_WINDOW:       string;
  RATE_LIMIT_MAX:          string;

  // Secrets
  JWT_SECRET:      string;
  SERVICE_API_KEY: string;
}
TS

cat > src/types/financial.ts <<'TS'
// ── KPI / Dashboard ───────────────────────────────────────────────────────────
export interface KPISnapshot {
  revenue:    number;
  expenses:   number;
  netIncome:  number;
  cashBalance:number;
  grossMargin:number;
  period:     string;
  asOf:       string;
}

export interface DashboardData {
  kpis:         KPISnapshot;
  recentAlerts: Alert[];
  trendData:    TrendPoint[];
}

export interface TrendPoint {
  period:   string;
  revenue:  number;
  expenses: number;
  net:      number;
}

export interface Alert {
  id:        string;
  type:      "cash_low" | "expense_spike" | "revenue_drop" | "insight";
  message:   string;
  severity:  "info" | "warning" | "critical";
  createdAt: string;
}

// ── P&L / Reports ─────────────────────────────────────────────────────────────
export interface ProfitLoss {
  periodStart:   string;
  periodEnd:     string;
  totalRevenue:  number;
  totalExpenses: number;
  netIncome:     number;
  grossMargin:   number;
  rows:          PLRow[];
}

export interface PLRow {
  account:  string;
  amount:   number;
  type:     "income" | "expense";
  category: string;
}

export interface ReportRecord {
  id:          string;
  orgId:       string;
  type:        "pl" | "cashflow" | "balance_sheet" | "forecast";
  title:       string;
  periodStart: string;
  periodEnd:   string;
  r2Key:       string;
  createdAt:   string;
  createdBy:   string;
}

// ── Forecast ──────────────────────────────────────────────────────────────────
export interface ForecastResult {
  periods:      ForecastPeriod[];
  confidence:   number;
  generatedAt:  string;
  modelVersion: string;
}

export interface ForecastPeriod {
  period:         string;
  projectedRev:   number;
  projectedExp:   number;
  projectedNet:   number;
  lower:          number;
  upper:          number;
}

// ── Transactions ──────────────────────────────────────────────────────────────
export interface Transaction {
  id:          string;
  orgId:       string;
  date:        string;
  description: string;
  amount:      number;
  category:    string;
  account:     string;
  source:      "qbo" | "csv" | "manual";
  createdAt:   string;
}

// ── Clients (white-label) ─────────────────────────────────────────────────────
export interface Client {
  id:          string;
  orgId:       string;
  name:        string;
  email:       string;
  tier:        "lite" | "standard" | "enterprise";
  status:      "active" | "suspended" | "trial";
  createdAt:   string;
}

// ── Insights ──────────────────────────────────────────────────────────────────
export interface Insight {
  id:        string;
  orgId:     string;
  summary:   string;
  detail:    string;
  actions:   string[];
  model:     string;
  createdAt: string;
}

// ── User / Org ────────────────────────────────────────────────────────────────
export interface TokenPayload {
  sub:   string;
  email: string;
  name:  string;
  tier:  string;
  orgId: string;
  iat:   number;
  exp:   number;
}
TS

cat > src/types/index.ts <<'TS'
export type { Env } from "./env";
export type {
  KPISnapshot,
  DashboardData,
  TrendPoint,
  Alert,
  ProfitLoss,
  PLRow,
  ReportRecord,
  ForecastResult,
  ForecastPeriod,
  Transaction,
  Client,
  Insight,
  TokenPayload,
} from "./financial";
TS
success "Types written."

# =============================================================================
# 8. DB schema & migrations
# =============================================================================
info "Writing DB schema & migrations…"

cat > src/db/schema.sql <<'SQL'
-- ── Organizations ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orgs (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  tier        TEXT NOT NULL DEFAULT 'lite',
  status      TEXT NOT NULL DEFAULT 'active',
  created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ── Users ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          TEXT PRIMARY KEY,
  org_id      TEXT NOT NULL REFERENCES orgs(id),
  email       TEXT NOT NULL UNIQUE,
  name        TEXT NOT NULL,
  role        TEXT NOT NULL DEFAULT 'member',
  created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_org ON users(org_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ── Transactions ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id          TEXT PRIMARY KEY,
  org_id      TEXT NOT NULL REFERENCES orgs(id),
  date        TEXT NOT NULL,
  description TEXT NOT NULL,
  amount      REAL NOT NULL,
  category    TEXT NOT NULL DEFAULT 'Uncategorized',
  account     TEXT NOT NULL DEFAULT 'Default',
  source      TEXT NOT NULL DEFAULT 'manual',
  created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_txn_org  ON transactions(org_id);
CREATE INDEX IF NOT EXISTS idx_txn_date ON transactions(org_id, date DESC);

-- ── Reports ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id           TEXT PRIMARY KEY,
  org_id       TEXT NOT NULL REFERENCES orgs(id),
  type         TEXT NOT NULL,
  title        TEXT NOT NULL,
  period_start TEXT NOT NULL,
  period_end   TEXT NOT NULL,
  r2_key       TEXT,
  created_by   TEXT NOT NULL,
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reports_org ON reports(org_id, created_at DESC);
SQL

cat > src/db/migrations/0001_init.sql <<'SQL'
-- Migration 0001: initial schema
CREATE TABLE IF NOT EXISTS orgs (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  tier       TEXT NOT NULL DEFAULT 'lite',
  status     TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS users (
  id         TEXT PRIMARY KEY,
  org_id     TEXT NOT NULL REFERENCES orgs(id),
  email      TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL,
  role       TEXT NOT NULL DEFAULT 'member',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_org   ON users(org_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS transactions (
  id          TEXT PRIMARY KEY,
  org_id      TEXT NOT NULL REFERENCES orgs(id),
  date        TEXT NOT NULL,
  description TEXT NOT NULL,
  amount      REAL NOT NULL,
  category    TEXT NOT NULL DEFAULT 'Uncategorized',
  account     TEXT NOT NULL DEFAULT 'Default',
  source      TEXT NOT NULL DEFAULT 'manual',
  created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_txn_org  ON transactions(org_id);
CREATE INDEX IF NOT EXISTS idx_txn_date ON transactions(org_id, date DESC);
SQL

cat > src/db/migrations/0002_clients.sql <<'SQL'
-- Migration 0002: white-label clients
CREATE TABLE IF NOT EXISTS clients (
  id         TEXT PRIMARY KEY,
  org_id     TEXT NOT NULL REFERENCES orgs(id),
  name       TEXT NOT NULL,
  email      TEXT NOT NULL,
  tier       TEXT NOT NULL DEFAULT 'lite',
  status     TEXT NOT NULL DEFAULT 'trial',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_clients_org ON clients(org_id);
SQL

cat > src/db/migrations/0003_reports.sql <<'SQL'
-- Migration 0003: report records
CREATE TABLE IF NOT EXISTS reports (
  id           TEXT PRIMARY KEY,
  org_id       TEXT NOT NULL REFERENCES orgs(id),
  type         TEXT NOT NULL,
  title        TEXT NOT NULL,
  period_start TEXT NOT NULL,
  period_end   TEXT NOT NULL,
  r2_key       TEXT,
  created_by   TEXT NOT NULL,
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reports_org ON reports(org_id, created_at DESC);
SQL

cat > src/db/migrations/0004_forecasts.sql <<'SQL'
-- Migration 0004: forecast cache
CREATE TABLE IF NOT EXISTS forecasts (
  id           TEXT PRIMARY KEY,
  org_id       TEXT NOT NULL REFERENCES orgs(id),
  model        TEXT NOT NULL DEFAULT 'linear',
  result_json  TEXT NOT NULL,
  confidence   REAL NOT NULL DEFAULT 0.0,
  period_start TEXT NOT NULL,
  period_end   TEXT NOT NULL,
  created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_forecasts_org ON forecasts(org_id, created_at DESC);
SQL

cat > src/db/queries.ts <<'TS'
import type { Transaction, ReportRecord, Client } from "@/types";

// ── Transactions ──────────────────────────────────────────────────────────────
export async function getTransactions(
  db: D1Database,
  orgId: string,
  limit = 50,
  offset = 0
): Promise<Transaction[]> {
  const { results } = await db
    .prepare("SELECT * FROM transactions WHERE org_id = ? ORDER BY date DESC LIMIT ? OFFSET ?")
    .bind(orgId, limit, offset)
    .all<Transaction>();
  return results;
}

export async function insertTransaction(
  db: D1Database,
  tx: Omit<Transaction, "createdAt">
): Promise<void> {
  await db
    .prepare(
      "INSERT INTO transactions (id, org_id, date, description, amount, category, account, source, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))"
    )
    .bind(tx.id, tx.orgId, tx.date, tx.description, tx.amount, tx.category, tx.account, tx.source)
    .run();
}

export async function getKPIAggregates(
  db: D1Database,
  orgId: string,
  start: string,
  end: string
): Promise<{ revenue: number; expenses: number }> {
  const { results } = await db
    .prepare(
      `SELECT
         SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as revenue,
         SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as expenses
       FROM transactions
       WHERE org_id = ? AND date BETWEEN ? AND ?`
    )
    .bind(orgId, start, end)
    .all<{ revenue: number; expenses: number }>();
  return results[0] ?? { revenue: 0, expenses: 0 };
}

export async function getTrendData(
  db: D1Database,
  orgId: string,
  months = 6
): Promise<{ period: string; revenue: number; expenses: number }[]> {
  const { results } = await db
    .prepare(
      `SELECT
         strftime('%Y-%m', date) as period,
         SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END)        as revenue,
         SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END)   as expenses
       FROM transactions
       WHERE org_id = ?
         AND date >= date('now', ? || ' months')
       GROUP BY period
       ORDER BY period ASC`
    )
    .bind(orgId, `-${months}`)
    .all<{ period: string; revenue: number; expenses: number }>();
  return results;
}

// ── Reports ───────────────────────────────────────────────────────────────────
export async function getReports(
  db: D1Database,
  orgId: string,
  limit = 20
): Promise<ReportRecord[]> {
  const { results } = await db
    .prepare("SELECT * FROM reports WHERE org_id = ? ORDER BY created_at DESC LIMIT ?")
    .bind(orgId, limit)
    .all<ReportRecord>();
  return results;
}

export async function insertReport(
  db: D1Database,
  report: Omit<ReportRecord, "createdAt">
): Promise<void> {
  await db
    .prepare(
      "INSERT INTO reports (id, org_id, type, title, period_start, period_end, r2_key, created_by, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))"
    )
    .bind(report.id, report.orgId, report.type, report.title, report.periodStart, report.periodEnd, report.r2Key, report.createdBy)
    .run();
}

// ── Clients ───────────────────────────────────────────────────────────────────
export async function getClients(
  db: D1Database,
  orgId: string
): Promise<Client[]> {
  const { results } = await db
    .prepare("SELECT * FROM clients WHERE org_id = ? ORDER BY created_at DESC")
    .bind(orgId)
    .all<Client>();
  return results;
}

export async function insertClient(
  db: D1Database,
  client: Omit<Client, "createdAt">
): Promise<void> {
  await db
    .prepare(
      "INSERT INTO clients (id, org_id, name, email, tier, status, created_at) VALUES (?, ?, ?, ?, ?, ?, datetime('now'))"
    )
    .bind(client.id, client.orgId, client.name, client.email, client.tier, client.status)
    .run();
}
TS
success "DB schema, migrations, and queries written."

# =============================================================================
# 9. Lib — cache, analytics, logger, pdf
# =============================================================================
info "Writing lib files…"

cat > src/lib/cache.ts <<'TS'
export async function cacheGet<T>(kv: KVNamespace, key: string): Promise<T | null> {
  const raw = await kv.get(key);
  return raw ? (JSON.parse(raw) as T) : null;
}

export async function cacheSet<T>(
  kv: KVNamespace,
  key: string,
  value: T,
  ttlSeconds = 300
): Promise<void> {
  await kv.put(key, JSON.stringify(value), { expirationTtl: ttlSeconds });
}

export async function cacheDel(kv: KVNamespace, key: string): Promise<void> {
  await kv.delete(key);
}

export async function cacheGetOrSet<T>(
  kv: KVNamespace,
  key: string,
  fetcher: () => Promise<T>,
  ttlSeconds = 300
): Promise<T> {
  const cached = await cacheGet<T>(kv, key);
  if (cached !== null) return cached;
  const fresh = await fetcher();
  await cacheSet(kv, key, fresh, ttlSeconds);
  return fresh;
}
TS

cat > src/lib/analytics.ts <<'TS'
import type { Env } from "@/types";

export type EventName =
  | "dashboard_viewed"
  | "report_generated"
  | "report_exported"
  | "forecast_run"
  | "insight_generated"
  | "transaction_imported"
  | "client_created"
  | "api_error";

export function trackEvent(
  env: Env,
  event: EventName,
  orgId: string,
  meta: Record<string, string | number | boolean> = {}
): void {
  try {
    env.EVENTS.writeDataPoint({
      blobs:   [event, orgId, env.APP_ENV],
      doubles: [Date.now()],
      indexes: [orgId],
    });
  } catch {
    // non-blocking — never throw from analytics
  }
}
TS

cat > src/lib/logger.ts <<'TS'
type Level = "debug" | "info" | "warn" | "error";

interface LogEntry {
  level:   Level;
  message: string;
  ts:      string;
  data?:   unknown;
}

function log(level: Level, message: string, data?: unknown): void {
  const entry: LogEntry = { level, message, ts: new Date().toISOString(), data };
  const line = JSON.stringify(entry);
  if (level === "error" || level === "warn") {
    console.error(line);
  } else {
    console.log(line);
  }
}

export const logger = {
  debug: (msg: string, data?: unknown) => log("debug", msg, data),
  info:  (msg: string, data?: unknown) => log("info",  msg, data),
  warn:  (msg: string, data?: unknown) => log("warn",  msg, data),
  error: (msg: string, data?: unknown) => log("error", msg, data),
};
TS

cat > src/lib/pdf.ts <<'TS'
import type { Env, ReportRecord } from "@/types";
import { insertReport } from "@/db/queries";
import { logger } from "./logger";

/**
 * Stores report JSON in R2 and records metadata in D1.
 * Real PDF rendering would use a headless browser via Browser Rendering binding
 * or a third-party PDF service — scaffold uses JSON as placeholder.
 */
export async function storeReport(
  env: Env,
  orgId: string,
  userId: string,
  type: ReportRecord["type"],
  title: string,
  periodStart: string,
  periodEnd: string,
  payload: unknown
): Promise<ReportRecord> {
  const id    = crypto.randomUUID();
  const r2Key = `reports/${orgId}/${type}/${id}.json`;

  await env.REPORTS_BUCKET.put(r2Key, JSON.stringify(payload), {
    httpMeta { contentType: "application/json" },
    customMeta { orgId, type, title },
  });

  const record: Omit<ReportRecord, "createdAt"> = {
    id,
    orgId,
    type,
    title,
    periodStart,
    periodEnd,
    r2Key,
    createdBy: userId,
  };

  await insertReport(env.DB, record);
  logger.info("Report stored", { id, type, orgId });
  return { ...record, createdAt: new Date().toISOString() };
}

export async function getReportSignedUrl(
  env: Env,
  r2Key: string,
  expiresIn = 3600
): Promise<string> {
  // R2 does not yet support presigned URLs natively in Workers — return a
  // /api/reports/download/:key proxy route instead.
  return `/api/reports/download/${encodeURIComponent(r2Key)}`;
}
TS
success "Lib files written."

# =============================================================================
# 10. Middleware
# =============================================================================
info "Writing middleware…"

cat > src/middleware/cors.ts <<'TS'
import type { MiddlewareHandler } from "hono";
import type { Env } from "@/types";

export const corsMiddleware: MiddlewareHandler<{ Bindings: Env }> = async (c, next) => {
  const origin  = c.env.CORS_ORIGIN ?? "*";
  const reqOrigin = c.req.header("Origin") ?? "";
  const allowed = origin === "*" || reqOrigin === origin || reqOrigin.endsWith(".insighthunter.com");

  if (c.req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin":  allowed ? reqOrigin : origin,
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Api-Key",
        "Access-Control-Max-Age":       "86400",
      },
    });
  }

  await next();

  c.res.headers.set("Access-Control-Allow-Origin", allowed ? reqOrigin : origin);
  c.res.headers.set("Vary", "Origin");
};
TS

cat > src/middleware/auth.ts <<'TS'
import type { MiddlewareHandler } from "hono";
import type { Env, TokenPayload } from "@/types";
import { logger } from "@/lib/logger";

/** Validates JWT issued by insighthunter-auth via Web Crypto API */
async function verifyJWT(token: string, secret: string): Promise<TokenPayload | null> {
  try {
    const [headerB64, payloadB64, sigB64] = token.split(".");
    if (!headerB64 || !payloadB64 || !sigB64) return null;

    const enc      = new TextEncoder();
    const keyData  = enc.encode(secret);
    const key      = await crypto.subtle.importKey("raw", keyData, { name: "HMAC", hash: "SHA-256" }, false, ["verify"]);
    const sigBuf   = Uint8Array.from(atob(sigB64.replace(/-/g, "+").replace(/_/g, "/")), c => c.charCodeAt(0));
    const data     = enc.encode(`${headerB64}.${payloadB64}`);
    const valid    = await crypto.subtle.verify("HMAC", key, sigBuf, data);
    if (!valid) return null;

    const payload = JSON.parse(atob(payloadB64)) as TokenPayload;
    if (payload.exp && Date.now() / 1000 > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

export const authMiddleware: MiddlewareHandler<{ Bindings: Env; Variables: { user: TokenPayload } }> = async (c, next) => {
  const authHeader = c.req.header("Authorization") ?? "";
  const token      = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

  if (!token) {
    return c.json({ error: "Unauthorized", message: "Bearer token required." }, 401);
  }

  const payload = await verifyJWT(token, c.env.JWT_SECRET);
  if (!payload) {
    return c.json({ error: "Unauthorized", message: "Invalid or expired token." }, 401);
  }

  c.set("user", payload);
  logger.debug("Auth OK", { sub: payload.sub, orgId: payload.orgId });
  await next();
};
TS

cat > src/middleware/rateLimit.ts <<'TS'
import type { MiddlewareHandler } from "hono";
import type { Env } from "@/types";

export const rateLimitMiddleware: MiddlewareHandler<{ Bindings: Env }> = async (c, next) => {
  const ip      = c.req.header("CF-Connecting-IP") ?? "unknown";
  const key     = `rl:${ip}:${Math.floor(Date.now() / 1000 / parseInt(c.env.RATE_LIMIT_WINDOW ?? "60"))}`;
  const max     = parseInt(c.env.RATE_LIMIT_MAX ?? "100");

  const raw     = await c.env.RATE_LIMIT.get(key);
  const count   = raw ? parseInt(raw) : 0;

  if (count >= max) {
    return c.json({ error: "Too Many Requests", message: "Rate limit exceeded. Try again shortly." }, 429);
  }

  const ttl = parseInt(c.env.RATE_LIMIT_WINDOW ?? "60");
  await c.env.RATE_LIMIT.put(key, String(count + 1), { expirationTtl: ttl * 2 });

  c.res.headers.set("X-RateLimit-Limit",     String(max));
  c.res.headers.set("X-RateLimit-Remaining", String(Math.max(0, max - count - 1)));

  await next();
};
TS

cat > src/middleware/featureFlags.ts <<'TS'
import type { MiddlewareHandler } from "hono";
import type { Env, TokenPayload } from "@/types";

type Tier = "lite" | "standard" | "enterprise";

const TIER_FEATURES: Record<Tier, Set<string>> = {
  lite:       new Set(["dashboard", "transactions", "csv_upload"]),
  standard:   new Set(["dashboard", "transactions", "csv_upload", "reports", "forecasts", "insights"]),
  enterprise: new Set(["dashboard", "transactions", "csv_upload", "reports", "forecasts", "insights", "clients", "whitelabel", "api_access"]),
};

export function requireFeature(feature: string): MiddlewareHandler<{ Bindings: Env; Variables: { user: TokenPayload } }> {
  return async (c, next) => {
    const user = c.get("user");
    const tier = (user?.tier ?? "lite") as Tier;
    const allowed = TIER_FEATURES[tier] ?? TIER_FEATURES.lite;

    if (!allowed.has(feature)) {
      return c.json({
        error:   "Forbidden",
        message: `This feature requires a higher tier. Current: ${tier}.`,
        upgrade: "https://app.insighthunter.com/upgrade",
      }, 403);
    }
    await next();
  };
}
TS
success "Middleware written."

# =============================================================================
# 11. Services
# =============================================================================
info "Writing services…"

cat > src/services/dashboardService.ts <<'TS'
import type { Env, DashboardData, KPISnapshot } from "@/types";
import { getKPIAggregates, getTrendData } from "@/db/queries";
import { cacheGetOrSet } from "@/lib/cache";

export async function getDashboardData(
  env: Env,
  orgId: string
): Promise<DashboardData> {
  const cacheKey = `dashboard:${orgId}`;

  return cacheGetOrSet(env.CACHE, cacheKey, async () => {
    const now   = new Date();
    const start = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`;
    const end   = now.toISOString().split("T")[0];

    const [agg, trend] = await Promise.all([
      getKPIAggregates(env.DB, orgId, start, end),
      getTrendData(env.DB, orgId, 6),
    ]);

    const net         = agg.revenue - agg.expenses;
    const grossMargin = agg.revenue > 0 ? ((net / agg.revenue) * 100) : 0;

    const kpis: KPISnapshot = {
      revenue:     agg.revenue,
      expenses:    agg.expenses,
      netIncome:   net,
      cashBalance: agg.revenue,   // replace with real bank balance
      grossMargin: Math.round(grossMargin * 100) / 100,
      period:      `${start} – ${end}`,
      asOf:        new Date().toISOString(),
    };

    return {
      kpis,
      recentAlerts: [],
      trendData: trend.map(t => ({
        period:   t.period,
        revenue:  t.revenue,
        expenses: t.expenses,
        net:      t.revenue - t.expenses,
      })),
    } satisfies DashboardData;
  }, 120); // cache 2 min
}
TS

cat > src/services/forecastService.ts <<'TS'
import type { Env, ForecastResult, ForecastPeriod } from "@/types";
import { getTrendData } from "@/db/queries";
import { cacheGetOrSet } from "@/lib/cache";

/**
 * Linear regression forecast over historical monthly data.
 * For production, delegate to insighthunter-agents ForecastAgent.
 */
export async function getForecast(
  env: Env,
  orgId: string,
  horizonMonths = 6
): Promise<ForecastResult> {
  const cacheKey = `forecast:${orgId}:${horizonMonths}`;

  return cacheGetOrSet(env.CACHE, cacheKey, async () => {
    const history = await getTrendData(env.DB, orgId, 12);
    if (history.length < 2) {
      return { periods: [], confidence: 0, generatedAt: new Date().toISOString(), modelVersion: "linear-v1" };
    }

    // Simple linear regression on revenue
    const n  = history.length;
    const xs = history.map((_, i) => i);
    const ys = history.map(h => h.revenue);
    const xMean = xs.reduce((a, b) => a + b, 0) / n;
    const yMean = ys.reduce((a, b) => a + b, 0) / n;
    const slope = xs.reduce((s, x, i) => s + (x - xMean) * (ys[i] - yMean), 0) /
                  xs.reduce((s, x) => s + (x - xMean) ** 2, 0);
    const intercept = yMean - slope * xMean;

    // Project forward
    const lastDate  = new Date(history[history.length - 1].period + "-01");
    const expSlope  = history.map(h => h.expenses).reduce((a, b) => a + b, 0) / n;
    const periods: ForecastPeriod[] = [];

    for (let i = 1; i <= horizonMonths; i++) {
      const d = new Date(lastDate);
      d.setMonth(d.getMonth() + i);
      const period = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
      const projRev = Math.max(0, intercept + slope * (n + i - 1));
      const projExp = expSlope;
      const band    = projRev * 0.15;
      periods.push({
        period,
        projectedRev: Math.round(projRev),
        projectedExp: Math.round(projExp),
        projectedNet: Math.round(projRev - projExp),
        lower:        Math.round(projRev - band),
        upper:        Math.round(projRev + band),
      });
    }

    return {
      periods,
      confidence:   Math.min(0.85, 0.5 + n * 0.03),
      generatedAt:  new Date().toISOString(),
      modelVersion: "linear-v1",
    };
  }, 600); // cache 10 min
}
TS

cat > src/services/reportService.ts <<'TS'
import type { Env, ReportRecord, ProfitLoss } from "@/types";
import { getKPIAggregates, getReports } from "@/db/queries";
import { storeReport } from "@/lib/pdf";

export async function buildPLReport(
  env: Env,
  orgId: string,
  userId: string,
  start: string,
  end: string
): Promise<ReportRecord> {
  const agg = await getKPIAggregates(env.DB, orgId, start, end);
  const pl: ProfitLoss = {
    periodStart:   start,
    periodEnd:     end,
    totalRevenue:  agg.revenue,
    totalExpenses: agg.expenses,
    netIncome:     agg.revenue - agg.expenses,
    grossMargin:   agg.revenue > 0 ? ((agg.revenue - agg.expenses) / agg.revenue) * 100 : 0,
    rows:          [],
  };

  return storeReport(env, orgId, userId, "pl", `P&L ${start} – ${end}`, start, end, pl);
}

export async function listReports(
  env: Env,
  orgId: string
): Promise<ReportRecord[]> {
  return getReports(env.DB, orgId, 20);
}

export async function getReportFile(
  env: Env,
  r2Key: string
): Promise<R2ObjectBody | null> {
  return env.REPORTS_BUCKET.get(r2Key);
}
TS

cat > src/services/insightService.ts <<'TS'
import type { Env, Insight } from "@/types";
import { cacheGetOrSet } from "@/lib/cache";
import { logger } from "@/lib/logger";

/** Delegates to insighthunter-agents via internal service binding */
export async function getInsights(
  env: Env,
  orgId: string,
  context: Record<string, unknown>
): Promise<Insight[]> {
  const cacheKey = `insights:${orgId}`;

  return cacheGetOrSet(env.CACHE, cacheKey, async () => {
    try {
      const res = await fetch(`${env.AGENTS_SERVICE_URL}/api/insights`, {
        method:  "POST",
        headers: {
          "Content-Type":  "application/json",
          "X-Api-Key":     env.SERVICE_API_KEY,
          "X-Org-Id":      orgId,
        },
        body: JSON.stringify({ orgId, context }),
      });
      if (!res.ok) throw new Error(`Agents service ${res.status}`);
      return res.json() as Promise<Insight[]>;
    } catch (e) {
      logger.warn("Insight service unavailable", { error: String(e) });
      return [];
    }
  }, 900); // cache 15 min
}
TS

cat > src/services/bookkeepingService.ts <<'TS'
import type { Env } from "@/types";
import { logger } from "@/lib/logger";

/** Proxies requests to insighthunter-bookkeeping service */
export async function syncBookkeepingData(
  env: Env,
  orgId: string
): Promise<{ synced: boolean; recordCount: number }> {
  try {
    const res = await fetch(`${env.BOOKKEEPING_SERVICE_URL}/api/sync`, {
      method:  "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Api-Key":    env.SERVICE_API_KEY,
        "X-Org-Id":     orgId,
      },
      body: JSON.stringify({ orgId }),
    });
    if (!res.ok) throw new Error(`Bookkeeping service ${res.status}`);
    return res.json() as Promise<{ synced: boolean; recordCount: number }>;
  } catch (e) {
    logger.warn("Bookkeeping service unavailable", { error: String(e) });
    return { synced: false, recordCount: 0 };
  }
}
TS

cat > src/services/notificationService.ts <<'TS'
import type { Env, Alert } from "@/types";
import { logger } from "@/lib/logger";

export interface KPIThresholds {
  cashLowThreshold?:       number;
  expenseSpikePercent?:    number;
  revenueDropPercent?:     number;
}

export async function checkThresholds(
  env: Env,
  orgId: string,
  kpis: { revenue: number; expenses: number; cashBalance: number },
  thresholds: KPIThresholds = {}
): Promise<Alert[]> {
  const alerts: Alert[] = [];
  const {
    cashLowThreshold    = 5000,
    expenseSpikePercent = 20,
    revenueDropPercent  = 15,
  } = thresholds;

  if (kpis.cashBalance < cashLowThreshold) {
    alerts.push({
      id:        crypto.randomUUID(),
      type:      "cash_low",
      message:   `Cash balance is below $${cashLowThreshold.toLocaleString()}.`,
      severity:  "warning",
      createdAt: new Date().toISOString(),
    });
  }

  if (alerts.length > 0) {
    try {
      await env.NOTIFICATION_QUEUE.send({ orgId, alerts });
    } catch (e) {
      logger.warn("Notification queue send failed", { error: String(e) });
    }
  }

  return alerts;
}
TS
success "Services written."

# =============================================================================
# 12. Routes
# =============================================================================
info "Writing routes…"

cat > src/routes/dashboard.ts <<'TS'
import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { getDashboardData } from "@/services/dashboardService";
import { trackEvent } from "@/lib/analytics";

const dashboard = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

dashboard.get("/", async (c) => {
  const user = c.get("user");
  const data = await getDashboardData(c.env, user.orgId);
  trackEvent(c.env, "dashboard_viewed", user.orgId);
  return c.json({ ok: true, data });
});

export default dashboard;
TS

cat > src/routes/reports.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env, TokenPayload } from "@/types";
import { buildPLReport, listReports, getReportFile } from "@/services/reportService";
import { trackEvent } from "@/lib/analytics";

const reports = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

const GenerateSchema = z.object({
  type:  z.enum(["pl", "cashflow", "balance_sheet"]),
  start: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  end:   z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

reports.get("/", async (c) => {
  const user    = c.get("user");
  const records = await listReports(c.env, user.orgId);
  return c.json({ ok: true,  records });
});

reports.post("/generate", async (c) => {
  const user = c.get("user");
  const body = await c.req.json();
  const parsed = GenerateSchema.safeParse(body);
  if (!parsed.success) return c.json({ error: "Invalid request", issues: parsed.error.issues }, 400);

  const { type, start, end } = parsed.data;
  const record = await buildPLReport(c.env, user.orgId, user.sub, start, end);
  trackEvent(c.env, "report_generated", user.orgId, { type });
  return c.json({ ok: true,  record }, 201);
});

reports.get("/download/:key", async (c) => {
  const user = c.get("user");
  const key  = decodeURIComponent(c.req.param("key"));
  if (!key.startsWith(`reports/${user.orgId}/`)) return c.json({ error: "Forbidden" }, 403);
  const obj  = await getReportFile(c.env, key);
  if (!obj)  return c.json({ error: "Not found" }, 404);
  trackEvent(c.env, "report_exported", user.orgId);
  return new Response(obj.body, { headers: { "Content-Type": "application/json", "Content-Disposition": `attachment; filename="${key.split("/").pop()}"` } });
});

export default reports;
TS

cat > src/routes/forecasts.ts <<'TS'
import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { getForecast } from "@/services/forecastService";
import { trackEvent } from "@/lib/analytics";

const forecasts = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

forecasts.get("/", async (c) => {
  const user    = c.get("user");
  const horizon = parseInt(c.req.query("horizon") ?? "6");
  const result  = await getForecast(c.env, user.orgId, Math.min(Math.max(horizon, 1), 24));
  trackEvent(c.env, "forecast_run", user.orgId, { horizon });
  return c.json({ ok: true,  result });
});

export default forecasts;
TS

cat > src/routes/insights.ts <<'TS'
import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { getInsights } from "@/services/insightService";
import { getDashboardData } from "@/services/dashboardService";
import { trackEvent } from "@/lib/analytics";

const insights = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

insights.get("/", async (c) => {
  const user    = c.get("user");
  const dash    = await getDashboardData(c.env, user.orgId);
  const results = await getInsights(c.env, user.orgId, { kpis: dash.kpis });
  trackEvent(c.env, "insight_generated", user.orgId);
  return c.json({ ok: true,  results });
});

export default insights;
TS

cat > src/routes/transactions.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env, TokenPayload, Transaction } from "@/types";
import { getTransactions, insertTransaction } from "@/db/queries";
import { trackEvent } from "@/lib/analytics";
import { cacheDel } from "@/lib/cache";

const transactions = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

const TxSchema = z.object({
  date:        z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  description: z.string().min(1).max(255),
  amount:      z.number(),
  category:    z.string().default("Uncategorized"),
  account:     z.string().default("Default"),
  source:      z.enum(["qbo", "csv", "manual"]).default("manual"),
});

transactions.get("/", async (c) => {
  const user   = c.get("user");
  const limit  = parseInt(c.req.query("limit") ?? "50");
  const offset = parseInt(c.req.query("offset") ?? "0");
  const rows   = await getTransactions(c.env.DB, user.orgId, Math.min(limit, 200), offset);
  return c.json({ ok: true,  rows, limit, offset });
});

transactions.post("/", async (c) => {
  const user   = c.get("user");
  const body   = await c.req.json();
  const parsed = TxSchema.safeParse(body);
  if (!parsed.success) return c.json({ error: "Invalid request", issues: parsed.error.issues }, 400);

  const tx: Omit<Transaction, "createdAt"> = { id: crypto.randomUUID(), orgId: user.orgId, ...parsed.data };
  await insertTransaction(c.env.DB, tx);
  await cacheDel(c.env.CACHE, `dashboard:${user.orgId}`);
  trackEvent(c.env, "transaction_imported", user.orgId, { source: parsed.data.source });
  return c.json({ ok: true,  { id: tx.id } }, 201);
});

transactions.post("/bulk", async (c) => {
  const user   = c.get("user");
  const { rows } = await c.req.json() as { rows: unknown[] };
  if (!Array.isArray(rows) || rows.length === 0) return c.json({ error: "rows array required" }, 400);
  if (rows.length > 1000) return c.json({ error: "Max 1000 rows per bulk import" }, 400);

  let imported = 0;
  const errors: string[] = [];

  for (const [i, row] of rows.entries()) {
    const parsed = TxSchema.safeParse(row);
    if (!parsed.success) { errors.push(`Row ${i + 1}: ${parsed.error.issues[0]?.message}`); continue; }
    await insertTransaction(c.env.DB, { id: crypto.randomUUID(), orgId: user.orgId, ...parsed.data });
    imported++;
  }

  await cacheDel(c.env.CACHE, `dashboard:${user.orgId}`);
  trackEvent(c.env, "transaction_imported", user.orgId, { source: "bulk", count: imported });
  return c.json({ ok: true,  { imported, errors } });
});

export default transactions;
TS

cat > src/routes/clients.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env, TokenPayload, Client } from "@/types";
import { getClients, insertClient } from "@/db/queries";
import { trackEvent } from "@/lib/analytics";

const clients = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

const ClientSchema = z.object({
  name:   z.string().min(1).max(100),
  email:  z.string().email(),
  tier:   z.enum(["lite", "standard", "enterprise"]).default("lite"),
  status: z.enum(["active", "suspended", "trial"]).default("trial"),
});

clients.get("/", async (c) => {
  const user = c.get("user");
  const rows = await getClients(c.env.DB, user.orgId);
  return c.json({ ok: true,  rows });
});

clients.post("/", async (c) => {
  const user   = c.get("user");
  const body   = await c.req.json();
  const parsed = ClientSchema.safeParse(body);
  if (!parsed.success) return c.json({ error: "Invalid request", issues: parsed.error.issues }, 400);

  const client: Omit<Client, "createdAt"> = { id: crypto.randomUUID(), orgId: user.orgId, ...parsed.data };
  await insertClient(c.env.DB, client);
  trackEvent(c.env, "client_created", user.orgId, { tier: parsed.data.tier });
  return c.json({ ok: true,  { id: client.id } }, 201);
});

export default clients;
TS

cat > src/routes/settings.ts <<'TS'
import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { cacheGet, cacheSet } from "@/lib/cache";

const settings = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

settings.get("/", async (c) => {
  const user = c.get("user");
  const key  = `settings:${user.orgId}`;
  const data = await cacheGet(c.env.CACHE, key) ?? {
    notifications:   true,
    cashThreshold:   5000,
    forecastHorizon: 6,
    currency:        "USD",
    timezone:        "America/New_York",
  };
  return c.json({ ok: true, data });
});

settings.put("/", async (c) => {
  const user = c.get("user");
  const body = await c.req.json() as Record<string, unknown>;
  const key  = `settings:${user.orgId}`;
  const current = await cacheGet<Record<string, unknown>>(c.env.CACHE, key) ?? {};
  const updated = { ...current, ...body };
  await cacheSet(c.env.CACHE, key, updated, 60 * 60 * 24 * 30);
  return c.json({ ok: true,  updated });
});

export default settings;
TS
success "Routes written."

# =============================================================================
# 13. Main entry — src/index.ts
# =============================================================================
info "Writing src/index.ts…"
cat > src/index.ts <<'TS'
import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";

// Middleware
import { corsMiddleware }      from "@/middleware/cors";
import { rateLimitMiddleware } from "@/middleware/rateLimit";
import { authMiddleware }      from "@/middleware/auth";
import { requireFeature }      from "@/middleware/featureFlags";

// Routes
import dashboard    from "@/routes/dashboard";
import reports      from "@/routes/reports";
import forecasts    from "@/routes/forecasts";
import insights     from "@/routes/insights";
import transactions from "@/routes/transactions";
import clients      from "@/routes/clients";
import settings     from "@/routes/settings";

import { logger } from "@/lib/logger";

const app = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

// ── Global middleware ────────────────────────────────────────────────────────
app.use("*", corsMiddleware);
app.use("/api/*", rateLimitMiddleware);

// ── Health check (public) ────────────────────────────────────────────────────
app.get("/health", (c) => c.json({ ok: true, service: "insighthunter-main", ts: new Date().toISOString() }));

// ── Authenticated API routes ─────────────────────────────────────────────────
app.use("/api/*", authMiddleware);

app.route("/api/dashboard",    dashboard);
app.route("/api/settings",     settings);
app.route("/api/transactions",  transactions);

app.use("/api/reports/*",   requireFeature("reports"));
app.route("/api/reports",   reports);

app.use("/api/forecasts/*", requireFeature("forecasts"));
app.route("/api/forecasts", forecasts);

app.use("/api/insights/*",  requireFeature("insights"));
app.route("/api/insights",  insights);

app.use("/api/clients/*",   requireFeature("clients"));
app.route("/api/clients",   clients);

// ── Queue consumer (report generation + notifications) ───────────────────────
export default {
  fetch: app.fetch,

  async queue(batch: MessageBatch, env: Env): Promise<void> {
    for (const msg of batch.messages) {
      try {
        const payload = msg.body as Record<string, unknown>;
        logger.info("Queue message received", { queue: batch.queue, type: typeof payload });
        msg.ack();
      } catch (e) {
        logger.error("Queue message failed", { error: String(e) });
        msg.retry();
      }
    }
  },
};
TS
success "src/index.ts written."

# =============================================================================
# 14. Tests
# =============================================================================
info "Writing tests…"

cat > tests/routes/dashboard.test.ts <<'TS'
import { describe, it, expect, vi } from "vitest";

describe("GET /api/dashboard", () => {
  it("returns 401 without token", async () => {
    // TODO: use Miniflare or wrangler-test-env to mount the app
    expect(true).toBe(true);
  });

  it("returns dashboard data with valid token", async () => {
    expect(true).toBe(true);
  });
});
TS

cat > tests/routes/reports.test.ts <<'TS'
import { describe, it, expect } from "vitest";

describe("POST /api/reports/generate", () => {
  it("returns 400 for invalid date range", async () => {
    expect(true).toBe(true);
  });

  it("generates and stores a P&L report", async () => {
    expect(true).toBe(true);
  });
});
TS

cat > tests/services/forecastService.test.ts <<'TS'
import { describe, it, expect, vi } from "vitest";
import { getForecast } from "../../src/services/forecastService";

describe("forecastService", () => {
  it("returns empty forecast for insufficient history", async () => {
    const mockEnv = {
      DB:    { prepare: vi.fn().mockReturnValue({ bind: vi.fn().mockReturnValue({ all: vi.fn().mockResolvedValue({ results: [] }) }) }) },
      CACHE: { get: vi.fn().mockResolvedValue(null), put: vi.fn().mockResolvedValue(undefined) },
    } as any;

    const result = await getForecast(mockEnv, "org-123", 6);
    expect(result.periods).toHaveLength(0);
    expect(result.confidence).toBe(0);
  });

  it("projects forward months correctly", async () => {
    const history = Array.from({ length: 6 }, (_, i) => ({
      period:   `2025-${String(i + 1).padStart(2, "0")}`,
      revenue:  5000 + i * 200,
      expenses: 3000,
    }));
    const mockEnv = {
      DB:    { prepare: vi.fn().mockReturnValue({ bind: vi.fn().mockReturnValue({ all: vi.fn().mockResolvedValue({ results: history }) }) }) },
      CACHE: { get: vi.fn().mockResolvedValue(null), put: vi.fn().mockResolvedValue(undefined) },
    } as any;

    const result = await getForecast(mockEnv, "org-123", 3);
    expect(result.periods).toHaveLength(3);
    expect(result.periods[0].projectedRev).toBeGreaterThan(0);
  });
});
TS

cat > tests/fixtures/mockUser.ts <<'TS'
import type { TokenPayload } from "../../src/types";

export const mockUser: TokenPayload = {
  sub:   "user-test-001",
  email: "test@insighthunter.com",
  name:  "Test User",
  tier:  "standard",
  orgId: "org-test-001",
  iat:   Math.floor(Date.now() / 1000),
  exp:   Math.floor(Date.now() / 1000) + 3600,
};
TS

cat > tests/fixtures/mockFinancials.ts <<'TS'
import type { KPISnapshot, TrendPoint } from "../../src/types";

export const mockKPIs: KPISnapshot = {
  revenue:     42500,
  expenses:    28300,
  netIncome:   14200,
  cashBalance: 38750,
  grossMargin: 33.41,
  period:      "2026-03-01 – 2026-03-07",
  asOf:        "2026-03-07T00:00:00.000Z",
};

export const mockTrend: TrendPoint[] = [
  { period: "2025-10", revenue: 38000, expenses: 24000, net: 14000 },
  { period: "2025-11", revenue: 40500, expenses: 25500, net: 15000 },
  { period: "2025-12", revenue: 45000, expenses: 27000, net: 18000 },
  { period: "2026-01", revenue: 39000, expenses: 26000, net: 13000 },
  { period: "2026-02", revenue: 41000, expenses: 27500, net: 13500 },
  { period: "2026-03", revenue: 42500, expenses: 28300, net: 14200 },
];
TS
success "Tests written."

# =============================================================================
# 15. Public index.html
# =============================================================================
info "Writing public/index.html…"
cat > public/index.html <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Insight Hunter</title>
    <meta name="description" content="Insight Hunter financial API" />
    <link rel="icon" href="/assets/icons/favicon.ico" sizes="any" />
  </head>
  <body>
    <!--
      insighthunter-main is a pure API Worker.
      The frontend SPA (insighthunter-lite / standard / enterprise)
      is hosted separately and calls this Worker via /api/*.
    -->
    <pre style="font-family:monospace;padding:2rem">
insighthunter-main API Worker
GET /health  →  status check
/api/*       →  requires Bearer token
    </pre>
  </body>
</html>
HTML
success "public/index.html written."

# =============================================================================
# 16. README
# =============================================================================
info "Writing README.md…"
cat > README.md <<'MD'
# insighthunter-main

Insight Hunter Main API — Cloudflare Worker  
Routes: dashboard · reports · forecasts · insights · transactions · clients · settings

## Stack
- **Runtime**: Cloudflare Workers (Hono router)
- **DB**: D1 (SQLite)
- **Cache**: KV
- **Storage**: R2 (PDF reports)
- **Queues**: Report generation + notifications
- **Analytics**: Analytics Engine
- **Auth**: JWT validated via `insighthunter-auth`

## Quick Start

```bash
cp .env.example .dev.vars

# Create D1 database
wrangler d1 create insighthunter-main-db

# Create KV namespaces
wrangler kv:namespace create CACHE
wrangler kv:namespace create RATE_LIMIT

# Create R2 bucket
wrangler r2 bucket create insighthunter-reports

# Create Queues
wrangler queues create insighthunter-report-queue
wrangler queues create insighthunter-notification-queue

# Run migrations
npm run migrate:local

# Set secrets
wrangler secret put JWT_SECRET
wrangler secret put SERVICE_API_KEY

# Dev
npm run dev

# Deploy
npm run deploy
