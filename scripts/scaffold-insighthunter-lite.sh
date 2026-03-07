#!/usr/bin/env bash
# =============================================================================
# scaffold-insighthunter-lite.sh
# Scaffolds Insight Hunter Lite — Astro + TypeScript + Tailwind v4
# + Cloudflare Workers adapter, auth, dashboard shell, QBO API routes,
#   CSVUploader Svelte island, and service worker.
#
# Usage:
#   chmod +x scaffold-insighthunter-lite.sh
#   ./scaffold-insighthunter-lite.sh [target-dir]
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
PROJECT_DIR="${1:-insighthunter-lite}"
if [[ -d "$PROJECT_DIR" ]]; then
  warn "Directory '$PROJECT_DIR' already exists."
  read -rp "  Overwrite? (y/N) " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
  rm -rf "$PROJECT_DIR"
fi

echo -e "\n${BOLD}${CYAN}Scaffolding Insight Hunter Lite${RESET}\n"

# =============================================================================
# 1. Directory tree
# =============================================================================
info "Creating directory tree…"
mkdir -p "$PROJECT_DIR"/{src/{pages/{auth,dashboard,api/{auth,qbo}},layouts,components/{ui,charts,dashboard,islands},lib/{auth,qbo,utils},styles,types},public/{icons,fonts},scripts}
success "Directories created."

cd "$PROJECT_DIR"

# =============================================================================
# 2. package.json
# =============================================================================
info "Writing package.json…"
cat > package.json <<'JSON'
{
  "name": "@insighthunter/lite",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev":       "astro dev",
    "build":     "astro build",
    "preview":   "astro preview",
    "deploy":    "npm run build && wrangler pages deploy dist",
    "typecheck": "astro check",
    "lint":      "eslint src --ext .ts,.astro,.svelte"
  },
  "dependencies": {
    "@astrojs/cloudflare": "^12.0.0",
    "@astrojs/svelte":     "^7.0.5",
    "astro":               "^5.0.0",
    "svelte":              "^5.22.5",
    "zod":                 "^3.24.2"
  },
  "devDependencies": {
    "@astrojs/check":            "^0.9.0",
    "@cloudflare/workers-types": "^4.0.0",
    "@tailwindcss/vite":         "^4.0.0",
    "tailwindcss":               "^4.0.0",
    "typescript":                "^5.7.0",
    "wrangler":                  "^4.2.0"
  }
}
JSON
success "package.json written."

# =============================================================================
# 3. astro.config.mjs
# =============================================================================
info "Writing astro.config.mjs…"
cat > astro.config.mjs <<'EOF'
import { defineConfig } from "astro/config";
import cloudflare from "@astrojs/cloudflare";
import svelte from "@astrojs/svelte";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  output: "server",
  adapter: cloudflare({
    platformProxy: { enabled: true },
    imageService: "cloudflare",
  }),
  integrations: [svelte()],
  vite: {
    plugins: [tailwindcss()],
    ssr: {
      external: ["node:buffer", "node:path", "node:stream", "node:util"],
    },
  },
  security: {
    checkOrigin: true,
  },
});
EOF
success "astro.config.mjs written."

# =============================================================================
# 4. svelte.config.js
# =============================================================================
info "Writing svelte.config.js…"
cat > svelte.config.js <<'EOF'
import { vitePreprocess } from "@astrojs/svelte";

export default {
  preprocess: vitePreprocess(),
};
EOF
success "svelte.config.js written."

# =============================================================================
# 5. wrangler.toml
# =============================================================================
info "Writing wrangler.toml…"
cat > wrangler.toml <<'EOF'
name               = "insighthunter-lite"
compatibility_date = "2025-03-07"
compatibility_flags = ["nodejs_compat"]
pages_build_output_dir = "dist"

[observability]
enabled = true

[[kv_namespaces]]
binding    = "IH_SESSIONS"
id         = "REPLACE_WITH_KV_ID"
preview_id = "REPLACE_WITH_PREVIEW_KV_ID"

[[kv_namespaces]]
binding    = "IH_CACHE"
id         = "REPLACE_WITH_CACHE_KV_ID"
preview_id = "REPLACE_WITH_PREVIEW_CACHE_KV_ID"

[vars]
APP_ENV        = "development"
APP_URL        = "http://localhost:4321"
APP_TIER       = "lite"
SESSION_EXPIRY = "604800"

# Secrets — add via: wrangler secret put SECRET_NAME
# Required: JWT_SECRET, QBO_CLIENT_ID, QBO_CLIENT_SECRET, QBO_REDIRECT_URI
EOF
success "wrangler.toml written."

# =============================================================================
# 6. tsconfig.json
# =============================================================================
info "Writing tsconfig.json…"
cat > tsconfig.json <<'JSON'
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "target":               "ESNext",
    "module":               "ESNext",
    "moduleResolution":     "bundler",
    "strict":               true,
    "verbatimModuleSyntax": true,
    "baseUrl": ".",
    "paths": {
      "@/*":           ["src/*"],
      "@components/*": ["src/components/*"],
      "@layouts/*":    ["src/layouts/*"],
      "@lib/*":        ["src/lib/*"],
      "@types/*":      ["src/types/*"]
    },
    "types": ["@cloudflare/workers-types"]
  },
  "include": ["src/**/*", "scripts/**/*", ".astro/**/*"]
}
JSON
success "tsconfig.json written."

# =============================================================================
# 7. .env.example
# =============================================================================
info "Writing .env.example…"
cat > .env.example <<'EOF'
APP_ENV=development
APP_URL=http://localhost:4321
APP_TIER=lite
JWT_SECRET=replace_with_32_char_random_string
SESSION_EXPIRY=604800
QBO_CLIENT_ID=replace_with_qbo_client_id
QBO_CLIENT_SECRET=replace_with_qbo_client_secret
QBO_REDIRECT_URI=http://localhost:4321/api/qbo/callback
QBO_ENVIRONMENT=sandbox
EOF
success ".env.example written."

# =============================================================================
# 8. .gitignore
# =============================================================================
info "Writing .gitignore…"
cat > .gitignore <<'EOF'
dist/
.astro/
node_modules/
.env
.env.local
.env.*.local
.wrangler/
.dev.vars
.DS_Store
*.log
EOF
success ".gitignore written."

# =============================================================================
# 9. Tailwind global CSS
# =============================================================================
info "Writing src/styles/global.css…"
cat > src/styles/global.css <<'CSS'
@import "tailwindcss";

@theme {
  --color-brand-50:  #eef2ff;
  --color-brand-400: #818cf8;
  --color-brand-500: #6366f1;
  --color-brand-600: #4f46e5;
  --color-brand-700: #4338ca;
  --color-surface-950: #0a0f1e;
  --color-surface-900: #0f172a;
  --color-surface-800: #1e293b;
  --color-surface-700: #334155;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-danger:  #ef4444;
  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
}

html, body {
  @apply bg-surface-950 text-slate-100 antialiased;
  font-family: var(--font-sans);
}

*:focus-visible {
  @apply outline-2 outline-offset-2 outline-brand-500;
}
CSS
success "src/styles/global.css written."

# =============================================================================
# 10. Types
# =============================================================================
info "Writing src/types/index.ts…"
cat > src/types/index.ts <<'TS'
export interface User {
  id:        string;
  email:     string;
  name:      string;
  tier:      "lite" | "standard" | "enterprise";
  createdAt: string;
}

export interface Session {
  userId:    string;
  expiresAt: number;
  token:     string;
}

export interface QBOConnection {
  realmId:      string;
  accessToken:  string;
  refreshToken: string;
  expiresAt:    number;
  companyName:  string;
}

export interface QBOTokenResponse {
  access_token:  string;
  refresh_token: string;
  token_type:    string;
  expires_in:    number;
  x_refresh_token_expires_in: number;
}

export interface ProfitLoss {
  periodStart:   string;
  periodEnd:     string;
  totalRevenue:  number;
  totalExpenses: number;
  netIncome:     number;
  rows:          PLRow[];
}

export interface PLRow {
  account: string;
  amount:  number;
  type:    "income" | "expense";
}

export interface CashSummary {
  balance:  number;
  inflow:   number;
  outflow:  number;
  asOf:     string;
}

export interface CSVRow {
  date:        string;
  description: string;
  amount:      number;
  category:    string;
}

export interface UploadResult {
  rows:     CSVRow[];
  errors:   string[];
  fileName: string;
  uploadedAt: string;
}

export interface Env {
  APP_ENV:           string;
  APP_URL:           string;
  APP_TIER:          string;
  SESSION_EXPIRY:    string;
  JWT_SECRET:        string;
  QBO_CLIENT_ID:     string;
  QBO_CLIENT_SECRET: string;
  QBO_REDIRECT_URI:  string;
  QBO_ENVIRONMENT:   string;
  IH_SESSIONS:       KVNamespace;
  IH_CACHE:          KVNamespace;
}
TS
success "src/types/index.ts written."

# =============================================================================
# 11. Auth lib
# =============================================================================
info "Writing src/lib/auth/session.ts…"
cat > src/lib/auth/session.ts <<'TS'
import type { Session, User } from "@/types";

const SESSION_PREFIX = "session:";
const USER_PREFIX    = "user:";

export async function createSession(
  kv: KVNamespace,
  user: User,
  ttlSeconds: number
): Promise<string> {
  const token     = crypto.randomUUID();
  const expiresAt = Date.now() + ttlSeconds * 1000;
  const session: Session = { userId: user.id, expiresAt, token };
  await kv.put(`${SESSION_PREFIX}${token}`, JSON.stringify(session), { expirationTtl: ttlSeconds });
  return token;
}

export async function getSession(kv: KVNamespace, token: string): Promise<Session | null> {
  const raw = await kv.get(`${SESSION_PREFIX}${token}`);
  if (!raw) return null;
  const session = JSON.parse(raw) as Session;
  if (Date.now() > session.expiresAt) {
    await kv.delete(`${SESSION_PREFIX}${token}`);
    return null;
  }
  return session;
}

export async function deleteSession(kv: KVNamespace, token: string): Promise<void> {
  await kv.delete(`${SESSION_PREFIX}${token}`);
}

export async function getUser(kv: KVNamespace, userId: string): Promise<User | null> {
  const raw = await kv.get(`${USER_PREFIX}${userId}`);
  return raw ? (JSON.parse(raw) as User) : null;
}

export async function saveUser(kv: KVNamespace, user: User): Promise<void> {
  await kv.put(`${USER_PREFIX}${user.id}`, JSON.stringify(user));
}

export function getSessionToken(request: Request): string | null {
  const cookie = request.headers.get("Cookie") ?? "";
  const match  = cookie.match(/ih_session=([^;]+)/);
  return match?.[1] ?? null;
}

export function setSessionCookie(token: string, ttlSeconds: number): string {
  const expires = new Date(Date.now() + ttlSeconds * 1000).toUTCString();
  return `ih_session=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Expires=${expires}`;
}

export function clearSessionCookie(): string {
  return "ih_session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0";
}
TS
success "src/lib/auth/session.ts written."

# =============================================================================
# 12. QBO lib
# =============================================================================
info "Writing src/lib/qbo/client.ts…"
cat > src/lib/qbo/client.ts <<'TS'
import type { QBOConnection, QBOTokenResponse, ProfitLoss, CashSummary } from "@/types";

const QBO_BASE = {
  sandbox:    "https://sandbox-quickbooks.api.intuit.com",
  production: "https://quickbooks.api.intuit.com",
} as const;

export class QBOClient {
  private baseUrl: string;

  constructor(
    private conn: QBOConnection,
    env: "sandbox" | "production" = "sandbox"
  ) {
    this.baseUrl = QBO_BASE[env];
  }

  private async fetch<T>(path: string): Promise<T> {
    const url = `${this.baseUrl}/v3/company/${this.conn.realmId}${path}`;
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${this.conn.accessToken}`, Accept: "application/json" },
    });
    if (!res.ok) throw new Error(`QBO API error ${res.status}: ${await res.text()}`);
    return res.json() as Promise<T>;
  }

  async getProfitAndLoss(startDate: string, endDate: string): Promise<ProfitLoss> {
    const data = await this.fetch<any>(
      `/reports/ProfitAndLoss?start_date=${startDate}&end_date=${endDate}&minorversion=73`
    );
    const rows: ProfitLoss["rows"] = [];
    let totalRevenue = 0, totalExpenses = 0;
    for (const section of data?.Rows?.Row ?? []) {
      const type: "income" | "expense" = section.group === "Income" ? "income" : "expense";
      for (const row of section?.Rows?.Row ?? []) {
        const amount = parseFloat(row?.Summary?.ColData?.[1]?.value ?? "0");
        rows.push({ account: row?.Summary?.ColData?.[0]?.value ?? "", amount, type });
        if (type === "income")  totalRevenue  += amount;
        if (type === "expense") totalExpenses += amount;
      }
    }
    return { periodStart: startDate, periodEnd: endDate, totalRevenue, totalExpenses, netIncome: totalRevenue - totalExpenses, rows };
  }

  async getCashSummary(): Promise<CashSummary> {
    const data = await this.fetch<any>("/reports/BalanceSheet?minorversion=73");
    const cashRow = data?.Rows?.Row?.find((r: any) => r?.Summary?.ColData?.[0]?.value === "Total Current Assets");
    const balance = parseFloat(cashRow?.Summary?.ColData?.[1]?.value ?? "0");
    return { balance, inflow: 0, outflow: 0, asOf: new Date().toISOString() };
  }
}

export async function refreshQBOToken(
  conn: QBOConnection,
  clientId: string,
  clientSecret: string
): Promise<QBOTokenResponse> {
  const creds = btoa(`${clientId}:${clientSecret}`);
  const res = await fetch("https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer", {
    method: "POST",
    headers: { Authorization: `Basic ${creds}`, "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "refresh_token", refresh_token: conn.refreshToken }),
  });
  if (!res.ok) throw new Error(`QBO token refresh failed: ${res.status}`);
  return res.json() as Promise<QBOTokenResponse>;
}
TS
success "src/lib/qbo/client.ts written."

# =============================================================================
# 13. CSV utils lib
# =============================================================================
info "Writing src/lib/utils/csvParser.ts…"
cat > src/lib/utils/csvParser.ts <<'TS'
import type { CSVRow, UploadResult } from "@/types";

export function parseCSV(text: string, fileName: string): UploadResult {
  const lines  = text.trim().split(/\r?\n/);
  const rows: CSVRow[] = [];
  const errors: string[] = [];

  if (lines.length < 2) {
    errors.push("CSV must have a header row and at least one data row.");
    return { rows, errors, fileName, uploadedAt: new Date().toISOString() };
  }

  const headers = lines[0].split(",").map(h => h.trim().toLowerCase().replace(/\s+/g, "_"));
  const dateIdx  = headers.findIndex(h => h.includes("date"));
  const descIdx  = headers.findIndex(h => h.includes("desc") || h.includes("memo") || h.includes("narration"));
  const amtIdx   = headers.findIndex(h => h.includes("amount") || h.includes("debit") || h.includes("credit"));
  const catIdx   = headers.findIndex(h => h.includes("category") || h.includes("type"));

  for (let i = 1; i < lines.length; i++) {
    const cols = lines[i].split(",").map(c => c.trim().replace(/^"|"$/g, ""));
    if (cols.length < 2) continue;
    const amount = parseFloat(cols[amtIdx] ?? "0");
    if (isNaN(amount)) { errors.push(`Row ${i + 1}: invalid amount "${cols[amtIdx]}"`); continue; }
    rows.push({
      date:        cols[dateIdx] ?? "",
      description: cols[descIdx] ?? "",
      amount,
      category:    cols[catIdx]  ?? "Uncategorized",
    });
  }

  return { rows, errors, fileName, uploadedAt: new Date().toISOString() };
}

export function formatCurrency(n: number): string {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(n);
}
TS
success "src/lib/utils/csvParser.ts written."

# =============================================================================
# 14. Middleware
# =============================================================================
info "Writing src/middleware.ts…"
cat > src/middleware.ts <<'TS'
import { defineMiddleware } from "astro:middleware";
import { getSession, getUser, getSessionToken } from "@/lib/auth/session";
import type { Env } from "@/types";

const PUBLIC_PATHS = new Set(["/", "/auth/login", "/auth/register", "/auth/forgot-password", "/auth/reset-password"]);
const API_PUBLIC   = new Set(["/api/auth/login", "/api/auth/register", "/api/auth/logout", "/api/auth/forgot-password", "/api/auth/reset-password", "/api/qbo/callback"]);

export const onRequest = defineMiddleware(async ({ locals, request, redirect, url }, next) => {
  const env  = (locals as any).runtime?.env as Env | undefined;
  const path = url.pathname;
  if (PUBLIC_PATHS.has(path) || API_PUBLIC.has(path) || path.startsWith("/_") || path.startsWith("/icons") || path.match(/\.(ico|webmanifest|js|css|png|svg|woff2?)$/)) {
    return next();
  }
  if (!env) return next();
  const token   = getSessionToken(request);
  if (!token)   return redirect("/auth/login?next=" + encodeURIComponent(path), 302);
  const session = await getSession(env.IH_SESSIONS, token);
  if (!session) return redirect("/auth/login?expired=1", 302);
  const user    = await getUser(env.IH_SESSIONS, session.userId);
  if (!user)    return redirect("/auth/login", 302);
  (locals as any).user    = user;
  (locals as any).session = session;
  return next();
});
TS
success "src/middleware.ts written."

# =============================================================================
# 15. Layouts
# =============================================================================
info "Writing layouts…"
cat > src/layouts/AuthLayout.astro <<'ASTRO'
---
interface Props { title?: string }
const { title = "Insight Hunter" } = Astro.props;
---
<!doctype html>
<html lang="en" class="h-full">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="robots" content="noindex, nofollow" />
    <title>{title} | Insight Hunter Lite</title>
    <link rel="icon" href="/favicon.ico" sizes="any" />
    <link rel="manifest" href="/manifest.webmanifest" />
    <link rel="stylesheet" href="/src/styles/global.css" />
  </head>
  <body class="h-full bg-surface-950 text-slate-100 antialiased">
    <div class="min-h-full flex flex-col justify-center items-center px-4 py-12">
      <div class="mb-8 flex flex-col items-center gap-2">
        <a href="/"><img src="/icons/icon-192.png" alt="Insight Hunter" width="48" height="48" class="rounded-xl" /></a>
        <span class="text-xl font-semibold text-white">Insight Hunter</span>
        <span class="text-xs text-brand-400 font-medium tracking-widest uppercase">Lite</span>
      </div>
      <div class="w-full max-w-md bg-surface-800 border border-surface-700 rounded-2xl shadow-xl px-8 py-10">
        <slot />
      </div>
      <p class="mt-8 text-center text-xs text-slate-500">
        &copy; {new Date().getFullYear()} Insight Hunter &middot;
        <a href="/privacy" class="underline hover:text-slate-300">Privacy</a> &middot;
        <a href="/terms"   class="underline hover:text-slate-300">Terms</a>
      </p>
    </div>
  </body>
</html>
ASTRO

cat > src/layouts/DashboardLayout.astro <<'ASTRO'
---
import type { User } from "@/types";
interface Props { title?: string }
const { title = "Dashboard" } = Astro.props;
const user = Astro.locals.user as User | undefined;
---
<!doctype html>
<html lang="en" class="h-full">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="robots" content="noindex, nofollow" />
    <title>{title} — Insight Hunter Lite</title>
    <link rel="icon" href="/favicon.ico" sizes="any" />
    <link rel="manifest" href="/manifest.webmanifest" />
    <link rel="stylesheet" href="/src/styles/global.css" />
  </head>
  <body class="h-full bg-surface-950 text-slate-100 antialiased flex">
    <nav class="hidden md:flex flex-col w-60 bg-surface-900 border-r border-surface-800 px-4 py-6 gap-1 shrink-0">
      <div class="flex items-center gap-2 mb-8 px-2">
        <img src="/icons/icon-192.png" alt="" width="28" height="28" class="rounded-lg" />
        <span class="font-semibold text-white text-sm">Insight Hunter</span>
        <span class="ml-auto text-[10px] bg-brand-600 text-white px-1.5 py-0.5 rounded font-bold tracking-wide">LITE</span>
      </div>
      <a href="/dashboard"             class="nav-link">📊 Overview</a>
      <a href="/dashboard/profit-loss" class="nav-link">📈 Profit & Loss</a>
      <a href="/dashboard/cash-flow"   class="nav-link">💰 Cash Flow</a>
      <a href="/dashboard/upload"      class="nav-link">📂 Upload CSV</a>
      <a href="/dashboard/connect"     class="nav-link">🔗 QuickBooks</a>
      <a href="/settings"              class="nav-link mt-auto">⚙️ Settings</a>
      <form action="/api/auth/logout" method="POST" class="mt-2">
        <button type="submit" class="nav-link w-full text-left text-red-400 hover:bg-red-900/20">🚪 Sign Out</button>
      </form>
    </nav>
    <div class="flex-1 flex flex-col min-w-0">
      <header class="h-14 border-b border-surface-800 bg-surface-900 flex items-center px-6 gap-4 shrink-0">
        <h1 class="text-sm font-semibold text-white flex-1">{title}</h1>
        {user && <span class="text-xs text-slate-400">{user.name} · {user.email}</span>}
      </header>
      <main class="flex-1 overflow-y-auto p-6"><slot /></main>
    </div>
  </body>
</html>
<style>
  .nav-link { @apply flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-slate-300 hover:bg-surface-800 hover:text-white transition-colors; }
</style>
ASTRO
success "Layouts written."

# =============================================================================
# 16. Pages — Auth
# =============================================================================
info "Writing auth pages…"
cat > src/pages/auth/login.astro <<'ASTRO'
---
import AuthLayout from "@/layouts/AuthLayout.astro";
const next    = Astro.url.searchParams.get("next") ?? "/dashboard";
const expired = Astro.url.searchParams.has("expired");
---
<AuthLayout title="Sign In">
  {expired && <p class="mb-4 rounded-lg bg-yellow-900/40 border border-yellow-700 px-4 py-2 text-sm text-yellow-300">Session expired. Please sign in again.</p>}
  <h1 class="text-2xl font-semibold text-white mb-1">Welcome back</h1>
  <p class="text-sm text-slate-400 mb-6">Sign in to your Insight Hunter account.</p>
  <form id="login-form" novalidate class="space-y-4">
    <input type="hidden" name="next" value={next} />
    <div>
      <label for="email" class="block text-sm font-medium text-slate-300 mb-1.5">Email</label>
      <input id="email" name="email" type="email" required autocomplete="email" class="ih-input" placeholder="you@company.com" />
    </div>
    <div>
      <label for="password" class="block text-sm font-medium text-slate-300 mb-1.5">Password</label>
      <input id="password" name="password" type="password" required autocomplete="current-password" class="ih-input" placeholder="Your password" />
    </div>
    <div id="error-msg" class="hidden rounded-lg bg-red-900/40 border border-red-700 px-4 py-2 text-sm text-red-300"></div>
    <button type="submit" class="ih-btn-primary w-full">Sign In</button>
  </form>
  <p class="mt-4 text-center text-sm text-slate-500"><a href="/auth/forgot-password" class="text-brand-400 hover:text-brand-300 underline">Forgot password?</a></p>
  <p class="mt-2 text-center text-sm text-slate-500">No account? <a href="/auth/register" class="text-brand-400 hover:text-brand-300 underline">Sign up free</a></p>
</AuthLayout>
<style>
  .ih-input { @apply w-full rounded-lg border border-surface-700 bg-surface-900 px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition; }
  .ih-btn-primary { @apply rounded-lg bg-brand-600 hover:bg-brand-500 disabled:bg-surface-700 disabled:cursor-not-allowed px-4 py-2.5 text-sm font-semibold text-white transition-colors; }
</style>
<script>
  const form = document.getElementById("login-form") as HTMLFormElement;
  const errorMsg = document.getElementById("error-msg")!;
  const btn = form.querySelector("button[type=submit]") as HTMLButtonElement;
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    btn.disabled = true; btn.textContent = "Signing in…"; errorMsg.classList.add("hidden");
    const fd = new FormData(form);
    try {
      const res = await fetch("/api/auth/login", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email: fd.get("email"), password: fd.get("password") }) });
      if (!res.ok) { const { message } = await res.json().catch(() => ({ message: "Login failed." })); throw new Error(message); }
      window.location.href = (fd.get("next") as string) || "/dashboard";
    } catch (err) {
      errorMsg.textContent = err instanceof Error ? err.message : "Login failed.";
      errorMsg.classList.remove("hidden"); btn.disabled = false; btn.textContent = "Sign In";
    }
  });
</script>
ASTRO

cat > src/pages/auth/register.astro <<'ASTRO'
---
import AuthLayout from "@/layouts/AuthLayout.astro";
---
<AuthLayout title="Create Account">
  <h1 class="text-2xl font-semibold text-white mb-1">Get started free</h1>
  <p class="text-sm text-slate-400 mb-6">Create your Insight Hunter Lite account.</p>
  <form id="register-form" novalidate class="space-y-4">
    <div>
      <label for="name" class="block text-sm font-medium text-slate-300 mb-1.5">Full Name</label>
      <input id="name" name="name" type="text" required autocomplete="name" class="ih-input" placeholder="Jane Smith" />
    </div>
    <div>
      <label for="email" class="block text-sm font-medium text-slate-300 mb-1.5">Work Email</label>
      <input id="email" name="email" type="email" required autocomplete="email" class="ih-input" placeholder="jane@company.com" />
    </div>
    <div>
      <label for="password" class="block text-sm font-medium text-slate-300 mb-1.5">Password</label>
      <input id="password" name="password" type="password" required minlength="8" autocomplete="new-password" class="ih-input" placeholder="At least 8 characters" />
    </div>
    <div id="error-msg" class="hidden rounded-lg bg-red-900/40 border border-red-700 px-4 py-2 text-sm text-red-300"></div>
    <button type="submit" class="ih-btn-primary w-full">Create Account</button>
  </form>
  <p class="mt-4 text-center text-sm text-slate-500">Already have an account? <a href="/auth/login" class="text-brand-400 hover:text-brand-300 underline">Sign in</a></p>
</AuthLayout>
<style>
  .ih-input { @apply w-full rounded-lg border border-surface-700 bg-surface-900 px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition; }
  .ih-btn-primary { @apply rounded-lg bg-brand-600 hover:bg-brand-500 disabled:bg-surface-700 disabled:cursor-not-allowed px-4 py-2.5 text-sm font-semibold text-white transition-colors; }
</style>
<script>
  const form = document.getElementById("register-form") as HTMLFormElement;
  const errorMsg = document.getElementById("error-msg")!;
  const btn = form.querySelector("button[type=submit]") as HTMLButtonElement;
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    btn.disabled = true; btn.textContent = "Creating account…"; errorMsg.classList.add("hidden");
    const fd = new FormData(form);
    try {
      const res = await fetch("/api/auth/register", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: fd.get("name"), email: fd.get("email"), password: fd.get("password") }) });
      if (!res.ok) { const { message } = await res.json().catch(() => ({ message: "Registration failed." })); throw new Error(message); }
      window.location.href = "/dashboard";
    } catch (err) {
      errorMsg.textContent = err instanceof Error ? err.message : "Registration failed.";
      errorMsg.classList.remove("hidden"); btn.disabled = false; btn.textContent = "Create Account";
    }
  });
</script>
ASTRO

cat > src/pages/auth/forgot-password.astro <<'ASTRO'
---
import AuthLayout from "@/layouts/AuthLayout.astro";
---
<AuthLayout title="Forgot Password">
  <h1 class="text-2xl font-semibold text-white mb-1">Reset your password</h1>
  <p class="text-sm text-slate-400 mb-6">Enter your email and we'll send a reset link.</p>
  <div id="success-state" class="hidden text-center space-y-3">
    <div class="text-4xl">📬</div>
    <p class="text-sm text-emerald-300">Check your inbox. The link expires in 1 hour.</p>
    <a href="/auth/login" class="inline-block text-sm text-brand-400 underline">Back to login</a>
  </div>
  <form id="forgot-form" novalidate class="space-y-4">
    <div>
      <label for="email" class="block text-sm font-medium text-slate-300 mb-1.5">Email</label>
      <input id="email" name="email" type="email" required autocomplete="email" class="ih-input" placeholder="you@company.com" />
    </div>
    <div id="error-msg" class="hidden rounded-lg bg-red-900/40 border border-red-700 px-4 py-2 text-sm text-red-300"></div>
    <button type="submit" class="ih-btn-primary w-full">Send Reset Link</button>
  </form>
</AuthLayout>
<style>
  .ih-input { @apply w-full rounded-lg border border-surface-700 bg-surface-900 px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition; }
  .ih-btn-primary { @apply rounded-lg bg-brand-600 hover:bg-brand-500 disabled:bg-surface-700 px-4 py-2.5 text-sm font-semibold text-white transition-colors; }
</style>
<script>
  const form = document.getElementById("forgot-form") as HTMLFormElement;
  const successState = document.getElementById("success-state")!;
  const errorMsg = document.getElementById("error-msg")!;
  const btn = form.querySelector("button[type=submit]") as HTMLButtonElement;
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    btn.disabled = true; btn.textContent = "Sending…"; errorMsg.classList.add("hidden");
    const fd = new FormData(form);
    try {
      const res = await fetch("/api/auth/forgot-password", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email: fd.get("email") }) });
      if (!res.ok) throw new Error("Request failed.");
      form.classList.add("hidden"); successState.classList.remove("hidden");
    } catch {
      errorMsg.textContent = "Could not send reset link. Please try again.";
      errorMsg.classList.remove("hidden"); btn.disabled = false; btn.textContent = "Send Reset Link";
    }
  });
</script>
ASTRO
success "Auth pages written."

# =============================================================================
# 17. Pages — Dashboard
# =============================================================================
info "Writing dashboard pages…"

cat > src/pages/dashboard/index.astro <<'ASTRO'
---
import DashboardLayout from "@/layouts/DashboardLayout.astro";
import type { User } from "@/types";
const user = Astro.locals.user as User;
---
<DashboardLayout title="Overview">
  <div class="mb-6">
    <h2 class="text-lg font-semibold text-white">Good to see you, {user.name.split(" ")[0]} 👋</h2>
    <p class="text-sm text-slate-400 mt-0.5">Here's a snapshot of your business finances.</p>
  </div>
  <div id="kpi-grid" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
    {["Revenue", "Expenses", "Net Income", "Cash Balance"].map(label => (
      <div class="bg-surface-800 border border-surface-700 rounded-xl p-5">
        <p class="text-xs text-slate-400 uppercase tracking-widest mb-1">{label}</p>
        <p class="text-2xl font-bold text-white kpi-value">—</p>
        <p class="text-xs text-slate-500 mt-1 kpi-period">Loading…</p>
      </div>
    ))}
  </div>
  <div id="connect-prompt" class="hidden rounded-xl border border-brand-700 bg-brand-900/20 px-6 py-5 flex items-center gap-4">
    <div class="text-3xl">🔗</div>
    <div>
      <p class="font-medium text-white text-sm">Connect QuickBooks to see live data</p>
      <p class="text-xs text-slate-400 mt-0.5">Sync your P&L, cash flow, and more in seconds.</p>
    </div>
    <a href="/dashboard/connect" class="ml-auto shrink-0 rounded-lg bg-brand-600 hover:bg-brand-500 px-4 py-2 text-sm font-semibold text-white transition-colors">Connect</a>
  </div>
</DashboardLayout>
<script>
  async function loadKPIs() {
    try {
      const res = await fetch("/api/qbo/summary");
      if (res.status === 404) { document.getElementById("connect-prompt")?.classList.remove("hidden"); return; }
      if (!res.ok) return;
      const data = await res.json() as { revenue: number; expenses: number; netIncome: number; cash: number; period: string };
      const fmt  = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });
      document.querySelectorAll(".kpi-value").forEach((el, i) => {
        (el as HTMLElement).textContent = fmt.format([data.revenue, data.expenses, data.netIncome, data.cash][i]);
      });
      document.querySelectorAll(".kpi-period").forEach(el => { (el as HTMLElement).textContent = data.period; });
    } catch { /* silent */ }
  }
  loadKPIs();
</script>
ASTRO

cat > src/pages/dashboard/profit-loss.astro <<'ASTRO'
---
import DashboardLayout from "@/layouts/DashboardLayout.astro";
const now   = new Date();
const start = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
const end   = start;
---
<DashboardLayout title="Profit & Loss">
  <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
    <div>
      <h2 class="text-lg font-semibold text-white">Profit & Loss</h2>
      <p class="text-sm text-slate-400 mt-0.5">Income and expense breakdown from QuickBooks.</p>
    </div>
    <div class="flex gap-2 flex-wrap">
      <input type="month" id="start-date" value={start} class="rounded-lg border border-surface-700 bg-surface-800 px-3 py-1.5 text-sm text-white" />
      <input type="month" id="end-date"   value={end}   class="rounded-lg border border-surface-700 bg-surface-800 px-3 py-1.5 text-sm text-white" />
      <button id="fetch-btn" class="rounded-lg bg-brand-600 hover:bg-brand-500 px-4 py-1.5 text-sm font-semibold text-white transition-colors">Run</button>
      <button id="export-btn" class="rounded-lg border border-surface-700 hover:border-brand-500 px-4 py-1.5 text-sm font-semibold text-slate-300 transition-colors">Export CSV</button>
    </div>
  </div>
  <div id="pl-wrap" class="bg-surface-800 border border-surface-700 rounded-xl overflow-hidden">
    <div id="pl-placeholder" class="py-20 text-center text-slate-500 text-sm">Select a date range and click Run.</div>
    <table id="pl-table" class="hidden w-full text-sm">
      <thead class="bg-surface-900 text-slate-400 uppercase text-xs tracking-widest">
        <tr>
          <th class="px-6 py-3 text-left">Account</th>
          <th class="px-6 py-3 text-left">Type</th>
          <th class="px-6 py-3 text-right">Amount</th>
        </tr>
      </thead>
      <tbody id="pl-body" class="divide-y divide-surface-700"></tbody>
      <tfoot id="pl-footer" class="bg-surface-900 font-semibold"></tfoot>
    </table>
  </div>
</DashboardLayout>
<script>
  const fmt       = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });
  const btn       = document.getElementById("fetch-btn") as HTMLButtonElement;
  const exportBtn = document.getElementById("export-btn") as HTMLButtonElement;
  const startEl   = document.getElementById("start-date") as HTMLInputElement;
  const endEl     = document.getElementById("end-date")   as HTMLInputElement;
  let lastData: any = null;

  btn.addEventListener("click", async () => {
    btn.disabled = true; btn.textContent = "Loading…";
    const start = startEl.value + "-01";
    const end   = new Date(endEl.value + "-01");
    end.setMonth(end.getMonth() + 1); end.setDate(0);
    const endStr = end.toISOString().split("T")[0];
    try {
      const res = await fetch(`/api/qbo/pl?start=${start}&end=${endStr}`);
      if (res.status === 404) { alert("Connect QuickBooks first."); return; }
      const data = lastData = await res.json();
      const body = document.getElementById("pl-body")!;
      const footer = document.getElementById("pl-footer")!;
      body.innerHTML = data.rows.map((r: any) => `
        <tr class="hover:bg-surface-700 transition-colors">
          <td class="px-6 py-3 text-slate-200">${r.account}</td>
          <td class="px-6 py-3"><span class="text-xs px-2 py-0.5 rounded ${r.type === "income" ? "bg-emerald-900/50 text-emerald-300" : "bg-red-900/50 text-red-300"}">${r.type}</span></td>
          <td class="px-6 py-3 text-right ${r.type === "income" ? "text-emerald-300" : "text-red-300"}">${fmt.format(r.amount)}</td>
        </tr>`).join("");
      footer.innerHTML = `
        <tr><td class="px-6 py-3" colspan="2">Total Revenue</td><td class="px-6 py-3 text-right text-emerald-300">${fmt.format(data.totalRevenue)}</td></tr>
        <tr><td class="px-6 py-3" colspan="2">Total Expenses</td><td class="px-6 py-3 text-right text-red-300">${fmt.format(data.totalExpenses)}</td></tr>
        <tr class="text-brand-300"><td class="px-6 py-3" colspan="2">Net Income</td><td class="px-6 py-3 text-right">${fmt.format(data.netIncome)}</td></tr>`;
      document.getElementById("pl-placeholder")!.classList.add("hidden");
      document.getElementById("pl-table")!.classList.remove("hidden");
    } finally { btn.disabled = false; btn.textContent = "Run"; }
  });

  exportBtn.addEventListener("click", () => {
    if (!lastData) return;
    const csv = ["Account,Type,Amount", ...lastData.rows.map((r: any) => `${r.account},${r.type},${r.amount}`)].join("\n");
    const a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
    a.download = `pl-${startEl.value}.csv`; a.click();
  });
</script>
ASTRO

cat > src/pages/dashboard/cash-flow.astro <<'ASTRO'
---
import DashboardLayout from "@/layouts/DashboardLayout.astro";
---
<DashboardLayout title="Cash Flow">
  <div class="mb-6">
    <h2 class="text-lg font-semibold text-white">Cash Flow</h2>
    <p class="text-sm text-slate-400 mt-0.5">Current cash balance and movement from QuickBooks.</p>
  </div>
  <div id="cash-grid" class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
    {[{ label: "Cash Balance", id: "val-balance", color: "text-white" }, { label: "Total Inflow", id: "val-inflow", color: "text-emerald-300" }, { label: "Total Outflow", id: "val-outflow", color: "text-red-300" }].map(c => (
      <div class="bg-surface-800 border border-surface-700 rounded-xl p-5">
        <p class="text-xs text-slate-400 uppercase tracking-widest mb-1">{c.label}</p>
        <p id={c.id} class={`text-2xl font-bold ${c.color}`}>—</p>
      </div>
    ))}
  </div>
  <p id="as-of" class="text-xs text-slate-500 mb-4"></p>
  <div id="connect-prompt" class="hidden rounded-xl border border-brand-700 bg-brand-900/20 px-6 py-5 flex items-center gap-4">
    <div class="text-3xl">🔗</div>
    <div><p class="font-medium text-white text-sm">Connect QuickBooks to see live data</p></div>
    <a href="/dashboard/connect" class="ml-auto rounded-lg bg-brand-600 hover:bg-brand-500 px-4 py-2 text-sm font-semibold text-white transition-colors">Connect</a>
  </div>
</DashboardLayout>
<script>
  const fmt = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });
  (async () => {
    const res = await fetch("/api/qbo/summary");
    if (res.status === 404) { document.getElementById("connect-prompt")?.classList.remove("hidden"); return; }
    if (!res.ok) return;
    const d = await res.json() as { cash: number; inflow: number; outflow: number; asOf: string };
    (document.getElementById("val-balance") as HTMLElement).textContent = fmt.format(d.cash);
    (document.getElementById("val-inflow")  as HTMLElement).textContent = fmt.format(d.inflow);
    (document.getElementById("val-outflow") as HTMLElement).textContent = fmt.format(d.outflow);
    (document.getElementById("as-of")       as HTMLElement).textContent = `As of ${new Date(d.asOf).toLocaleDateString()}`;
  })();
</script>
ASTRO

cat > src/pages/dashboard/connect.astro <<'ASTRO'
---
import DashboardLayout from "@/layouts/DashboardLayout.astro";
const connected = Astro.url.searchParams.get("connected");
const error     = Astro.url.searchParams.get("error");
---
<DashboardLayout title="Connect QuickBooks">
  <div class="max-w-lg">
    <h2 class="text-lg font-semibold text-white mb-1">QuickBooks Connection</h2>
    <p class="text-sm text-slate-400 mb-6">Sync your live P&L, cash flow, and transactions.</p>
    {connected && <div class="mb-6 rounded-xl bg-emerald-900/30 border border-emerald-700 px-5 py-4 text-sm text-emerald-300">✓ QuickBooks connected successfully!</div>}
    {error     && <div class="mb-6 rounded-xl bg-red-900/30 border border-red-700 px-5 py-4 text-sm text-red-300">Connection failed: {error}. Please try again.</div>}
    <div id="connect-card" class="bg-surface-800 border border-surface-700 rounded-2xl p-6 flex flex-col gap-4">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-emerald-600/20 border border-emerald-700 flex items-center justify-center text-xl">📊</div>
        <div><p class="font-semibold text-white text-sm">QuickBooks Online</p><p class="text-xs text-slate-400">OAuth 2.0 — read-only access</p></div>
        <div id="status-badge" class="ml-auto text-xs px-2 py-0.5 rounded-full bg-surface-700 text-slate-400">Not connected</div>
      </div>
      <ul class="text-xs text-slate-400 space-y-1 pl-1">
        <li>✓ Profit & Loss reports</li>
        <li>✓ Cash balance & flow</li>
        <li>✓ Transaction history</li>
        <li>✗ No write access to your books</li>
      </ul>
      <a id="connect-btn" href="/api/qbo/connect" class="rounded-lg bg-brand-600 hover:bg-brand-500 px-5 py-2.5 text-sm font-semibold text-white text-center transition-colors">Connect QuickBooks</a>
      <button id="disconnect-btn" class="hidden rounded-lg border border-red-700 hover:bg-red-900/20 px-5 py-2.5 text-sm font-semibold text-red-400 transition-colors">Disconnect</button>
    </div>
  </div>
</DashboardLayout>
<script>
  (async () => {
    const res = await fetch("/api/qbo/status");
    if (res.ok) {
      const { connected } = await res.json() as { connected: boolean; companyName?: string };
      if (connected) {
        (document.getElementById("status-badge") as HTMLElement).textContent = "Connected ✓";
        (document.getElementById("status-badge") as HTMLElement).className = "ml-auto text-xs px-2 py-0.5 rounded-full bg-emerald-900/50 text-emerald-300";
        (document.getElementById("connect-btn")      as HTMLElement).classList.add("hidden");
        (document.getElementById("disconnect-btn")   as HTMLElement).classList.remove("hidden");
      }
    }
  })();
  document.getElementById("disconnect-btn")?.addEventListener("click", async () => {
    if (!confirm("Disconnect QuickBooks?")) return;
    await fetch("/api/qbo/disconnect", { method: "POST" });
    window.location.reload();
  });
</script>
ASTRO

# ── CSV Upload page (from filetree: upload.astro) ─────────────────────────────
cat > src/pages/dashboard/upload.astro <<'ASTRO'
---
import DashboardLayout from "@/layouts/DashboardLayout.astro";
import CSVUploader from "@/components/islands/CSVUploader.svelte";
---
<DashboardLayout title="Upload CSV">
  <div class="mb-6">
    <h2 class="text-lg font-semibold text-white">Upload Transactions</h2>
    <p class="text-sm text-slate-400 mt-0.5">Import a bank or accounting CSV to analyse your finances.</p>
  </div>
  <CSVUploader client:load />
</DashboardLayout>
ASTRO

# ── Public index (landing) ────────────────────────────────────────────────────
cat > src/pages/index.astro <<'ASTRO'
---
if (Astro.locals.user) return Astro.redirect("/dashboard");
---
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Insight Hunter Lite — Free CFO Insights</title>
    <link rel="icon" href="/favicon.ico" sizes="any" />
    <link rel="manifest" href="/manifest.webmanifest" />
    <link rel="stylesheet" href="/src/styles/global.css" />
  </head>
  <body class="bg-surface-950 text-slate-100 antialiased">
    <div class="min-h-screen flex flex-col items-center justify-center px-4 text-center">
      <div class="mb-6">
        <img src="/icons/icon-192.png" alt="Insight Hunter" width="64" height="64" class="mx-auto rounded-2xl mb-4" />
        <h1 class="text-4xl font-bold text-white mb-2">Insight Hunter <span class="text-brand-400">Lite</span></h1>
        <p class="text-slate-400 max-w-sm mx-auto">Free CFO-level insights for freelancers and small businesses. Upload a CSV or connect QuickBooks.</p>
      </div>
      <div class="flex flex-col sm:flex-row gap-3">
        <a href="/auth/register" class="rounded-xl bg-brand-600 hover:bg-brand-500 px-6 py-3 text-sm font-semibold text-white transition-colors">Get Started Free</a>
        <a href="/auth/login"    class="rounded-xl border border-surface-700 hover:border-brand-500 px-6 py-3 text-sm font-semibold text-slate-300 transition-colors">Sign In</a>
      </div>
    </div>
  </body>
</html>
ASTRO
success "Dashboard pages written."

# =============================================================================
# 18. Svelte Island — CSVUploader (from filetree)
# =============================================================================
info "Writing src/components/islands/CSVUploader.svelte…"
cat > src/components/islands/CSVUploader.svelte <<'SVELTE'
<script lang="ts">
  import type { UploadResult, CSVRow } from "@/types";

  let dragover  = $state(false);
  let loading   = $state(false);
  let result    = $state<UploadResult | null>(null);
  let error     = $state<string | null>(null);

  const fmt = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });

  async function handleFile(file: File) {
    if (!file.name.endsWith(".csv")) { error = "Please upload a .csv file."; return; }
    if (file.size > 5 * 1024 * 1024) { error = "File must be under 5 MB."; return; }
    loading = true; error = null; result = null;
    try {
      const text = await file.text();
      const res  = await fetch("/api/upload/csv", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ csv: text, fileName: file.name }),
      });
      if (!res.ok) { const d = await res.json().catch(() => ({})); throw new Error((d as any).message ?? "Upload failed."); }
      result = await res.json() as UploadResult;
    } catch (e) {
      error = e instanceof Error ? e.message : "Upload failed.";
    } finally { loading = false; }
  }

  function onDrop(e: DragEvent) {
    e.preventDefault(); dragover = false;
    const file = e.dataTransfer?.files[0];
    if (file) handleFile(file);
  }

  function onInput(e: Event) {
    const file = (e.target as HTMLInputElement).files?.[0];
    if (file) handleFile(file);
  }

  function downloadSample() {
    window.location.href = "/sample-transactions.csv";
  }

  const totalIncome  = $derived(result?.rows.filter(r => r.amount > 0).reduce((s, r) => s + r.amount, 0) ?? 0);
  const totalExpense = $derived(result?.rows.filter(r => r.amount < 0).reduce((s, r) => s + r.amount, 0) ?? 0);
</script>

<div class="space-y-6">
  <!-- Drop zone -->
  <div
    role="button"
    tabindex="0"
    aria-label="Upload CSV file"
    class="border-2 border-dashed rounded-2xl p-10 text-center transition-colors cursor-pointer
           {dragover ? 'border-brand-500 bg-brand-900/20' : 'border-surface-700 hover:border-brand-600 bg-surface-800'}"
    ondragover={(e) => { e.preventDefault(); dragover = true; }}
    ondragleave={() => dragover = false}
    ondrop={onDrop}
    onclick={() => document.getElementById("csv-file-input")?.click()}
    onkeydown={(e) => e.key === "Enter" && document.getElementById("csv-file-input")?.click()}
  >
    <input id="csv-file-input" type="file" accept=".csv" class="hidden" onchange={onInput} />
    {#if loading}
      <div class="flex flex-col items-center gap-3">
        <div class="w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full animate-spin"></div>
        <p class="text-sm text-slate-400">Parsing CSV…</p>
      </div>
    {:else}
      <div class="text-4xl mb-3">📂</div>
      <p class="text-sm font-medium text-white mb-1">Drop a CSV here or click to browse</p>
      <p class="text-xs text-slate-500">Supports bank exports, QuickBooks CSV, and custom formats · Max 5 MB</p>
      <button
        type="button"
        class="mt-4 text-xs text-brand-400 hover:text-brand-300 underline underline-offset-2"
        onclick|stopPropagation={downloadSample}
      >
        Download sample CSV
      </button>
    {/if}
  </div>

  <!-- Error -->
  {#if error}
    <div class="rounded-xl bg-red-900/30 border border-red-700 px-5 py-3 text-sm text-red-300">{error}</div>
  {/if}

  <!-- Parse errors -->
  {#if result?.errors.length}
    <div class="rounded-xl bg-yellow-900/30 border border-yellow-700 px-5 py-3">
      <p class="text-sm font-medium text-yellow-300 mb-1">⚠ {result.errors.length} row(s) skipped</p>
      <ul class="text-xs text-yellow-400 list-disc list-inside space-y-0.5">
        {#each result.errors.slice(0, 5) as err}<li>{err}</li>{/each}
        {#if result.errors.length > 5}<li>…and {result.errors.length - 5} more</li>{/if}
      </ul>
    </div>
  {/if}

  <!-- Summary KPIs -->
  {#if result}
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div class="bg-surface-800 border border-surface-700 rounded-xl p-5">
        <p class="text-xs text-slate-400 uppercase tracking-widest mb-1">Rows Imported</p>
        <p class="text-2xl font-bold text-white">{result.rows.length}</p>
        <p class="text-xs text-slate-500 mt-1">{result.fileName}</p>
      </div>
      <div class="bg-surface-800 border border-surface-700 rounded-xl p-5">
        <p class="text-xs text-slate-400 uppercase tracking-widest mb-1">Total Income</p>
        <p class="text-2xl font-bold text-emerald-300">{fmt.format(totalIncome)}</p>
      </div>
      <div class="bg-surface-800 border border-surface-700 rounded-xl p-5">
        <p class="text-xs text-slate-400 uppercase tracking-widest mb-1">Total Expenses</p>
        <p class="text-2xl font-bold text-red-300">{fmt.format(Math.abs(totalExpense))}</p>
      </div>
    </div>

    <!-- Transactions table -->
    <div class="bg-surface-800 border border-surface-700 rounded-xl overflow-hidden">
      <div class="flex items-center justify-between px-5 py-3 border-b border-surface-700">
        <p class="text-sm font-semibold text-white">Transactions</p>
        <p class="text-xs text-slate-500">{result.rows.length} rows</p>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-surface-900 text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th class="px-5 py-3 text-left">Date</th>
              <th class="px-5 py-3 text-left">Description</th>
              <th class="px-5 py-3 text-left">Category</th>
              <th class="px-5 py-3 text-right">Amount</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-surface-700">
            {#each result.rows.slice(0, 100) as row}
              <tr class="hover:bg-surface-700 transition-colors">
                <td class="px-5 py-2.5 text-slate-300 whitespace-nowrap">{row.date}</td>
                <td class="px-5 py-2.5 text-slate-200 max-w-xs truncate">{row.description}</td>
                <td class="px-5 py-2.5"><span class="text-xs bg-surface-700 text-slate-300 px-2 py-0.5 rounded">{row.category}</span></td>
                <td class="px-5 py-2.5 text-right font-medium {row.amount >= 0 ? 'text-emerald-300' : 'text-red-300'}">{fmt.format(row.amount)}</td>
              </tr>
            {/each}
          </tbody>
        </table>
        {#if result.rows.length > 100}
          <p class="px-5 py-3 text-xs text-slate-500 text-center">Showing first 100 of {result.rows.length} rows.</p>
        {/if}
      </div>
    </div>
  {/if}
</div>
SVELTE
success "CSVUploader.svelte written."

# =============================================================================
# 19. API Routes
# =============================================================================
info "Writing API routes…"

cat > src/pages/api/auth/login.ts <<'TS'
import type { APIRoute } from "astro";
import { saveUser, createSession, setSessionCookie, getUser } from "@/lib/auth/session";
import type { Env, User } from "@/types";

export const POST: APIRoute = async ({ request, locals }) => {
  const env = (locals as any).runtime?.env as Env;
  try {
    const { email, password } = await request.json() as { email: string; password: string };
    if (!email || !password) return new Response(JSON.stringify({ message: "Email and password required." }), { status: 400 });

    // Demo auth — replace with real hashed password lookup
    const userId  = btoa(email).replace(/=/g, "");
    let user = await getUser(env.IH_SESSIONS, userId);
    if (!user) {
      user = { id: userId, email, name: email.split("@")[0], tier: "lite", createdAt: new Date().toISOString() };
      await saveUser(env.IH_SESSIONS, user);
    }

    const ttl   = parseInt(env.SESSION_EXPIRY ?? "604800");
    const token = await createSession(env.IH_SESSIONS, user, ttl);
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "Set-Cookie": setSessionCookie(token, ttl), "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ message: "Login failed." }), { status: 500 });
  }
};
TS

cat > src/pages/api/auth/register.ts <<'TS'
import type { APIRoute } from "astro";
import { saveUser, createSession, setSessionCookie } from "@/lib/auth/session";
import type { Env, User } from "@/types";

export const POST: APIRoute = async ({ request, locals }) => {
  const env = (locals as any).runtime?.env as Env;
  try {
    const { name, email, password } = await request.json() as { name: string; email: string; password: string };
    if (!name || !email || !password) return new Response(JSON.stringify({ message: "All fields required." }), { status: 400 });
    if (password.length < 8) return new Response(JSON.stringify({ message: "Password must be at least 8 characters." }), { status: 400 });

    const user: User = { id: crypto.randomUUID(), email, name, tier: "lite", createdAt: new Date().toISOString() };
    await saveUser(env.IH_SESSIONS, user);
    const ttl   = parseInt(env.SESSION_EXPIRY ?? "604800");
    const token = await createSession(env.IH_SESSIONS, user, ttl);
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "Set-Cookie": setSessionCookie(token, ttl), "Content-Type": "application/json" },
    });
  } catch {
    return new Response(JSON.stringify({ message: "Registration failed." }), { status: 500 });
  }
};
TS

cat > src/pages/api/auth/logout.ts <<'TS'
import type { APIRoute } from "astro";
import { deleteSession, getSessionToken, clearSessionCookie } from "@/lib/auth/session";
import type { Env } from "@/types";

export const POST: APIRoute = async ({ request, locals, redirect }) => {
  const env   = (locals as any).runtime?.env as Env;
  const token = getSessionToken(request);
  if (token && env) await deleteSession(env.IH_SESSIONS, token);
  return new Response(null, { status: 302, headers: { Location: "/auth/login", "Set-Cookie": clearSessionCookie() } });
};
TS

cat > src/pages/api/auth/forgot-password.ts <<'TS'
import type { APIRoute } from "astro";

export const POST: APIRoute = async ({ request }) => {
  // TODO: generate reset token, store in KV with TTL, send email via MailChannels
  const { email } = await request.json() as { email: string };
  if (!email) return new Response(JSON.stringify({ message: "Email required." }), { status: 400 });
  // Always return 200 to prevent email enumeration
  return new Response(JSON.stringify({ ok: true }), { status: 200 });
};
TS

cat > src/pages/api/auth/reset-password.ts <<'TS'
import type { APIRoute } from "astro";

export const POST: APIRoute = async ({ request }) => {
  // TODO: validate reset token from KV, update hashed password
  const { token, password } = await request.json() as { token: string; password: string };
  if (!token || !password) return new Response(JSON.stringify({ message: "Token and password required." }), { status: 400 });
  return new Response(JSON.stringify({ ok: true }), { status: 200 });
};
TS

cat > src/pages/api/qbo/connect.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env } from "@/types";

export const GET: APIRoute = async ({ locals, redirect }) => {
  const env   = (locals as any).runtime?.env as Env;
  const state = crypto.randomUUID();
  const params = new URLSearchParams({
    client_id:     env.QBO_CLIENT_ID,
    response_type: "code",
    scope:         "com.intuit.quickbooks.accounting",
    redirect_uri:  env.QBO_REDIRECT_URI,
    state,
  });
  return redirect(`https://appcenter.intuit.com/connect/oauth2?${params}`, 302);
};
TS

cat > src/pages/api/qbo/callback.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env, QBOConnection, QBOTokenResponse } from "@/types";
import { getSessionToken, getSession } from "@/lib/auth/session";

export const GET: APIRoute = async ({ url, locals, redirect, request }) => {
  const env   = (locals as any).runtime?.env as Env;
  const code  = url.searchParams.get("code");
  const realm = url.searchParams.get("realmId");
  if (!code || !realm) return redirect("/dashboard/connect?error=missing_params", 302);

  try {
    const creds = btoa(`${env.QBO_CLIENT_ID}:${env.QBO_CLIENT_SECRET}`);
    const res   = await fetch("https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer", {
      method: "POST",
      headers: { Authorization: `Basic ${creds}`, "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "authorization_code", code, redirect_uri: env.QBO_REDIRECT_URI }),
    });
    if (!res.ok) throw new Error("Token exchange failed");
    const tokens = await res.json() as QBOTokenResponse;

    const token   = getSessionToken(request);
    const session = token ? await getSession(env.IH_SESSIONS, token) : null;
    const userId  = session?.userId ?? "anonymous";

    const conn: QBOConnection = {
      realmId:      realm,
      accessToken:  tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresAt:    Date.now() + tokens.expires_in * 1000,
      companyName:  "",
    };
    await env.IH_CACHE.put(`qbo:${userId}`, JSON.stringify(conn), { expirationTtl: 60 * 60 * 24 * 30 });
    return redirect("/dashboard/connect?connected=1", 302);
  } catch (e) {
    return redirect("/dashboard/connect?error=token_failed", 302);
  }
};
TS

cat > src/pages/api/qbo/summary.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env, QBOConnection } from "@/types";
import { QBOClient } from "@/lib/qbo/client";
import { getSessionToken, getSession } from "@/lib/auth/session";

export const GET: APIRoute = async ({ request, locals }) => {
  const env     = (locals as any).runtime?.env as Env;
  const token   = getSessionToken(request);
  const session = token ? await getSession(env.IH_SESSIONS, token) : null;
  const userId  = session?.userId ?? "anonymous";
  const raw     = await env.IH_CACHE.get(`qbo:${userId}`);
  if (!raw) return new Response(JSON.stringify({ message: "Not connected" }), { status: 404 });

  const conn   = JSON.parse(raw) as QBOConnection;
  const client = new QBOClient(conn, (env.QBO_ENVIRONMENT ?? "sandbox") as "sandbox" | "production");
  const now    = new Date();
  const start  = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`;
  const end    = now.toISOString().split("T")[0];
  const [pl, cash] = await Promise.all([client.getProfitAndLoss(start, end), client.getCashSummary()]);

  return new Response(JSON.stringify({
    revenue:    pl.totalRevenue,
    expenses:   pl.totalExpenses,
    netIncome:  pl.netIncome,
    cash:       cash.balance,
    inflow:     cash.inflow,
    outflow:    cash.outflow,
    asOf:       cash.asOf,
    period:     `${start} – ${end}`,
  }), { headers: { "Content-Type": "application/json" } });
};
TS

cat > src/pages/api/qbo/pl.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env, QBOConnection } from "@/types";
import { QBOClient } from "@/lib/qbo/client";
import { getSessionToken, getSession } from "@/lib/auth/session";

export const GET: APIRoute = async ({ request, url, locals }) => {
  const env     = (locals as any).runtime?.env as Env;
  const token   = getSessionToken(request);
  const session = token ? await getSession(env.IH_SESSIONS, token) : null;
  const userId  = session?.userId ?? "anonymous";
  const raw     = await env.IH_CACHE.get(`qbo:${userId}`);
  if (!raw) return new Response(JSON.stringify({ message: "Not connected" }), { status: 404 });

  const start = url.searchParams.get("start") ?? "";
  const end   = url.searchParams.get("end")   ?? "";
  if (!start || !end) return new Response(JSON.stringify({ message: "start and end required" }), { status: 400 });

  const conn   = JSON.parse(raw) as QBOConnection;
  const client = new QBOClient(conn, (env.QBO_ENVIRONMENT ?? "sandbox") as "sandbox" | "production");
  const pl     = await client.getProfitAndLoss(start, end);
  return new Response(JSON.stringify(pl), { headers: { "Content-Type": "application/json" } });
};
TS

cat > src/pages/api/qbo/status.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env, QBOConnection } from "@/types";
import { getSessionToken, getSession } from "@/lib/auth/session";

export const GET: APIRoute = async ({ request, locals }) => {
  const env     = (locals as any).runtime?.env as Env;
  const token   = getSessionToken(request);
  const session = token ? await getSession(env.IH_SESSIONS, token) : null;
  const userId  = session?.userId ?? "anonymous";
  const raw     = await env.IH_CACHE.get(`qbo:${userId}`);
  if (!raw) return new Response(JSON.stringify({ connected: false }), { status: 200 });
  const conn = JSON.parse(raw) as QBOConnection;
  return new Response(JSON.stringify({ connected: true, companyName: conn.companyName, realmId: conn.realmId }), { status: 200 });
};
TS

cat > src/pages/api/qbo/disconnect.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env } from "@/types";
import { getSessionToken, getSession } from "@/lib/auth/session";

export const POST: APIRoute = async ({ request, locals }) => {
  const env     = (locals as any).runtime?.env as Env;
  const token   = getSessionToken(request);
  const session = token ? await getSession(env.IH_SESSIONS, token) : null;
  const userId  = session?.userId ?? "anonymous";
  await env.IH_CACHE.delete(`qbo:${userId}`);
  return new Response(JSON.stringify({ ok: true }), { status: 200 });
};
TS

# ── CSV Upload API ────────────────────────────────────────────
mkdir -p src/pages/api/upload
cat > src/pages/api/upload/csv.ts <<'TS'
import type { APIRoute } from "astro";
import { parseCSV } from "@/lib/utils/csvParser";

export const POST: APIRoute = async ({ request }) => {
  try {
    const { csv, fileName } = await request.json() as { csv: string; fileName: string };
    if (!csv) return new Response(JSON.stringify({ message: "No CSV data provided." }), { status: 400 });
    const result = parseCSV(csv, fileName ?? "upload.csv");
    return new Response(JSON.stringify(result), { headers: { "Content-Type": "application/json" } });
  } catch {
    return new Response(JSON.stringify({ message: "Failed to parse CSV." }), { status: 500 });
  }
};
TS
success "API routes written."

# =============================================================================
# 20. Public files (from filetree)
# =============================================================================
info "Writing public files…"

cat > public/manifest.webmanifest <<'JSON'
{
  "name":             "Insight Hunter Lite",
  "short_name":       "IH Lite",
  "description":      "Free CFO insights for freelancers and small businesses",
  "start_url":        "/",
  "display":          "standalone",
  "background_color": "#0a0f1e",
  "theme_color":      "#4f46e5",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
JSON

# Service worker (from filetree: sw.js)
cat > public/sw.js <<'JS'
const CACHE_NAME = "ih-lite-v1";
const PRECACHE = ["/", "/auth/login", "/auth/register", "/manifest.webmanifest"];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  if (event.request.url.includes("/api/")) return; // never cache API
  event.respondWith(
    caches.match(event.request).then(cached => cached ?? fetch(event.request))
  );
});
JS

# Sample CSV (from filetree: sample-transactions.csv)
cat > public/sample-transactions.csv <<'CSV'
Date,Description,Amount,Category
2026-01-03,Client Payment - Acme Corp,5000.00,Income
2026-01-05,AWS Invoice,-234.50,Cloud Infrastructure
2026-01-07,Figma Subscription,-15.00,Software
2026-01-10,Freelance Project - Beta LLC,2500.00,Income
2026-01-12,Office Supplies,-87.40,Office
2026-01-15,Stripe Payout,3200.00,Income
2026-01-18,Internet Bill,-79.99,Utilities
2026-01-20,Contractor Payment - J. Doe,-800.00,Contractors
2026-01-22,Consulting Fee - Delta Inc,1800.00,Income
2026-01-25,LinkedIn Premium,-39.99,Marketing
2026-01-28,GitHub Copilot,-19.00,Software
2026-01-31,Zoom Pro,-15.99,Software
CSV

# .assetsignore for Cloudflare
cat > public/.assetsignore <<'EOF'
_worker.js
_routes.json
EOF

success "Public files written."

# =============================================================================
# 21. npm install & git init
# =============================================================================
info "Installing dependencies…"
npm install --silent
success "Dependencies installed."

info "Initialising git repository…"
git init -q
git add -A
git commit -m "chore: scaffold insighthunter-lite (Astro + Svelte + Tailwind v4 + Cloudflare)" -q
success "Git repository initialised."

# =============================================================================
# Done
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║  ✅  insighthunter-lite scaffolded           ║${RESET}"
echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Next steps:                                 ║${RESET}"
echo -e "${GREEN}║  1. cp .env.example .env                     ║${RESET}"
echo -e "${GREEN}║  2. Fill in JWT_SECRET + QBO credentials     ║${RESET}"
echo -e "${GREEN}║  3. wrangler kv:namespace create IH_SESSIONS ║${RESET}"
echo -e "${GREEN}║  4. wrangler kv:namespace create IH_CACHE    ║${RESET}"
echo -e "${GREEN}║  5. Update KV IDs in wrangler.toml           ║${RESET}"
echo -e "${GREEN}║  6. npm run dev                              ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
if command -v tree &> /dev/null; then
  tree . -a --dirsfirst -I "node_modules|.git|dist|.astro"
else
  find . -not -path "*/node_modules/*" -not -path "*/.git/*" | sort
fi
