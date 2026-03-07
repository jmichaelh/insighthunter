#!/usr/bin/env bash
# =============================================================================
# scaffold-insighthunter-lite.sh
# Scaffolds Insight Hunter Lite — Astro + TypeScript + Tailwind v4
# + Cloudflare Workers adapter, auth, dashboard shell, and QBO API routes.
#
# Usage:
#   chmod +x scaffold-insighthunter-lite.sh
#   ./scaffold-insighthunter-lite.sh [target-dir]   # default: ./insighthunter-lite
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
die()     { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }

# ── Dependency checks ─────────────────────────────────────────────────────────
command -v node >/dev/null 2>&1 || die "Node.js >= 20 required (https://nodejs.org)"
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
mkdir -p "$PROJECT_DIR"/{src/{pages/{auth,dashboard,api/{auth,qbo}},layouts,components/{ui,charts,dashboard},lib/{auth,qbo,utils},styles,types},public/{icons,fonts},scripts}
success "Directories created."

cd "$PROJECT_DIR"

# =============================================================================
# 2. package.json
# =============================================================================
info "Writing package.json…"
cat > package.json <<'JSON'
{
  "name": "insighthunter-lite",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev":       "astro dev",
    "build":     "astro build",
    "preview":   "astro preview",
    "deploy":    "npm run build && wrangler deploy",
    "typecheck": "astro check",
    "lint":      "eslint src --ext .ts,.astro"
  },
  "dependencies": {
    "@astrojs/cloudflare": "^12.0.0",
    "astro": "^5.0.0"
  },
  "devDependencies": {
    "@astrojs/check":            "^0.9.0",
    "@cloudflare/workers-types": "^4.0.0",
    "@tailwindcss/vite":         "^4.0.0",
    "tailwindcss":               "^4.0.0",
    "typescript":                "^5.7.0",
    "wrangler":                  "^3.0.0"
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
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  output: "server",
  adapter: cloudflare({
    platformProxy: { enabled: true },
    imageService: "cloudflare",
  }),
  vite: {
    plugins: [tailwindcss()],
  },
  security: {
    checkOrigin: true,
  },
});
EOF
success "astro.config.mjs written."

# =============================================================================
# 4. wrangler.jsonc
# =============================================================================
info "Writing wrangler.jsonc…"
cat > wrangler.jsonc <<'EOF'
{
  "name": "insighthunter-lite",
  "compatibility_date": "2025-01-01",
  "compatibility_flags": ["nodejs_compat"],
  "main": "./dist/_worker.js",
  "assets": {
    "directory": "./dist",
    "not_found_handling": "single-page-application"
  },
  "kv_namespaces": [
    {
      "binding": "IH_SESSIONS",
      "id": "REPLACE_WITH_KV_ID",
      "preview_id": "REPLACE_WITH_PREVIEW_KV_ID"
    },
    {
      "binding": "IH_CACHE",
      "id": "REPLACE_WITH_CACHE_KV_ID",
      "preview_id": "REPLACE_WITH_PREVIEW_CACHE_KV_ID"
    }
  ],
  "vars": {
    "APP_ENV":        "development",
    "APP_URL":        "http://localhost:4321",
    "APP_TIER":       "lite",
    "SESSION_EXPIRY": "604800"
  }
  // Secrets — add via: wrangler secret put SECRET_NAME
  // Required: JWT_SECRET, QBO_CLIENT_ID, QBO_CLIENT_SECRET, QBO_REDIRECT_URI
}
EOF
success "wrangler.jsonc written."

# =============================================================================
# 5. tsconfig.json
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
      "@/*":            ["src/*"],
      "@components/*":  ["src/components/*"],
      "@layouts/*":     ["src/layouts/*"],
      "@lib/*":         ["src/lib/*"],
      "@types/*":       ["src/types/*"]
    },
    "types": ["@cloudflare/workers-types"]
  },
  "include": ["src/**/*", "scripts/**/*", ".astro/**/*"]
}
JSON
success "tsconfig.json written."

# =============================================================================
# 6. .env.example
# =============================================================================
info "Writing .env.example…"
cat > .env.example <<'EOF'
# App
APP_ENV=development
APP_URL=http://localhost:4321
APP_TIER=lite

# Auth
JWT_SECRET=replace_with_32_char_random_string
SESSION_EXPIRY=604800

# QuickBooks Online OAuth 2.0
QBO_CLIENT_ID=replace_with_qbo_client_id
QBO_CLIENT_SECRET=replace_with_qbo_client_secret
QBO_REDIRECT_URI=http://localhost:4321/api/qbo/callback
QBO_ENVIRONMENT=sandbox

# Cloudflare KV bindings are injected automatically by wrangler
EOF
success ".env.example written."

# =============================================================================
# 7. .gitignore
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
Thumbs.db
*.log
EOF
success ".gitignore written."

# =============================================================================
# 8. Tailwind global CSS
# =============================================================================
info "Writing src/styles/global.css…"
cat > src/styles/global.css <<'CSS'
@import "tailwindcss";

@theme {
  /* Brand */
  --color-brand-50:  #eef2ff;
  --color-brand-100: #e0e7ff;
  --color-brand-400: #818cf8;
  --color-brand-500: #6366f1;
  --color-brand-600: #4f46e5;
  --color-brand-700: #4338ca;

  /* Surfaces */
  --color-surface-950: #0a0f1e;
  --color-surface-900: #0f172a;
  --color-surface-800: #1e293b;
  --color-surface-700: #334155;

  /* Semantic */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-danger:  #ef4444;

  /* Font */
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
# 9. Types
# =============================================================================
info "Writing src/types/index.ts…"
cat > src/types/index.ts <<'TS'
// ── Auth ─────────────────────────────────────────────────────────────────────
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

// ── QuickBooks ────────────────────────────────────────────────────────────────
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

// ── Financial ─────────────────────────────────────────────────────────────────
export interface ProfitLoss {
  periodStart:   string;
  periodEnd:     string;
  totalRevenue:  number;
  totalExpenses: number;
  netIncome:     number;
  rows:          PLRow[];
}

export interface PLRow {
  account:  string;
  amount:   number;
  type:     "income" | "expense";
}

export interface CashSummary {
  balance:   number;
  inflow:    number;
  outflow:   number;
  asOf:      string;
}

// ── Cloudflare Env ────────────────────────────────────────────────────────────
export interface Env {
  APP_ENV:        string;
  APP_URL:        string;
  APP_TIER:       string;
  SESSION_EXPIRY: string;
  JWT_SECRET:     string;
  QBO_CLIENT_ID:     string;
  QBO_CLIENT_SECRET: string;
  QBO_REDIRECT_URI:  string;
  QBO_ENVIRONMENT:   string;
  IH_SESSIONS: KVNamespace;
  IH_CACHE:    KVNamespace;
}
TS
success "src/types/index.ts written."

# =============================================================================
# 10. Auth lib
# =============================================================================
info "Writing src/lib/auth/session.ts…"
cat > src/lib/auth/session.ts <<'TS'
import type { Session, User, Env } from "@/types";

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

  await kv.put(
    `${SESSION_PREFIX}${token}`,
    JSON.stringify(session),
    { expirationTtl: ttlSeconds }
  );
  return token;
}

export async function getSession(
  kv: KVNamespace,
  token: string
): Promise<Session | null> {
  const raw = await kv.get(`${SESSION_PREFIX}${token}`);
  if (!raw) return null;
  const session = JSON.parse(raw) as Session;
  if (Date.now() > session.expiresAt) {
    await kv.delete(`${SESSION_PREFIX}${token}`);
    return null;
  }
  return session;
}

export async function deleteSession(
  kv: KVNamespace,
  token: string
): Promise<void> {
  await kv.delete(`${SESSION_PREFIX}${token}`);
}

export async function getUser(
  kv: KVNamespace,
  userId: string
): Promise<User | null> {
  const raw = await kv.get(`${USER_PREFIX}${userId}`);
  return raw ? (JSON.parse(raw) as User) : null;
}

export async function saveUser(
  kv: KVNamespace,
  user: User
): Promise<void> {
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
# 11. QBO lib
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
      headers: {
        Authorization: `Bearer ${this.conn.accessToken}`,
        Accept:        "application/json",
      },
    });
    if (!res.ok) {
      const body = await res.text();
      throw new Error(`QBO API error ${res.status}: ${body}`);
    }
    return res.json() as Promise<T>;
  }

  async getProfitAndLoss(
    startDate: string,
    endDate:   string
  ): Promise<ProfitLoss> {
    const data = await this.fetch<any>(
      `/reports/ProfitAndLoss?start_date=${startDate}&end_date=${endDate}&minorversion=73`
    );

    const rows: ProfitLoss["rows"] = [];
    let totalRevenue  = 0;
    let totalExpenses = 0;

    for (const section of data?.Rows?.Row ?? []) {
      const type: "income" | "expense" =
        section.group === "Income" ? "income" : "expense";
      for (const row of section?.Rows?.Row ?? []) {
        const amount = parseFloat(row?.Summary?.ColData?.[1]?.value ?? "0");
        rows.push({ account: row?.Summary?.ColData?.[0]?.value ?? "", amount, type });
        if (type === "income")  totalRevenue  += amount;
        if (type === "expense") totalExpenses += amount;
      }
    }

    return {
      periodStart:   startDate,
      periodEnd:     endDate,
      totalRevenue,
      totalExpenses,
      netIncome: totalRevenue - totalExpenses,
      rows,
    };
  }

  async getCashSummary(): Promise<CashSummary> {
    const data = await this.fetch<any>(
      "/reports/BalanceSheet?minorversion=73"
    );
    const cashRow = data?.Rows?.Row?.find(
      (r: any) => r?.Summary?.ColData?.[0]?.value === "Total Current Assets"
    );
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
    headers: {
      Authorization:  `Basic ${creds}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type:    "refresh_token",
      refresh_token: conn.refreshToken,
    }),
  });
  if (!res.ok) throw new Error(`QBO token refresh failed: ${res.status}`);
  return res.json() as Promise<QBOTokenResponse>;
}
TS
success "src/lib/qbo/client.ts written."

# =============================================================================
# 12. Middleware (auth guard)
# =============================================================================
info "Writing src/middleware.ts…"
cat > src/middleware.ts <<'TS'
import { defineMiddleware } from "astro:middleware";
import { getSession, getUser, getSessionToken } from "@/lib/auth/session";
import type { Env } from "@/types";

const PUBLIC_PATHS = new Set([
  "/",
  "/auth/login",
  "/auth/register",
  "/auth/forgot-password",
  "/auth/reset-password",
]);

const API_PUBLIC = new Set([
  "/api/auth/login",
  "/api/auth/register",
  "/api/auth/logout",
  "/api/qbo/callback",
]);

export const onRequest = defineMiddleware(async ({ locals, request, redirect, url }, next) => {
  const env = (locals as any).runtime?.env as Env | undefined;

  // Skip guard for public routes and static assets
  const path = url.pathname;
  if (PUBLIC_PATHS.has(path) || API_PUBLIC.has(path) || path.startsWith("/_")) {
    return next();
  }

  if (!env) return next(); // dev fallback

  const token = getSessionToken(request);
  if (!token) return redirect("/auth/login?next=" + encodeURIComponent(path), 302);

  const session = await getSession(env.IH_SESSIONS, token);
  if (!session) return redirect("/auth/login?expired=1", 302);

  const user = await getUser(env.IH_SESSIONS, session.userId);
  if (!user) return redirect("/auth/login", 302);

  (locals as any).user = user;
  (locals as any).session = session;

  return next();
});
TS
success "src/middleware.ts written."

# =============================================================================
# 13. Layouts
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
    <title>{title} | Insight Hunter</title>
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
    <title>{title} — Insight Hunter</title>
    <link rel="icon" href="/favicon.ico" sizes="any" />
    <link rel="manifest" href="/manifest.webmanifest" />
    <link rel="stylesheet" href="/src/styles/global.css" />
  </head>
  <body class="h-full bg-surface-950 text-slate-100 antialiased flex">

    <!-- Sidebar -->
    <nav class="hidden md:flex flex-col w-60 bg-surface-900 border-r border-surface-800 px-4 py-6 gap-1 shrink-0">
      <div class="flex items-center gap-2 mb-8 px-2">
        <img src="/icons/icon-192.png" alt="" width="28" height="28" class="rounded-lg" />
        <span class="font-semibold text-white text-sm">Insight Hunter</span>
        <span class="ml-auto text-[10px] bg-brand-600 text-white px-1.5 py-0.5 rounded font-bold tracking-wide">LITE</span>
      </div>
      <a href="/dashboard"             class="nav-link">📊 Overview</a>
      <a href="/dashboard/profit-loss" class="nav-link">📈 Profit & Loss</a>
      <a href="/dashboard/cash-flow"   class="nav-link">💰 Cash Flow</a>
      <a href="/dashboard/connect"     class="nav-link">🔗 QuickBooks</a>
      <a href="/settings"              class="nav-link mt-auto">⚙️ Settings</a>
      <form action="/api/auth/logout" method="POST" class="mt-2">
        <button type="submit" class="nav-link w-full text-left text-red-400 hover:bg-red-900/20">
          🚪 Sign Out
        </button>
      </form>
    </nav>

    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0">
      <header class="h-14 border-b border-surface-800 bg-surface-900 flex items-center px-6 gap-4 shrink-0">
        <h1 class="text-sm font-semibold text-white flex-1">{title}</h1>
        {user && (
          <span class="text-xs text-slate-400">{user.name} · {user.email}</span>
        )}
      </header>
      <main class="flex-1 overflow-y-auto p-6">
        <slot />
      </main>
    </div>

  </body>
</html>

<style>
  .nav-link {
    @apply flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-slate-300 hover:bg-surface-800 hover:text-white transition-colors;
  }
</style>
ASTRO

success "Layouts written."

# =============================================================================
# 14. Pages — Auth
# =============================================================================
info "Writing auth pages…"

cat > src/pages/auth/login.astro <<'ASTRO'
---
import AuthLayout from "@/layouts/AuthLayout.astro";
const next = Astro.url.searchParams.get("next") ?? "/dashboard";
const expired = Astro.url.searchParams.has("expired");
---
<AuthLayout title="Sign In">
  {expired && (
    <p class="mb-4 rounded-lg bg-yellow-900/40 border border-yellow-700 px-4 py-2 text-sm text-yellow-300">
      Your session expired. Please sign in again.
    </p>
  )}
  <h1 class="text-2xl font-semibold text-white mb-1">Welcome back</h1>
  <p class="text-sm text-slate-400 mb-6">Sign in to your Insight Hunter account.</p>
  <form id="login-form" novalidate class="space-y-4">
    <input type="hidden" name="next" value={next} />
    <div>
      <label for="email" class="block text-sm font-medium text-slate-300 mb-1.5">Email</label>
      <input id="email" name="email" type="email" required autocomplete="email"
        class="ih-input" placeholder="you@company.com" />
    </div>
    <div>
      <label for="password" class="block text-sm font-medium text-slate-300 mb-1.5">Password</label>
      <input id="password" name="password" type="password" required autocomplete="current-password"
        class="ih-input" placeholder="Your password" />
    </div>
    <div id="error-msg" class="hidden rounded-lg bg-red-900/40 border border-red-700 px-4 py-2 text-sm text-red-300"></div>
    <button type="submit" class="ih-btn-primary w-full">Sign In</button>
  </form>
  <p class="mt-6 text-center text-sm text-slate-500">
    <a href="/auth/forgot-password" class="text-brand-400 hover:text-brand-300 underline underline-offset-2">Forgot password?</a>
  </p>
  <p class="mt-2 text-center text-sm text-slate-500">
    No account? <a href="/auth/register" class="text-brand-400 hover:text-brand-300 underline underline-offset-2">Sign up free</a>
  </p>
</AuthLayout>

<style>
  .ih-input  { @apply w-full rounded-lg border border-surface-700 bg-surface-900 px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition; }
  .ih-btn-primary { @apply rounded-lg bg-brand-600 hover:bg-brand-500 disabled:bg-surface-700 disabled:cursor-not-allowed px-4 py-2.5 text-sm font-semibold text-white transition-colors; }
</style>

<script>
  const form     = document.getElementById("login-form") as HTMLFormElement;
  const errorMsg = document.getElementById("error-msg")!;
  const submitBtn = form.querySelector("button[type=submit]") as HTMLButtonElement;

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    submitBtn.disabled = true;
    submitBtn.textContent = "Signing in…";
    errorMsg.classList.add("hidden");

    const fd = new FormData(form);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: fd.get("email"), password: fd.get("password") }),
      });
      if (!res.ok) {
        const { message } = await res.json().catch(() => ({ message: "Login failed." }));
        throw new Error(message);
      }
      window.location.href = (fd.get("next") as string) || "/dashboard";
    } catch (err) {
      errorMsg.textContent = err instanceof Error ? err.message : "Login failed.";
      errorMsg.classList.remove("hidden");
      submitBtn.disabled = false;
      submitBtn.textContent = "Sign In";
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
      <input id="name" name="name" type="text" required autocomplete="name"
        class="ih-input" placeholder="Jane Smith" />
    </div>
    <div>
      <label for="email" class="block text-sm font-medium text-slate-300 mb-1.5">Work Email</label>
      <input id="email" name="email" type="email" required autocomplete="email"
        class="ih-input" placeholder="jane@company.com" />
    </div>
    <div>
      <label for="password" class="block text-sm font-medium text-slate-300 mb-1.5">Password</label>
      <input id="password" name="password" type="password" required minlength="8" autocomplete="new-password"
        class="ih-input" placeholder="At least 8 characters" />
    </div>
    <div id="error-msg" class="hidden rounded-lg bg-red-900/40 border border-red-700 px-4 py-2 text-sm text-red-300"></div>
    <button type="submit" class="ih-btn-primary w-full">Create Account</button>
  </form>
  <p class="mt-6 text-center text-sm text-slate-500">
    Already have an account? <a href="/auth/login" class="text-brand-400 hover:text-brand-300 underline underline-offset-2">Sign in</a>
  </p>
</AuthLayout>

<style>
  .ih-input  { @apply w-full rounded-lg border border-surface-700 bg-surface-900 px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition; }
  .ih-btn-primary { @apply rounded-lg bg-brand-600 hover:bg-brand-500 disabled:bg-surface-700 disabled:cursor-not-allowed px-4 py-2.5 text-sm font-semibold text-white transition-colors; }
</style>

<script>
  const form      = document.getElementById("register-form") as HTMLFormElement;
  const errorMsg  = document.getElementById("error-msg")!;
  const submitBtn = form.querySelector("button[type=submit]") as HTMLButtonElement;

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    submitBtn.disabled = true;
    submitBtn.textContent = "Creating account…";
    errorMsg.classList.add("hidden");

    const fd = new FormData(form);
    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: fd.get("name"), email: fd.get("email"), password: fd.get("password") }),
      });
      if (!res.ok) {
        const { message } = await res.json().catch(() => ({ message: "Registration failed." }));
        throw new Error(message);
      }
      window.location.href = "/dashboard";
    } catch (err) {
      errorMsg.textContent = err instanceof Error ? err.message : "Registration failed.";
      errorMsg.classList.remove("hidden");
      submitBtn.disabled = false;
      submitBtn.textContent = "Create Account";
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
    <p class="text-sm text-emerald-300">Check your inbox for a reset link. It expires in 1 hour.</p>
    <a href="/auth/login" class="inline-block text-sm text-brand-400 hover:text-brand-300 underline underline-offset-2">Back to login</a>
  </div>
  <form id="forgot-form" novalidate class="space-y-4">
    <div>
      <label for="email" class="block text-sm font-medium text-slate-300 mb-1.5">Email</label>
      <input id="email" name="email" type="email" required autocomplete="email"
        class="ih-input" placeholder="you@company.com" />
    </div>
    <div id="error-msg" class="hidden rounded-lg bg-red-900/40 border border-red-700 px-4 py-2 text-sm text-red-300"></div>
    <button type="submit" class="ih-btn-primary w-full">Send Reset Link</button>
  </form>
</AuthLayout>

<style>
  .ih-input  { @apply w-full rounded-lg border border-surface-700 bg-surface-900 px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition; }
  .ih-btn-primary { @apply rounded-lg bg-brand-600 hover:bg-brand-500 disabled:bg-surface-700 disabled:cursor-not-allowed px-4 py-2.5 text-sm font-semibold text-white transition-colors; }
</style>

<script>
  const form         = document.getElementById("forgot-form") as HTMLFormElement;
  const successState = document.getElementById("success-state")!;
  const errorMsg     = document.getElementById("error-msg")!;
  const submitBtn    = form.querySelector("button[type=submit]") as HTMLButtonElement;

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    submitBtn.disabled = true;
    submitBtn.textContent = "Sending…";
    errorMsg.classList.add("hidden");

    const fd = new FormData(form);
    try {
      const res = await fetch("/api/auth/forgot-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: fd.get("email") }),
      });
      if (!res.ok) throw new Error("Request failed.");
      form.classList.add("hidden");
      successState.classList.remove("hidden");
    } catch {
      errorMsg.textContent = "Could not send reset link. Please try again.";
      errorMsg.classList.remove("hidden");
      submitBtn.disabled = false;
      submitBtn.textContent = "Send Reset Link";
    }
  });
</script>
ASTRO

cat > src/pages/auth/reset-password.astro <<'ASTRO'
---
import AuthLayout from "@/layouts/AuthLayout.astro";
const token = Astro.url.searchParams.get("token");
---
<AuthLayout title="Reset Password">
  {!token ? (
    <div class="text-center space-y-4">
      <div class="text-4xl">🔗</div>
      <h1 class="text-xl font-semibold text-white">Link Invalid or Expired</h1>
      <p class="text-sm text-slate-400">Reset links expire after 1 hour.</p>
      <a href="/auth/forgot-password" class="ih-btn-primary inline-block w-full text-center">Request a New Link</a>
    </div>
  ) : (
    <>
      <h1 class="text-2xl font-semibold text-white mb-1">Set new password</h1>
      <p class="text-sm text-slate-400 mb-6">Choose a strong password for your account.</p>
      <div id="success-banner" class="hidden mb-4 rounded-lg bg-emerald-900/40 border border-emerald-700 px-4 py-2 text-sm text-emerald-300">✓ Password updated — redirecting…</div>
      <div id="error-banner"   class="hidden mb-4 rounded-lg bg-red-900/40   border border-red-700   px-4 py-2 text-sm text-red-300"></div>
      <form id="reset-form" novalidate class="space-y-4">
        <input type="hidden" name="token" value={token} />
        <div>
          <label for="password" class="block text-sm font-medium text-slate-300 mb-1.5">New Password</label>
          <input id="password" name="password" type="password" required minlength="8" autocomplete="new-password" class="ih-input" placeholder="At least 8 characters" />
        </div>
        <div>
          <label for="confirm" class="block text-sm font-medium text-slate-300 mb-1.5">Confirm Password</label>
          <input id="confirm" name="confirmPassword" type="password" required autocomplete="new-password" class="ih-input" placeholder="Repeat password" />
          <p id="mismatch" class="hidden mt-1 text-xs text-red-400">Passwords do not match.</p>
        </div>
        <button type="submit" class="ih-btn-primary w-full">Reset Password</button>
      </form>
    </>
  )}
</AuthLayout>

<style>
  .ih-input  { @apply w-full rounded-lg border border-surface-700 bg-surface-900 px-3.5 py-2.5 text-sm text-white placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition; }
  .ih-btn-primary { @apply rounded-lg bg-brand-600 hover:bg-brand-500 disabled:bg-surface-700 disabled:cursor-not-allowed px-4 py-2.5 text-sm font-semibold text-white transition-colors; }
</style>

<script>
  const form          = document.getElementById("reset-form") as HTMLFormElement | null;
  if (!form) throw new Error();
  const pw            = document.getElementById("password")       as HTMLInputElement;
  const confirm       = document.getElementById("confirm")        as HTMLInputElement;
  const mismatch      = document.getElementById("mismatch")!;
  const errorBanner   = document.getElementById("error-banner")!;
  const successBanner = document.getElementById("success-banner")!;
  const submitBtn     = form.querySelector("button[type=submit]") as HTMLButtonElement;

  confirm.addEventListener("input", () => {
    const bad = confirm.value.length > 0 && pw.value !== confirm.value;
    mismatch.classList.toggle("hidden", !bad);
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (pw.value !== confirm.value) return confirm.focus();
    submitBtn.disabled = true;
    submitBtn.textContent = "Updating…";
    errorBanner.classList.add("hidden");
    try {
      const fd  = new FormData(form);
      const res = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token: fd.get("token"), password: fd.get("password") }),
      });
      if (!res.ok) {
        const { message } = await res.json().catch(() => ({ message: "Reset failed." }));
        throw new Error(message);
      }
      successBanner.classList.remove("hidden");
      form.classList.add("hidden");
      setTimeout(() => (window.location.href = "/auth/login?reset=success"), 2500);
    } catch (err) {
      errorBanner.textContent = err instanceof Error ? err.message : "Reset failed.";
      errorBanner.classList.remove("hidden");
      submitBtn.disabled = false;
      submitBtn.textContent = "Reset Password";
    }
  });
</script>
ASTRO

success "Auth pages written."

# =============================================================================
# 15. Pages — Dashboard
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

  <!-- KPI cards (populated via client-side fetch) -->
  <div id="kpi-grid" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
    {["Revenue", "Expenses", "Net Income", "Cash Balance"].map(label => (
      <div class="bg-surface-800 border border-surface-700 rounded-xl p-5">
        <p class="text-xs text-slate-400 uppercase tracking-widest mb-1">{label}</p>
        <p class="text-2xl font-bold text-white kpi-value">—</p>
        <p class="text-xs text-slate-500 mt-1 kpi-period">Loading…</p>
      </div>
    ))}
  </div>

  <!-- Connect prompt if no QBO connection -->
  <div id="connect-prompt" class="hidden rounded-xl border border-brand-700 bg-brand-900/20 px-6 py-5 flex items-center gap-4">
    <div class="text-3xl">🔗</div>
    <div>
      <p class="font-medium text-white text-sm">Connect QuickBooks to see live data</p>
      <p class="text-xs text-slate-400 mt-0.5">Sync your P&amp;L, cash flow, and more in seconds.</p>
    </div>
    <a href="/dashboard/connect" class="ml-auto shrink-0 rounded-lg bg-brand-600 hover:bg-brand-500 px-4 py-2 text-sm font-semibold text-white transition-colors">
      Connect
    </a>
  </div>
</DashboardLayout>

<script>
  async function loadKPIs() {
    try {
      const res = await fetch("/api/qbo/summary");
      if (res.status === 404) {
        document.getElementById("connect-prompt")?.classList.remove("hidden");
        return;
      }
      if (!res.ok) return;
      const data = await res.json() as { revenue: number; expenses: number; netIncome: number; cash: number; period: string };
      const values = [data.revenue, data.expenses, data.netIncome, data.cash];
      const fmt    = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });
      document.querySelectorAll(".kpi-value").forEach((el, i) => {
        (el as HTMLElement).textContent = fmt.format(values[i]);
      });
      document.querySelectorAll(".kpi-period").forEach(el => {
        (el as HTMLElement).textContent = data.period;
      });
    } catch { /* silent */ }
  }
  loadKPIs();
</script>
ASTRO

cat > src/pages/dashboard/profit-loss.astro <<'ASTRO'
---
import DashboardLayout from "@/layouts/DashboardLayout.astro";
---
<DashboardLayout title="Profit & Loss">
  <div class="flex items-center justify-between mb-6">
    <div>
      <h2 class="text-lg font-semibold text-white">Profit & Loss</h2>
      <p class="text-sm text-slate-400 mt-0.5">Income and expense breakdown from QuickBooks.</p>
    </div>
    <div class="flex gap-2">
      <input type="month" id="start-date" class="rounded-lg border border-surface-700 bg-surface-800 px-3 py-1.5 text-sm text-white" />
      <input type="month" id="end-date"   class="rounded-lg border border-surface-700 bg-surface-800 px-3 py-1.5 text-sm text-white" />
      <button id="fetch-btn" class="rounded-lg bg-brand-600 hover:bg-brand-500 px-4 py-1.5 text-sm font-semibold text-white transition-colors">Run</button>
    </div>
  </div>

  <div id="pl-table-wrap" class="bg-surface-800 border border-surface-700 rounded-xl overflow-hidden">
    <div id="pl-placeholder" class="py-20 text-center text-slate-500 text-sm">
      Select a date range and click Run.
    </div>
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
  const fmt = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });
  const btn = document.getElementById("fetch-btn") as HTMLButtonElement;
  const startInput = document.getElementById("start-date") as HTMLInputElement;
  const endInput   = document.getElementById("end-date")   as HTMLInputElement;

  // Default to current month
  const now = new Date();
  const y = now.getFullYear(), m = String(now.getMonth() + 1).padStart(2, "0");
  startInput.value = `${y}-${m}`;
  endInput.value   = `${y}-${m}`;

  btn.addEventListener("click", async () => {
    if (!startInput.value || !endInput.value) return;
    btn.disabled = true;
    btn.textContent = "Loading…";
    try {
      const start = startInput.value + "-01";
      const end   = endInput.value   + "-" + new Date(parseInt(endInput.value.split("-")[0]), parseInt(endInput.value.split("-")[1]), 0).getDate();
      const res   = await fetch(`/api/qbo/profit-loss?start=${start}&end=${end}`);
      if (!res.ok) throw new Error();
      const pl = await res.json() as { rows: { account: string; type: string; amount: number }[]; totalRevenue: number; totalExpenses: number; netIncome: number };

      const tbody = document.getElementById("pl-body")!;
      tbody.innerHTML = pl.rows.map(r => `
        <tr class="hover:bg-surface-700 transition-colors">
          <td class="px-6 py-3 text-white">${r.account}</td>
          <td class="px-6 py-3"><span class="px-2 py-0.5 rounded text-xs font-medium ${r.type === "income" ? "bg-emerald-900/40 text-emerald-300" : "bg-red-900/40 text-red-300"}">${r.type}</span></td>
          <td class="px-6 py-3 text-right ${r.type === "income" ? "text-emerald-400" : "text-red-400"}">${fmt.format(r.amount)}</td>
        </tr>`).join("");

      document.getElementById("pl-footer")!.innerHTML = `
        <tr class="border-t border-surface-600">
          <td class="px-6 py-3" colspan="2">Net Income</td>
          <td class="px-6 py-3 text-right ${pl.netIncome >= 0 ? "text-emerald-400" : "text-red-400"}">${fmt.format(pl.netIncome)}</td>
        </tr>`;

      document.getElementById("pl-placeholder")?.classList.add("hidden");
      document.getElementById("pl-table")?.classList.remove("hidden");
    } catch {
      alert("Failed to load P&L data. Ensure QuickBooks is connected.");
    } finally {
      btn.disabled = false;
      btn.textContent = "Run";
    }
  });
</script>
ASTRO

cat > src/pages/dashboard/connect.astro <<'ASTRO'
---
import DashboardLayout from "@/layouts/DashboardLayout.astro";
const success = Astro.url.searchParams.has("success");
const error   = Astro.url.searchParams.has("error");
---
<DashboardLayout title="Connect QuickBooks">
  <div class="max-w-lg mx-auto mt-8">
    {success && (
      <div class="mb-6 rounded-xl bg-emerald-900/40 border border-emerald-700 px-5 py-4 text-sm text-emerald-300">
        ✓ QuickBooks connected successfully! Your financial data is now syncing.
      </div>
    )}
    {error && (
      <div class="mb-6 rounded-xl bg-red-900/40 border border-red-700 px-5 py-4 text-sm text-red-300">
        Connection failed. Please try again or contact support.
      </div>
    )}
    <div class="bg-surface-800 border border-surface-700 rounded-2xl p-8 text-center">
      <div class="text-5xl mb-4">📒</div>
      <h2 class="text-xl font-semibold text-white mb-2">Connect QuickBooks Online</h2>
      <p class="text-sm text-slate-400 mb-8 leading-relaxed">
        Sync your company's P&amp;L, cash flow, and account balances directly from QuickBooks Online. Insight Hunter reads your data — it never writes or modifies your books.
      </p>
      <a
        href="/api/qbo/connect"
        class="inline-block rounded-xl bg-brand-600 hover:bg-brand-500 px-8 py-3 text-sm font-semibold text-white transition-colors shadow-lg shadow-brand-600/20"
      >
        Connect QuickBooks →
      </a>
      <p class="mt-4 text-xs text-slate-500">
        You'll be redirected to Intuit to authorize access. Read-only permissions only.
      </p>
    </div>
  </div>
</DashboardLayout>
ASTRO

success "Dashboard pages written."

# =============================================================================
# 16. API routes
# =============================================================================
info "Writing API routes…"

cat > src/pages/api/auth/login.ts <<'TS'
import type { APIRoute } from "astro";
import { getUser, createSession, setSessionCookie } from "@/lib/auth/session";
import type { Env, User } from "@/types";

export const POST: APIRoute = async ({ request, locals }) => {
  const env = (locals as any).runtime?.env as Env;

  try {
    const { email, password } = await request.json() as { email: string; password: string };
    if (!email || !password) {
      return new Response(JSON.stringify({ message: "Email and password are required." }), { status: 400 });
    }

    // Look up user by email index
    const userId = await env.IH_SESSIONS.get(`email:${email.toLowerCase()}`);
    if (!userId) {
      return new Response(JSON.stringify({ message: "Invalid credentials." }), { status: 401 });
    }

    const user = await getUser(env.IH_SESSIONS, userId);
    if (!user) {
      return new Response(JSON.stringify({ message: "Invalid credentials." }), { status: 401 });
    }

    // TODO: verify hashed password (e.g. using Web Crypto API / bcrypt WASM)
    // const valid = await verifyPassword(password, user.passwordHash);
    // if (!valid) return new Response(...401...);

    const ttl   = parseInt(env.SESSION_EXPIRY ?? "604800");
    const token = await createSession(env.IH_SESSIONS, user, ttl);
    const cookie = setSessionCookie(token, ttl);

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "Set-Cookie": cookie, "Content-Type": "application/json" },
    });
  } catch {
    return new Response(JSON.stringify({ message: "Internal error." }), { status: 500 });
  }
};
TS

cat > src/pages/api/auth/logout.ts <<'TS'
import type { APIRoute } from "astro";
import { getSessionToken, deleteSession, clearSessionCookie } from "@/lib/auth/session";
import type { Env } from "@/types";

export const POST: APIRoute = async ({ request, locals, redirect }) => {
  const env   = (locals as any).runtime?.env as Env;
  const token = getSessionToken(request);
  if (token) await deleteSession(env.IH_SESSIONS, token);
  return redirect("/auth/login", 302, {
    headers: { "Set-Cookie": clearSessionCookie() },
  } as any);
};
TS

cat > src/pages/api/qbo/connect.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env } from "@/types";

const SCOPES = [
  "com.intuit.quickbooks.accounting",
].join(" ");

export const GET: APIRoute = async ({ locals, redirect }) => {
  const env = (locals as any).runtime?.env as Env;

  const state = crypto.randomUUID();
  const params = new URLSearchParams({
    client_id:     env.QBO_CLIENT_ID,
    response_type: "code",
    scope:         SCOPES,
    redirect_uri:  env.QBO_REDIRECT_URI,
    state,
  });

  const authUrl = `https://appcenter.intuit.com/connect/oauth2?${params.toString()}`;
  return redirect(authUrl, 302);
};
TS

cat > src/pages/api/qbo/callback.ts <<'TS'
import type { APIRoute } from "astro";
import type { Env, QBOConnection, QBOTokenResponse } from "@/types";
import { getSessionToken, getSession } from "@/lib/auth/session";

export const GET: APIRoute = async ({ request, url, locals, redirect }) => {
  const env  = (locals as any).runtime?.env as Env;
  const code  = url.searchParams.get("code");
  const realm = url.searchParams.get("realmId");

  if (!code || !realm) return redirect("/dashboard/connect?error=1", 302);

  const token = getSessionToken(request);
  if (!token) return redirect("/auth/login", 302);
  const session = await getSession(env.IH_SESSIONS, token);
  if (!session) return redirect("/auth/login", 302);

  try {
    const creds = btoa(`${env.QBO_CLIENT_ID}:${env.QBO_CLIENT_SECRET}`);
    const res   = await fetch("https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer", {
      method: "POST",
      headers: {
        Authorization:  `Basic ${creds}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type:   "authorization_code",
        code,
        redirect_uri: env.QBO_REDIRECT_URI,
      }),
    });
    if (!res.ok) throw new Error("Token exchange failed");

    const tokens = await res.json() as QBOTokenResponse;

    // Fetch company name
    const infoRes = await fetch(
      `https://${env.QBO_ENVIRONMENT === "production" ? "quickbooks" : "sandbox-quickbooks"}.api.intuit.com/v3/company/${realm}/companyinfo/${realm}?minorversion=73`,
      { headers: { Authorization: `Bearer ${tokens.access_token}`, Accept: "application/json" } }
    );
    const infoData = infoRes.ok ? await infoRes.json() as any : {};
    const companyName: string = infoData?.CompanyInfo?.CompanyName ?? "My Company";

    const conn: QBOConnection = {
      realmId:      realm,
      accessToken:  tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresAt:    Date.now() + tokens.expires_in * 1000,
      companyName,
    };

    await env.IH_CACHE.put(`qbo:${session.userId}`, JSON.stringify(conn), {
      expirationTtl: tokens.x_refresh_token_expires_in,
    });

    return redirect("/dashboard/connect?success=1", 302);
  } catch {
    return redirect("/dashboard/connect?error=1", 302);
  }
};
TS

cat > src/pages/api/qbo/summary.ts <<'TS'
import type { APIRoute } from "astro";
import { QBOClient } from "@/lib/qbo/client";
import { getSessionToken, getSession } from "@/lib/auth/session";
import type { Env, QBOConnection } from "@/types";

export const GET: APIRoute = async ({ request, locals }) => {
  const env     = (locals as any).runtime?.env as Env;
  const token   = getSessionToken(request);
  const session = token ? await getSession(env.IH_SESSIONS, token) : null;
  if (!session) return new Response(null, { status: 401 });

  const raw = await env.IH_CACHE.get(`qbo:${session.userId}`);
  if (!raw) return new Response(null, { status: 404 });

  const conn   = JSON.parse(raw) as QBOConnection;
  const client = new QBOClient(conn, (env.QBO_ENVIRONMENT as any) ?? "sandbox");

  const now   = new Date();
  const start = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`;
  const end   = now.toISOString().split("T")[0];

  const [pl, cash] = await Promise.all([
    client.getProfitAndLoss(start, end),
    client.getCashSummary(),
  ]);

  return new Response(JSON.stringify({
    revenue:  pl.totalRevenue,
    expenses: pl.totalExpenses,
    netIncome: pl.netIncome,
    cash: cash.balance,
    period: `${start} – ${end}`,
  }), { headers: { "Content-Type": "application/json" } });
};
TS

cat > src/pages/api/qbo/profit-loss.ts <<'TS'
import type { APIRoute } from "astro";
import { QBOClient } from "@/lib/qbo/client";
import { getSessionToken, getSession } from "@/lib/auth/session";
import type { Env, QBOConnection } from "@/types";

export const GET: APIRoute = async ({ request, url, locals }) => {
  const env     = (locals as any).runtime?.env as Env;
  const token   = getSessionToken(request);
  const session = token ? await getSession(env.IH_SESSIONS, token) : null;
  if (!session) return new Response(null, { status: 401 });

  const start = url.searchParams.get("start");
  const end   = url.searchParams.get("end");
  if (!start || !end) return new Response(JSON.stringify({ message: "start and end required." }), { status: 400 });

  const raw = await env.IH_CACHE.get(`qbo:${session.userId}`);
  if (!raw) return new Response(null, { status: 404 });

  const conn   = JSON.parse(raw) as QBOConnection;
  const client = new QBOClient(conn, (env.QBO_ENVIRONMENT as any) ?? "sandbox");
  const pl     = await client.getProfitAndLoss(start, end);

  return new Response(JSON.stringify(pl), { headers: { "Content-Type": "application/json" } });
};
TS

success "API routes written."

# =============================================================================
# 17. Index page
# =============================================================================
info "Writing src/pages/index.astro…"
cat > src/pages/index.astro <<'ASTRO'
---
// Redirect authenticated users to dashboard
import { getSessionToken, getSession } from "@/lib/auth/session";
import type { Env } from "@/types";

const env   = (Astro.locals as any).runtime?.env as Env | undefined;
const token = getSessionToken(Astro.request);
if (env && token) {
  const session = await getSession(env.IH_SESSIONS, token);
  if (session) return Astro.redirect("/dashboard", 302);
}
return Astro.redirect("/auth/login", 302);
---
ASTRO
success "index.astro written."

# =============================================================================
# 18. Install dependencies
# =============================================================================
echo ""
info "Installing dependencies…"
npm install
success "Dependencies installed."

# =============================================================================
# Done
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}✔ Insight Hunter Lite scaffolded at ./${PROJECT_DIR}${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. ${CYAN}cp .env.example .env${RESET}  — fill in your secrets"
echo -e "  2. ${CYAN}£_ kv:namespace create IH_SESSIONS${RESET}  — then paste the ID into wrangler.jsonc"
echo -e "  3. ${CYAN}wrangler kv:namespace create IH_CACHE${RESET}     — same"
echo -e "  4. ${CYAN}wrangler secret put JWT_SECRET${RESET}"
echo -e "  5. ${CYAN}wrangler secret put QBO_CLIENT_ID${RESET}"
echo -e "  6. ${CYAN}wrangler secret put QBO_CLIENT_SECRET${RESET}"
echo -e "  7. ${CYAN}npm run dev${RESET}  — start local dev server"
echo -e "  8. ${CYAN}npm run deploy${RESET}  — build and deploy to Cloudflare Workers"
echo ""
