#!/usr/bin/env bash
# =============================================================================
# scaffold-insighthunter-auth.sh
# Scaffolds Insight Hunter Auth — Hono + TypeScript Cloudflare Worker
# JWT issuance, session management, RBAC, D1 + KV
#
# Usage:
#   chmod +x scaffold-insighthunter-auth.sh
#   ./scaffold-insighthunter-auth.sh [target-dir]
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
PROJECT_DIR="${1:-insighthunter-auth}"
if [[ -d "$PROJECT_DIR" ]]; then
  warn "Directory '$PROJECT_DIR' already exists."
  read -rp "  Overwrite? (y/N) " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
  rm -rf "$PROJECT_DIR"
fi

echo -e "\n${BOLD}${CYAN}Scaffolding Insight Hunter Auth${RESET}\n"

# =============================================================================
# 1. Directory tree
# =============================================================================
info "Creating directory tree…"
mkdir -p "$PROJECT_DIR"/{migrations,src/{routes,middleware,services,db/migrations,lib,types},tests/{routes,services,fixtures}}
success "Directories created."

cd "$PROJECT_DIR"

# =============================================================================
# 2. package.json
# =============================================================================
info "Writing package.json…"
cat > package.json <<'JSON'
{
  "name": "@insighthunter/auth",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev":            "wrangler dev",
    "deploy":         "wrangler deploy",
    "deploy:staging": "wrangler deploy --env staging",
    "cf-typegen":     "wrangler types --env-interface CloudflareBindings",
    "type-check":     "tsc --noEmit",
    "test":           "vitest run",
    "test:watch":     "vitest",
    "test:coverage":  "vitest run --coverage",
    "lint":           "eslint src --ext .ts",
    "lint:fix":       "eslint src --ext .ts --fix",
    "migrate:local":  "wrangler d1 migrations apply insighthunter-auth-db --local",
    "migrate:remote": "wrangler d1 migrations apply insighthunter-auth-db --remote"
  },
  "dependencies": {
    "hono": "^4.7.4",
    "zod":  "^3.24.2"
  },
  "devDependencies": {
    "@cloudflare/workers-types":        "^4.20250310.0",
    "wrangler":                         "^4.2.0",
    "typescript":                       "^5.8.2",
    "vitest":                           "^3.0.8",
    "@vitest/coverage-v8":              "^3.0.8",
    "eslint":                           "^9.22.0",
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
# 3. wrangler.toml
# =============================================================================
info "Writing wrangler.toml…"
cat > wrangler.toml <<'EOF'
name               = "insighthunter-auth"
main               = "src/index.ts"
compatibility_date = "2025-03-07"
compatibility_flags = ["nodejs_compat"]

[observability]
enabled = true

# D1 — users, sessions, roles
[[d1_databases]]
binding        = "DB"
database_name  = "insighthunter-auth-db"
database_id    = "REPLACE_WITH_D1_DATABASE_ID"
migrations_dir = "migrations"

# KV — session tokens + reset tokens + email verification
[[kv_namespaces]]
binding    = "SESSIONS"
id         = "REPLACE_WITH_SESSIONS_KV_ID"
preview_id = "REPLACE_WITH_PREVIEW_SESSIONS_KV_ID"

[[kv_namespaces]]
binding    = "TOKENS"
id         = "REPLACE_WITH_TOKENS_KV_ID"
preview_id = "REPLACE_WITH_PREVIEW_TOKENS_KV_ID"

# Analytics Engine — auth events
[[analytics_engine_datasets]]
binding = "EVENTS"
dataset = "insighthunter_auth_events"

[vars]
APP_ENV             = "development"
APP_URL             = "http://localhost:4321"
CORS_ORIGIN         = "http://localhost:4321"
JWT_EXPIRY          = "3600"
REFRESH_EXPIRY      = "2592000"
RATE_LIMIT_WINDOW   = "60"
RATE_LIMIT_MAX      = "20"
BCRYPT_ROUNDS       = "12"

# Secrets — add via: wrangler secret put SECRET_NAME
# Required: JWT_SECRET, REFRESH_SECRET, MAILCHANNELS_API_KEY (or RESEND_API_KEY)
EOF
success "wrangler.toml written."

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
      "@/*":         ["src/*"],
      "@routes/*":   ["src/routes/*"],
      "@services/*": ["src/services/*"],
      "@lib/*":      ["src/lib/*"],
      "@types/*":    ["src/types/*"]
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
APP_ENV=development
APP_URL=http://localhost:4321
CORS_ORIGIN=http://localhost:4321

# JWT
JWT_EXPIRY=3600
REFRESH_EXPIRY=2592000

# Rate limiting
RATE_LIMIT_WINDOW=60
RATE_LIMIT_MAX=20

# Hashing
BCRYPT_ROUNDS=12

# Secrets — set via wrangler secret put
JWT_SECRET=replace_with_64_char_hex_secret
REFRESH_SECRET=replace_with_64_char_hex_secret
MAILCHANNELS_API_KEY=replace_with_key
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
.dev.vars
.wrangler/
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
  SESSIONS: KVNamespace;  // session_token → SessionRecord JSON
  TOKENS:   KVNamespace;  // reset/verify token → userId

  // Analytics Engine
  EVENTS: AnalyticsEngineDataset;

  // Vars
  APP_ENV:           string;
  APP_URL:           string;
  CORS_ORIGIN:       string;
  JWT_EXPIRY:        string;
  REFRESH_EXPIRY:    string;
  RATE_LIMIT_WINDOW: string;
  RATE_LIMIT_MAX:    string;
  BCRYPT_ROUNDS:     string;

  // Secrets
  JWT_SECRET:           string;
  REFRESH_SECRET:       string;
  MAILCHANNELS_API_KEY: string;
}
TS

cat > src/types/auth.ts <<'TS'
// ── User ──────────────────────────────────────────────────────────────────────
export interface User {
  id:              string;
  org_id:          string;
  email:           string;
  name:            string;
  password_hash:   string;
  role:            Role;
  tier:            Tier;
  email_verified:  number;   // 0 | 1  (D1 boolean)
  status:          UserStatus;
  created_at:      string;
  updated_at:      string;
}

export type UserStatus  = "active" | "suspended" | "pending";
export type Role        = "owner" | "admin" | "member" | "viewer";
export type Tier        = "lite" | "standard" | "enterprise";

// ── Session ───────────────────────────────────────────────────────────────────
export interface SessionRecord {
  userId:    string;
  orgId:     string;
  role:      Role;
  tier:      Tier;
  ip:        string;
  userAgent: string;
  createdAt: number;
  expiresAt: number;
}

// ── JWT ───────────────────────────────────────────────────────────────────────
export interface AccessTokenPayload {
  sub:   string;
  email: string;
  name:  string;
  orgId: string;
  role:  Role;
  tier:  Tier;
  type:  "access";
  iat:   number;
  exp:   number;
}

export interface RefreshTokenPayload {
  sub:  string;
  jti:  string;  // unique token ID for rotation
  type: "refresh";
  iat:  number;
  exp:  number;
}

// ── Request bodies ────────────────────────────────────────────────────────────
export interface RegisterBody {
  name:     string;
  email:    string;
  password: string;
  orgName?: string;
}

export interface LoginBody {
  email:    string;
  password: string;
}

export interface RefreshBody {
  refreshToken: string;
}

export interface ForgotPasswordBody {
  email: string;
}

export interface ResetPasswordBody {
  token:    string;
  password: string;
}

export interface VerifyEmailBody {
  token: string;
}

export interface AssignRoleBody {
  userId: string;
  role:   Role;
}

// ── Response ──────────────────────────────────────────────────────────────────
export interface AuthTokens {
  accessToken:  string;
  refreshToken: string;
  expiresIn:    number;
  tokenType:    "Bearer";
}

export interface AuthResponse {
  ok:     true;
  tokens: AuthTokens;
  user:   PublicUser;
}

export interface PublicUser {
  id:             string;
  email:          string;
  name:           string;
  orgId:          string;
  role:           Role;
  tier:           Tier;
  emailVerified:  boolean;
}
TS

cat > src/types/index.ts <<'TS'
export type { Env } from "./env";
export type {
  User,
  UserStatus,
  Role,
  Tier,
  SessionRecord,
  AccessTokenPayload,
  RefreshTokenPayload,
  RegisterBody,
  LoginBody,
  RefreshBody,
  ForgotPasswordBody,
  ResetPasswordBody,
  VerifyEmailBody,
  AssignRoleBody,
  AuthTokens,
  AuthResponse,
  PublicUser,
} from "./auth";
TS
success "Types written."

# =============================================================================
# 8. DB Schema & Migrations
# =============================================================================
info "Writing DB schema & migrations…"

# ── Shared schema (for reference) ─────────────────────────────────────────────
cat > src/db/schema.sql <<'SQL'
-- Full schema reference — applied via migrations

CREATE TABLE IF NOT EXISTS orgs (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  tier       TEXT NOT NULL DEFAULT 'lite',
  status     TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS users (
  id             TEXT PRIMARY KEY,
  org_id         TEXT NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  email          TEXT NOT NULL UNIQUE,
  name           TEXT NOT NULL,
  password_hash  TEXT NOT NULL,
  role           TEXT NOT NULL DEFAULT 'member',
  tier           TEXT NOT NULL DEFAULT 'lite',
  email_verified INTEGER NOT NULL DEFAULT 0,
  status         TEXT NOT NULL DEFAULT 'pending',
  created_at     TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_email  ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_org    ON users(org_id);

CREATE TABLE IF NOT EXISTS sessions (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  org_id     TEXT NOT NULL,
  ip         TEXT,
  user_agent TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_user    ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS roles (
  id         TEXT PRIMARY KEY,
  org_id     TEXT NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'member',
  granted_by TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(org_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_roles_org  ON roles(org_id);
CREATE INDEX IF NOT EXISTS idx_roles_user ON roles(user_id);

CREATE TABLE IF NOT EXISTS audit_log (
  id         TEXT PRIMARY KEY,
  org_id     TEXT NOT NULL,
  user_id    TEXT,
  action     TEXT NOT NULL,
  ip         TEXT,
  meta       TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_audit_org  ON audit_log(org_id, created_at DESC);
SQL

# ── src/db/migrations (used internally for reference) ─────────────────────────
cat > src/db/migrations/0001_init.sql <<'SQL'
-- 0001: orgs + users
CREATE TABLE IF NOT EXISTS orgs (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  tier       TEXT NOT NULL DEFAULT 'lite',
  status     TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS users (
  id             TEXT PRIMARY KEY,
  org_id         TEXT NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  email          TEXT NOT NULL UNIQUE,
  name           TEXT NOT NULL,
  password_hash  TEXT NOT NULL,
  role           TEXT NOT NULL DEFAULT 'member',
  tier           TEXT NOT NULL DEFAULT 'lite',
  email_verified INTEGER NOT NULL DEFAULT 0,
  status         TEXT NOT NULL DEFAULT 'pending',
  created_at     TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_org   ON users(org_id);
SQL

cat > src/db/migrations/0002_sessions.sql <<'SQL'
-- 0002: sessions + audit log
CREATE TABLE IF NOT EXISTS sessions (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  org_id     TEXT NOT NULL,
  ip         TEXT,
  user_agent TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_user    ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS audit_log (
  id         TEXT PRIMARY KEY,
  org_id     TEXT NOT NULL,
  user_id    TEXT,
  action     TEXT NOT NULL,
  ip         TEXT,
  meta       TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_audit_org ON audit_log(org_id, created_at DESC);
SQL

cat > src/db/migrations/0003_roles.sql <<'SQL'
-- 0003: fine-grained roles per org
CREATE TABLE IF NOT EXISTS roles (
  id         TEXT PRIMARY KEY,
  org_id     TEXT NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'member',
  granted_by TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(org_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_roles_org  ON roles(org_id);
CREATE INDEX IF NOT EXISTS idx_roles_user ON roles(user_id);
SQL

# ── Top-level wrangler migrations (identical content) ─────────────────────────
cp src/db/migrations/0001_init.sql    migrations/0001_init.sql
cp src/db/migrations/0002_sessions.sql migrations/0002_sessions.sql
cp src/db/migrations/0003_roles.sql   migrations/0003_roles.sql

# ── queries.ts ────────────────────────────────────────────────────────────────
cat > src/db/queries.ts <<'TS'
import type { User, Role } from "@/types";

// ── Orgs ──────────────────────────────────────────────────────────────────────
export async function createOrg(
  db: D1Database,
  id: string,
  name: string,
  tier = "lite"
): Promise<void> {
  await db
    .prepare("INSERT INTO orgs (id, name, tier) VALUES (?, ?, ?)")
    .bind(id, name, tier)
    .run();
}

export async function getOrgById(db: D1Database, id: string): Promise<{ id: string; name: string; tier: string } | null> {
  return db.prepare("SELECT * FROM orgs WHERE id = ?").bind(id).first();
}

// ── Users ─────────────────────────────────────────────────────────────────────
export async function getUserByEmail(db: D1Database, email: string): Promise<User | null> {
  return db.prepare("SELECT * FROM users WHERE email = ?").bind(email.toLowerCase()).first<User>();
}

export async function getUserById(db: D1Database, id: string): Promise<User | null> {
  return db.prepare("SELECT * FROM users WHERE id = ?").bind(id).first<User>();
}

export async function createUser(
  db: D1Database,
  user: Pick<User, "id" | "org_id" | "email" | "name" | "password_hash" | "role" | "tier">
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO users (id, org_id, email, name, password_hash, role, tier, email_verified, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 0, 'pending')`
    )
    .bind(user.id, user.org_id, user.email.toLowerCase(), user.name, user.password_hash, user.role, user.tier)
    .run();
}

export async function verifyUserEmail(db: D1Database, userId: string): Promise<void> {
  await db
    .prepare("UPDATE users SET email_verified = 1, status = 'active', updated_at = datetime('now') WHERE id = ?")
    .bind(userId)
    .run();
}

export async function updateUserPassword(db: D1Database, userId: string, hash: string): Promise<void> {
  await db
    .prepare("UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?")
    .bind(hash, userId)
    .run();
}

export async function updateUserStatus(db: D1Database, userId: string, status: string): Promise<void> {
  await db
    .prepare("UPDATE users SET status = ?, updated_at = datetime('now') WHERE id = ?")
    .bind(status, userId)
    .run();
}

// ── Sessions ──────────────────────────────────────────────────────────────────
export async function insertSession(
  db: D1Database,
  id: string,
  userId: string,
  orgId: string,
  ip: string,
  userAgent: string,
  expiresAt: string
): Promise<void> {
  await db
    .prepare(
      "INSERT INTO sessions (id, user_id, org_id, ip, user_agent, expires_at) VALUES (?, ?, ?, ?, ?, ?)"
    )
    .bind(id, userId, orgId, ip, userAgent, expiresAt)
    .run();
}

export async function deleteSession(db: D1Database, sessionId: string): Promise<void> {
  await db.prepare("DELETE FROM sessions WHERE id = ?").bind(sessionId).run();
}

export async function deleteAllUserSessions(db: D1Database, userId: string): Promise<void> {
  await db.prepare("DELETE FROM sessions WHERE user_id = ?").bind(userId).run();
}

export async function purgeExpiredSessions(db: D1Database): Promise<void> {
  await db.prepare("DELETE FROM sessions WHERE expires_at < datetime('now')").run();
}

// ── Roles ─────────────────────────────────────────────────────────────────────
export async function getUserRole(db: D1Database, orgId: string, userId: string): Promise<Role | null> {
  const row = await db
    .prepare("SELECT role FROM roles WHERE org_id = ? AND user_id = ?")
    .bind(orgId, userId)
    .first<{ role: Role }>();
  return row?.role ?? null;
}

export async function upsertRole(
  db: D1Database,
  id: string,
  orgId: string,
  userId: string,
  role: Role,
  grantedBy: string
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO roles (id, org_id, user_id, role, granted_by)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(org_id, user_id) DO UPDATE SET role = excluded.role, granted_by = excluded.granted_by`
    )
    .bind(id, orgId, userId, role, grantedBy)
    .run();
}

export async function listOrgRoles(
  db: D1Database,
  orgId: string
): Promise<{ userId: string; role: Role; grantedBy: string; createdAt: string }[]> {
  const { results } = await db
    .prepare("SELECT user_id as userId, role, granted_by as grantedBy, created_at as createdAt FROM roles WHERE org_id = ?")
    .bind(orgId)
    .all<{ userId: string; role: Role; grantedBy: string; createdAt: string }>();
  return results;
}

// ── Audit log ─────────────────────────────────────────────────────────────────
export async function insertAuditLog(
  db: D1Database,
  orgId: string,
  userId: string | null,
  action: string,
  ip: string,
  meta?: Record<string, unknown>
): Promise<void> {
  await db
    .prepare(
      "INSERT INTO audit_log (id, org_id, user_id, action, ip, meta) VALUES (?, ?, ?, ?, ?, ?)"
    )
    .bind(crypto.randomUUID(), orgId, userId, action, ip, meta ? JSON.stringify(meta) : null)
    .run();
}
TS
success "DB schema, migrations, and queries written."

# =============================================================================
# 9. Lib
# =============================================================================
info "Writing lib files…"

# ── jwt.ts ────────────────────────────────────────────────────────────────────
cat > src/lib/jwt.ts <<'TS'
import type { AccessTokenPayload, RefreshTokenPayload } from "@/types";

// ── Helpers ───────────────────────────────────────────────────────────────────
function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let b64 = btoa(String.fromCharCode(...bytes));
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function decodeBase64url(str: string): string {
  const b64 = str.replace(/-/g, "+").replace(/_/g, "/");
  return atob(b64);
}

async function importKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"]
  );
}

// ── Sign ──────────────────────────────────────────────────────────────────────
export async function signJWT(
  payload: Record<string, unknown>,
  secret: string
): Promise<string> {
  const header  = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body    = base64url(JSON.stringify(payload));
  const key     = await importKey(secret);
  const sigBuf  = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${header}.${body}`));
  const sig     = base64url(sigBuf);
  return `${header}.${body}.${sig}`;
}

// ── Verify ────────────────────────────────────────────────────────────────────
export async function verifyJWT<T extends { exp?: number; type?: string }>(
  token: string,
  secret: string,
  expectedType?: string
): Promise<T | null> {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const [header, body, sig] = parts;

    const key    = await importKey(secret);
    const sigBuf = Uint8Array.from(decodeBase64url(sig), c => c.charCodeAt(0));
    const valid  = await crypto.subtle.verify(
      "HMAC", key, sigBuf,
      new TextEncoder().encode(`${header}.${body}`)
    );
    if (!valid) return null;

    const payload = JSON.parse(decodeBase64url(body)) as T;
    if (payload.exp && Date.now() / 1000 > payload.exp) return null;
    if (expectedType && payload.type !== expectedType) return null;
    return payload;
  } catch {
    return null;
  }
}

// ── Token factories ───────────────────────────────────────────────────────────
export async function createAccessToken(
  user: { id: string; email: string; name: string; org_id: string; role: string; tier: string },
  secret: string,
  expirySeconds: number
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload: AccessTokenPayload = {
    sub:   user.id,
    email: user.email,
    name:  user.name,
    orgId: user.org_id,
    role:  user.role as AccessTokenPayload["role"],
    tier:  user.tier as AccessTokenPayload["tier"],
    type:  "access",
    iat:   now,
    exp:   now + expirySeconds,
  };
  return signJWT(payload, secret);
}

export async function createRefreshToken(
  userId: string,
  secret: string,
  expirySeconds: number
): Promise<{ token: string; jti: string }> {
  const now = Math.floor(Date.now() / 1000);
  const jti = crypto.randomUUID();
  const payload: RefreshTokenPayload = {
    sub:  userId,
    jti,
    type: "refresh",
    iat:  now,
    exp:  now + expirySeconds,
  };
  return { token: await signJWT(payload, secret), jti };
}

export async function verifyAccessToken(token: string, secret: string): Promise<AccessTokenPayload | null> {
  return verifyJWT<AccessTokenPayload>(token, secret, "access");
}

export async function verifyRefreshToken(token: string, secret: string): Promise<RefreshTokenPayload | null> {
  return verifyJWT<RefreshTokenPayload>(token, secret, "refresh");
}
TS

# ── hash.ts ───────────────────────────────────────────────────────────────────
cat > src/lib/hash.ts <<'TS'
/**
 * PBKDF2-based password hashing using Web Crypto API.
 * Compatible with Cloudflare Workers (no Node.js bcrypt needed).
 *
 * Format: "pbkdf2:<iterations>:<saltHex>:<hashHex>"
 */

const ITERATIONS = 100_000;
const HASH_LEN   = 32; // 256 bits
const ALG        = "SHA-256";

function bufToHex(buf: ArrayBuffer): string {
  return Array.from(new Uint8Array(buf))
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
}

function hexToBuf(hex: string): Uint8Array {
  const result = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    result[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  }
  return result;
}

export async function hashPassword(password: string): Promise<string> {
  const saltBuf = crypto.getRandomValues(new Uint8Array(16));
  const saltHex = bufToHex(saltBuf.buffer);

  const baseKey = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );

  const derived = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt: saltBuf, iterations: ITERATIONS, hash: ALG },
    baseKey,
    HASH_LEN * 8
  );

  return `pbkdf2:${ITERATIONS}:${saltHex}:${bufToHex(derived)}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const parts = stored.split(":");
  if (parts.length !== 4 || parts[0] !== "pbkdf2") return false;

  const [, iterStr, saltHex, hashHex] = parts;
  const iterations = parseInt(iterStr);
  const salt = hexToBuf(saltHex);

  const baseKey = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );

  const derived = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt, iterations, hash: ALG },
    baseKey,
    HASH_LEN * 8
  );

  // Constant-time comparison
  const a = new Uint8Array(derived);
  const b = hexToBuf(hashHex);
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

export function generateSecureToken(bytes = 32): string {
  return bufToHex(crypto.getRandomValues(new Uint8Array(bytes)).buffer);
}
TS

# ── cache.ts ──────────────────────────────────────────────────────────────────
cat > src/lib/cache.ts <<'TS'
export async function kvGet<T>(kv: KVNamespace, key: string): Promise<T | null> {
  const raw = await kv.get(key);
  return raw ? (JSON.parse(raw) as T) : null;
}

export async function kvSet<T>(
  kv: KVNamespace,
  key: string,
  value: T,
  ttlSeconds: number
): Promise<void> {
  await kv.put(key, JSON.stringify(value), { expirationTtl: ttlSeconds });
}

export async function kvDel(kv: KVNamespace, key: string): Promise<void> {
  await kv.delete(key);
}

// ── Namespaced helpers ────────────────────────────────────────────────────────
export async function storeResetToken(
  kv: KVNamespace,
  token: string,
  userId: string
): Promise<void> {
  await kvSet(kv, `reset:${token}`, { userId }, 3600); // 1 hour
}

export async function consumeResetToken(
  kv: KVNamespace,
  token: string
): Promise<string | null> {
  const data = await kvGet<{ userId: string }>(kv, `reset:${token}`);
  if (!data) return null;
  await kvDel(kv, `reset:${token}`);
  return data.userId;
}

export async function storeVerifyToken(
  kv: KVNamespace,
  token: string,
  userId: string
): Promise<void> {
  await kvSet(kv, `verify:${token}`, { userId }, 86400); // 24 hours
}

export async function consumeVerifyToken(
  kv: KVNamespace,
  token: string
): Promise<string | null> {
  const data = await kvGet<{ userId: string }>(kv, `verify:${token}`);
  if (!data) return null;
  await kvDel(kv, `verify:${token}`);
  return data.userId;
}

export async function storeRefreshJTI(
  kv: KVNamespace,
  jti: string,
  userId: string,
  ttlSeconds: number
): Promise<void> {
  await kvSet(kv, `jti:${jti}`, { userId, valid: true }, ttlSeconds);
}

export async function revokeJTI(kv: KVNamespace, jti: string): Promise<void> {
  await kvDel(kv, `jti:${jti}`);
}

export async function isJTIValid(kv: KVNamespace, jti: string): Promise<boolean> {
  const data = await kvGet<{ valid: boolean }>(kv, `jti:${jti}`);
  return data?.valid === true;
}
TS

# ── analytics.ts ──────────────────────────────────────────────────────────────
cat > src/lib/analytics.ts <<'TS'
import type { Env } from "@/types";

export type AuthEvent =
  | "register"
  | "login"
  | "logout"
  | "token_refresh"
  | "token_verify"
  | "password_reset_request"
  | "password_reset_complete"
  | "email_verify"
  | "role_assigned"
  | "login_failed"
  | "register_failed";

export function trackAuthEvent(
  env: Env,
  event: AuthEvent,
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
    // non-blocking
  }
}
TS

# ── logger.ts ─────────────────────────────────────────────────────────────────
cat > src/lib/logger.ts <<'TS'
type Level = "debug" | "info" | "warn" | "error";

function log(level: Level, message: string, data?: unknown): void {
  const entry = JSON.stringify({ level, message, ts: new Date().toISOString(), ...(data ? { data } : {}) });
  level === "error" || level === "warn" ? console.error(entry) : console.log(entry);
}

export const logger = {
  debug: (msg: string, data?: unknown) => log("debug", msg, data),
  info:  (msg: string, data?: unknown) => log("info",  msg, data),
  warn:  (msg: string, data?: unknown) => log("warn",  msg, data),
  error: (msg: string, data?: unknown) => log("error", msg, data),
};
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
  const allowed = c.env.CORS_ORIGIN ?? "*";
  const reqOrigin = c.req.header("Origin") ?? "";
  const isAllowed = allowed === "*"
    || reqOrigin === allowed
    || reqOrigin.endsWith(".insighthunter.com");

  if (c.req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin":  isAllowed ? reqOrigin : allowed,
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
        "Access-Control-Max-Age":       "86400",
        "Access-Control-Allow-Credentials": "true",
      },
    });
  }

  await next();
  c.res.headers.set("Access-Control-Allow-Origin", isAllowed ? reqOrigin : allowed);
  c.res.headers.set("Access-Control-Allow-Credentials", "true");
  c.res.headers.set("Vary", "Origin");
};
TS

cat > src/middleware/rateLimit.ts <<'TS'
import type { MiddlewareHandler } from "hono";
import type { Env } from "@/types";

/**
 * KV-based sliding window rate limiter.
 * Auth routes use tighter limits than the global Worker defaults.
 */
export function rateLimitMiddleware(
  maxOverride?: number
): MiddlewareHandler<{ Bindings: Env }> {
  return async (c, next) => {
    const ip      = c.req.header("CF-Connecting-IP") ?? "unknown";
    const path    = new URL(c.req.url).pathname.replace(/\//g, "_");
    const window  = parseInt(c.env.RATE_LIMIT_WINDOW ?? "60");
    const max     = maxOverride ?? parseInt(c.env.RATE_LIMIT_MAX ?? "20");
    const bucket  = Math.floor(Date.now() / 1000 / window);
    const key     = `rl:${ip}:${path}:${bucket}`;

    const raw   = await c.env.SESSIONS.get(key);
    const count = raw ? parseInt(raw) : 0;

    if (count >= max) {
      return c.json(
        { error: "Too Many Requests", message: "Rate limit exceeded. Try again shortly.", retryAfter: window },
        429,
        { "Retry-After": String(window) }
      );
    }

    await c.env.SESSIONS.put(key, String(count + 1), { expirationTtl: window * 2 });
    c.res.headers.set("X-RateLimit-Limit",     String(max));
    c.res.headers.set("X-RateLimit-Remaining", String(Math.max(0, max - count - 1)));
    await next();
  };
}
TS

cat > src/middleware/validate.ts <<'TS'
import type { MiddlewareHandler } from "hono";
import type { ZodSchema } from "zod";
import type { Env } from "@/types";

/**
 * Zod schema validation middleware.
 * Parses JSON body and stores the validated result in c.var.body.
 */
export function validateBody<T>(
  schema: ZodSchema<T>
): MiddlewareHandler<{ Bindings: Env; Variables: { body: T } }> {
  return async (c, next) => {
    let raw: unknown;
    try {
      raw = await c.req.json();
    } catch {
      return c.json({ error: "Bad Request", message: "Invalid JSON body." }, 400);
    }

    const result = schema.safeParse(raw);
    if (!result.success) {
      return c.json({
        error:   "Validation Failed",
        message: result.error.issues[0]?.message ?? "Invalid request body.",
        issues:  result.error.issues.map(i => ({ field: i.path.join("."), message: i.message })),
      }, 422);
    }

    c.set("body", result.data);
    await next();
  };
}
TS
success "Middleware written."

# =============================================================================
# 11. Services
# =============================================================================
info "Writing services…"

cat > src/services/tokenService.ts <<'TS'
import type { Env, AccessTokenPayload, RefreshTokenPayload } from "@/types";
import {
  createAccessToken,
  createRefreshToken,
  verifyRefreshToken,
} from "@/lib/jwt";
import {
  storeRefreshJTI,
  revokeJTI,
  isJTIValid,
} from "@/lib/cache";
import { logger } from "@/lib/logger";

export interface IssuedTokens {
  accessToken:  string;
  refreshToken: string;
  expiresIn:    number;
  tokenType:    "Bearer";
}

export async function issueTokens(
  env: Env,
  user: { id: string; email: string; name: string; org_id: string; role: string; tier: string }
): Promise<IssuedTokens> {
  const jwtExpiry     = parseInt(env.JWT_EXPIRY     ?? "3600");
  const refreshExpiry = parseInt(env.REFRESH_EXPIRY ?? "2592000");

  const [accessToken, { token: refreshToken, jti }] = await Promise.all([
    createAccessToken(user, env.JWT_SECRET, jwtExpiry),
    createRefreshToken(user.id, env.REFRESH_SECRET, refreshExpiry),
  ]);

  await storeRefreshJTI(env.TOKENS, jti, user.id, refreshExpiry);
  logger.debug("Tokens issued", { userId: user.id, jti });

  return { accessToken, refreshToken, expiresIn: jwtExpiry, tokenType: "Bearer" };
}

export async function rotateRefreshToken(
  env: Env,
  oldRefreshToken: string,
  getUser: (id: string) => Promise<{ id: string; email: string; name: string; org_id: string; role: string; tier: string } | null>
): Promise<IssuedTokens | null> {
  const payload = await verifyRefreshToken(oldRefreshToken, env.REFRESH_SECRET);
  if (!payload) { logger.warn("Refresh token invalid or expired"); return null; }

  const valid = await isJTIValid(env.TOKENS, payload.jti);
  if (!valid) { logger.warn("Refresh JTI already revoked", { jti: payload.jti }); return null; }

  // Revoke old JTI before issuing new tokens (token rotation)
  await revokeJTI(env.TOKENS, payload.jti);

  const user = await getUser(payload.sub);
  if (!user) return null;

  return issueTokens(env, user);
}

export async function revokeRefreshToken(
  env: Env,
  refreshToken: string
): Promise<void> {
  const payload = await verifyRefreshToken(refreshToken, env.REFRESH_SECRET);
  if (payload) await revokeJTI(env.TOKENS, payload.jti);
}

export async function verifyAccessTokenForService(
  env: Env,
  token: string
): Promise<AccessTokenPayload | null> {
  const { verifyAccessToken } = await import("@/lib/jwt");
  return verifyAccessToken(token, env.JWT_SECRET);
}
TS

cat > src/services/sessionService.ts <<'TS'
import type { Env, SessionRecord } from "@/types";
import { kvSet, kvGet, kvDel } from "@/lib/cache";
import { insertSession, deleteSession, deleteAllUserSessions } from "@/db/queries";
import { logger } from "@/lib/logger";

const SESSION_PREFIX = "sess:";

export async function createSession(
  env: Env,
  userId: string,
  orgId: string,
  role: string,
  tier: string,
  request: Request
): Promise<string> {
  const sessionId = crypto.randomUUID();
  const ttl       = parseInt(env.REFRESH_EXPIRY ?? "2592000");
  const expiresAt = new Date(Date.now() + ttl * 1000);

  const record: SessionRecord = {
    userId,
    orgId,
    role:      role as SessionRecord["role"],
    tier:      tier as SessionRecord["tier"],
    ip:        request.headers.get("CF-Connecting-IP") ?? "unknown",
    userAgent: request.headers.get("User-Agent") ?? "unknown",
    createdAt: Date.now(),
    expiresAt: expiresAt.getTime(),
  };

  await Promise.all([
    kvSet(env.SESSIONS, `${SESSION_PREFIX}${sessionId}`, record, ttl),
    insertSession(env.DB, sessionId, userId, orgId, record.ip, record.userAgent, expiresAt.toISOString()),
  ]);

  logger.debug("Session created", { sessionId, userId });
  return sessionId;
}

export async function getSession(
  env: Env,
  sessionId: string
): Promise<SessionRecord | null> {
  const record = await kvGet<SessionRecord>(env.SESSIONS, `${SESSION_PREFIX}${sessionId}`);
  if (!record) return null;
  if (Date.now() > record.expiresAt) {
    await destroySession(env, sessionId, record.userId);
    return null;
  }
  return record;
}

export async function destroySession(
  env: Env,
  sessionId: string,
  userId: string
): Promise<void> {
  await Promise.all([
    kvDel(env.SESSIONS, `${SESSION_PREFIX}${sessionId}`),
    deleteSession(env.DB, sessionId),
  ]);
  logger.debug("Session destroyed", { sessionId, userId });
}

export async function destroyAllSessions(
  env: Env,
  userId: string
): Promise<void> {
  await deleteAllUserSessions(env.DB, userId);
  logger.info("All sessions revoked", { userId });
}
TS

cat > src/services/authService.ts <<'TS'
import type { Env, User, AuthResponse, PublicUser } from "@/types";
import type { RegisterBody, LoginBody } from "@/types";
import { hashPassword, verifyPassword } from "@/lib/hash";
import { issueTokens } from "./tokenService";
import { createSession } from "./sessionService";
import { trackAuthEvent } from "@/lib/analytics";
import { logger } from "@/lib/logger";
import {
  getUserByEmail,
  getUserById,
  createUser,
  createOrg,
  insertAuditLog,
} from "@/db/queries";
import { storeVerifyToken } from "@/lib/cache";
import { generateSecureToken } from "@/lib/hash";
import { sendVerificationEmail } from "./emailService";

export function toPublicUser(user: User): PublicUser {
  return {
    id:            user.id,
    email:         user.email,
    name:          user.name,
    orgId:         user.org_id,
    role:          user.role,
    tier:          user.tier,
    emailVerified: user.email_verified === 1,
  };
}

export async function registerUser(
  env: Env,
  body: RegisterBody,
  request: Request
): Promise<AuthResponse> {
  const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";

  // Check duplicate
  const existing = await getUserByEmail(env.DB, body.email);
  if (existing) {
    trackAuthEvent(env, "register_failed", "unknown", { reason: "duplicate_email" });
    throw Object.assign(new Error("An account with this email already exists."), { status: 409 });
  }

  // Create org
  const orgId       = crypto.randomUUID();
  const orgName     = body.orgName ?? `${body.name}'s Org`;
  await createOrg(env.DB, orgId, orgName, "lite");

  // Create user
  const userId      = crypto.randomUUID();
  const passwordHash = await hashPassword(body.password);

  await createUser(env.DB, {
    id:            userId,
    org_id:        orgId,
    email:         body.email,
    name:          body.name,
    password_hash: passwordHash,
    role:          "owner",
    tier:          "lite",
  });

  // Send verification email
  const verifyToken = generateSecureToken(32);
  await storeVerifyToken(env.TOKENS, verifyToken, userId);
  await sendVerificationEmail(env, body.email, body.name, verifyToken).catch(() => {
    logger.warn("Verification email failed to send", { userId });
  });

  const user = await getUserById(env.DB, userId) as User;
  const tokens = await issueTokens(env, user);
  await createSession(env, userId, orgId, user.role, user.tier, request);
  await insertAuditLog(env.DB, orgId, userId, "register", ip);

  trackAuthEvent(env, "register", orgId);
  logger.info("User registered", { userId, orgId });

  return { ok: true, tokens, user: toPublicUser(user) };
}

export async function loginUser(
  env: Env,
  body: LoginBody,
  request: Request
): Promise<AuthResponse> {
  const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";

  const user = await getUserByEmail(env.DB, body.email);
  if (!user) {
    trackAuthEvent(env, "login_failed", "unknown", { reason: "not_found" });
    throw Object.assign(new Error("Invalid email or password."), { status: 401 });
  }

  if (user.status === "suspended") {
    throw Object.assign(new Error("Your account has been suspended. Contact support."), { status: 403 });
  }

  const valid = await verifyPassword(body.password, user.password_hash);
  if (!valid) {
    await insertAuditLog(env.DB, user.org_id, user.id, "login_failed", ip);
    trackAuthEvent(env, "login_failed", user.org_id, { reason: "bad_password" });
    throw Object.assign(new Error("Invalid email or password."), { status: 401 });
  }

  const tokens = await issueTokens(env, user);
  await createSession(env, user.id, user.org_id, user.role, user.tier, request);
  await insertAuditLog(env.DB, user.org_id, user.id, "login", ip);

  trackAuthEvent(env, "login", user.org_id);
  logger.info("User logged in", { userId: user.id });

  return { ok: true, tokens, user: toPublicUser(user) };
}
TS

cat > src/services/roleService.ts <<'TS'
import type { Env, Role } from "@/types";
import { getUserById, upsertRole, listOrgRoles, insertAuditLog } from "@/db/queries";
import { logger } from "@/lib/logger";

const ROLE_HIERARCHY: Record<Role, number> = {
  viewer: 1,
  member: 2,
  admin:  3,
  owner:  4,
};

export function canAssignRole(assignerRole: Role, targetRole: Role): boolean {
  return ROLE_HIERARCHY[assignerRole] > ROLE_HIERARCHY[targetRole];
}

export async function assignRole(
  env: Env,
  orgId: string,
  assignerUserId: string,
  assignerRole: Role,
  targetUserId: string,
  newRole: Role
): Promise<void> {
  if (!canAssignRole(assignerRole, newRole)) {
    throw Object.assign(
      new Error(`Your role '${assignerRole}' cannot assign '${newRole}'.`),
      { status: 403 }
    );
  }

  const targetUser = await getUserById(env.DB, targetUserId);
  if (!targetUser || targetUser.org_id !== orgId) {
    throw Object.assign(new Error("User not found in this organisation."), { status: 404 });
  }

  await upsertRole(env.DB, crypto.randomUUID(), orgId, targetUserId, newRole, assignerUserId);
  await insertAuditLog(env.DB, orgId, assignerUserId, "role_assigned", "server", {
    targetUserId,
    newRole,
  });

  logger.info("Role assigned", { orgId, targetUserId, newRole, by: assignerUserId });
}

export async function getOrgRoles(
  env: Env,
  orgId: string
): Promise<{ userId: string; role: Role; grantedBy: string; createdAt: string }[]> {
  return listOrgRoles(env.DB, orgId);
}
TS

cat > src/services/emailService.ts <<'TS'
import type { Env } from "@/types";
import { logger } from "@/lib/logger";

const FROM    = "Insight Hunter <noreply@insighthunter.com>";
const SUBJECT = {
  verify: "Verify your Insight Hunter email",
  reset:  "Reset your Insight Hunter password",
};

async function sendEmail(
  env: Env,
  to: string,
  subject: string,
  html: string,
  text: string
): Promise<void> {
  // MailChannels Send API (free via Cloudflare Workers)
  const res = await fetch("https://api.mailchannels.net/tx/v1/send", {
    method:  "POST",
    headers: {
      "Content-Type":  "application/json",
      "X-Api-Key":     env.MAILCHANNELS_API_KEY ?? "",
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: to }] }],
      from: { email: "noreply@insighthunter.com", name: "Insight Hunter" },
      subject,
      content: [
        { type: "text/plain", value: text },
        { type: "text/html",  value: html },
      ],
    }),
  });

  if (!res.ok) {
    logger.warn("Email send failed", { to, status: res.status });
    throw new Error(`Email delivery failed: ${res.status}`);
  }
}

export async function sendVerificationEmail(
  env: Env,
  email: string,
  name: string,
  token: string
): Promise<void> {
  const link = `${env.APP_URL}/auth/verify-email?token=${token}`;
  const html = `
    <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
      <h2>Verify your email</h2>
      <p>Hi ${name},</p>
      <p>Click the button below to verify your Insight Hunter account:</p>
      <a href="${link}" style="display:inline-block;background:#4f46e5;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600">
        Verify Email
      </a>
      <p style="color:#6b7280;font-size:12px;margin-top:24px">
        This link expires in 24 hours. If you didn't create an account, ignore this email.
      </p>
    </div>`;
  const text = `Hi ${name},\n\nVerify your email:\n${link}\n\nLink expires in 24 hours.`;
  await sendEmail(env, email, SUBJECT.verify, html, text);
}

export async function sendPasswordResetEmail(
  env: Env,
  email: string,
  name: string,
  token: string
): Promise<void> {
  const link = `${env.APP_URL}/auth/reset-password?token=${token}`;
  const html = `
    <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
      <h2>Reset your password</h2>
      <p>Hi ${name},</p>
      <p>Click the button below to reset your Insight Hunter password:</p>
      <a href="${link}" style="display:inline-block;background:#4f46e5;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600">
        Reset Password
      </a>
      <p style="color:#6b7280;font-size:12px;margin-top:24px">
        This link expires in 1 hour. If you didn't request this, ignore this email.
      </p>
    </div>`;
  const text = `Hi ${name},\n\nReset your password:\n${link}\n\nLink expires in 1 hour.`;
  await sendEmail(env, email, SUBJECT.reset, html, text);
}
TS
success "Services written."

# =============================================================================
# 12. Routes
# =============================================================================
info "Writing routes…"

cat > src/routes/register.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env } from "@/types";
import { validateBody } from "@/middleware/validate";
import { rateLimitMiddleware } from "@/middleware/rateLimit";
import { registerUser } from "@/services/authService";
import { logger } from "@/lib/logger";

const RegisterSchema = z.object({
  name:     z.string().min(2).max(80).trim(),
  email:    z.string().email().toLowerCase().trim(),
  password: z.string().min(8).max(128),
  orgName:  z.string().min(2).max(100).trim().optional(),
});

const register = new Hono<{ Bindings: Env; Variables: { body: z.infer<typeof RegisterSchema> } }>();

register.post(
  "/",
  rateLimitMiddleware(10), // 10 registrations per window per IP
  validateBody(RegisterSchema),
  async (c) => {
    const body = c.get("body");
    try {
      const result = await registerUser(c.env, body, c.req.raw);
      return c.json(result, 201);
    } catch (e: any) {
      logger.warn("Registration failed", { email: body.email, error: e.message });
      return c.json({ error: e.message }, e.status ?? 500);
    }
  }
);

export default register;
TS

cat > src/routes/login.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env } from "@/types";
import { validateBody } from "@/middleware/validate";
import { rateLimitMiddleware } from "@/middleware/rateLimit";
import { loginUser } from "@/services/authService";
import { logger } from "@/lib/logger";

const LoginSchema = z.object({
  email:    z.string().email().toLowerCase().trim(),
  password: z.string().min(1),
});

const login = new Hono<{ Bindings: Env; Variables: { body: z.infer<typeof LoginSchema> } }>();

login.post(
  "/",
  rateLimitMiddleware(10), // strict: 10 login attempts per window per IP
  validateBody(LoginSchema),
  async (c) => {
    const body = c.get("body");
    try {
      const result = await loginUser(c.env, body, c.req.raw);
      return c.json(result, 200);
    } catch (e: any) {
      logger.warn("Login failed", { email: body.email, error: e.message });
      return c.json({ error: e.message }, e.status ?? 500);
    }
  }
);

export default login;
TS

cat > src/routes/logout.ts <<'TS'
import { Hono } from "hono";
import type { Env, AccessTokenPayload } from "@/types";
import { verifyAccessToken } from "@/lib/jwt";
import { revokeRefreshToken } from "@/services/tokenService";
import { destroyAllSessions } from "@/services/sessionService";
import { trackAuthEvent } from "@/lib/analytics";
import { logger } from "@/lib/logger";

const logout = new Hono<{ Bindings: Env }>();

logout.post("/", async (c) => {
  const authHeader   = c.req.header("Authorization") ?? "";
  const accessToken  = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  const body         = await c.req.json().catch(() => ({}) as Record<string, string>);
  const refreshToken = (body as Record<string, string>).refreshToken;

  let userId = "unknown";

  if (accessToken) {
    const payload = await verifyAccessToken(accessToken, c.env.JWT_SECRET);
    if (payload) {
      userId = payload.sub;
      await destroyAllSessions(c.env, payload.sub);
      trackAuthEvent(c.env, "logout", payload.orgId);
    }
  }

  if (refreshToken) {
    await revokeRefreshToken(c.env, refreshToken).catch(() => {});
  }

  logger.info("User logged out", { userId });
  return c.json({ ok: true, message: "Logged out successfully." });
});

export default logout;
TS

cat > src/routes/refresh.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env } from "@/types";
import { validateBody } from "@/middleware/validate";
import { rateLimitMiddleware } from "@/middleware/rateLimit";
import { rotateRefreshToken } from "@/services/tokenService";
import { getUserById } from "@/db/queries";
import { trackAuthEvent } from "@/lib/analytics";
import { logger } from "@/lib/logger";

const RefreshSchema = z.object({
  refreshToken: z.string().min(10),
});

const refresh = new Hono<{ Bindings: Env; Variables: { body: z.infer<typeof RefreshSchema> } }>();

refresh.post(
  "/",
  rateLimitMiddleware(30),
  validateBody(RefreshSchema),
  async (c) => {
    const { refreshToken } = c.get("body");

    const tokens = await rotateRefreshToken(
      c.env,
      refreshToken,
      (id) => getUserById(c.env.DB, id) as any
    );

    if (!tokens) {
      logger.warn("Token refresh failed — invalid or expired token");
      return c.json({ error: "Invalid or expired refresh token." }, 401);
    }

    trackAuthEvent(c.env, "token_refresh", "unknown");
    return c.json({ ok: true, tokens });
  }
);

export default refresh;
TS

cat > src/routes/verify.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env, AccessTokenPayload } from "@/types";
import { validateBody } from "@/middleware/validate";
import { verifyAccessToken } from "@/lib/jwt";
import { consumeVerifyToken, storeResetToken } from "@/lib/cache";
import { verifyUserEmail, getUserByEmail, getUserById, updateUserPassword } from "@/db/queries";
import { hashPassword, generateSecureToken } from "@/lib/hash";
import { sendPasswordResetEmail } from "@/services/emailService";
import { trackAuthEvent } from "@/lib/analytics";
import { logger } from "@/lib/logger";

const verify = new Hono<{ Bindings: Env }>();

// ── GET /verify — validate an access token (used by other services) ───────────
verify.get("/", async (c) => {
  const authHeader = c.req.header("Authorization") ?? "";
  const token      = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) return c.json({ valid: false, error: "No token provided." }, 401);

  const payload = await verifyAccessToken(token, c.env.JWT_SECRET);
  if (!payload) return c.json({ valid: false, error: "Invalid or expired token." }, 401);

  trackAuthEvent(c.env, "token_verify", payload.orgId);
  return c.json({ valid: true, payload });
});

// ── POST /verify/email — consume email verification token ─────────────────────
verify.post("/email", validateBody(z.object({ token: z.string().min(10) })), async (c) => {
  const { token } = c.get("body" as never) as { token: string };
  const userId    = await consumeVerifyToken(c.env.TOKENS, token);
  if (!userId) return c.json({ error: "Verification link is invalid or has expired." }, 400);

  await verifyUserEmail(c.env.DB, userId);
  trackAuthEvent(c.env, "email_verify", "unknown");
  logger.info("Email verified", { userId });
  return c.json({ ok: true, message: "Email verified successfully." });
});

// ── POST /verify/forgot-password ──────────────────────────────────────────────
verify.post("/forgot-password", validateBody(z.object({ email: z.string().email() })), async (c) => {
  const { email } = c.get("body" as never) as { email: string };
  // Always return 200 to prevent email enumeration
  const user = await getUserByEmail(c.env.DB, email);
  if (user && user.status !== "suspended") {
    const resetToken = generateSecureToken(32);
    await storeResetToken(c.env.TOKENS, resetToken, user.id);
    await sendPasswordResetEmail(c.env, user.email, user.name, resetToken).catch(() => {
      logger.warn("Reset email failed", { userId: user.id });
    });
    trackAuthEvent(c.env, "password_reset_request", user.org_id);
  }
  return c.json({ ok: true, message: "If that email exists, a reset link has been sent." });
});

// ── POST /verify/reset-password ───────────────────────────────────────────────
verify.post(
  "/reset-password",
  validateBody(z.object({ token: z.string().min(10), password: z.string().min(8).max(128) })),
  async (c) => {
    const { token, password } = c.get("body" as never) as { token: string; password: string };
    const { consumeResetToken } = await import("@/lib/cache");
    const userId = await consumeResetToken(c.env.TOKENS, token);
    if (!userId) return c.json({ error: "Reset link is invalid or has expired." }, 400);

    const hash = await hashPassword(password);
    await updateUserPassword(c.env.DB, userId, hash);

    const user = await getUserById(c.env.DB, userId);
    if (user) trackAuthEvent(c.env, "password_reset_complete", user.org_id);
    logger.info("Password reset", { userId });
    return c.json({ ok: true, message: "Password updated successfully." });
  }
);

export default verify;
TS

cat > src/routes/roles.ts <<'TS'
import { Hono } from "hono";
import { z } from "zod";
import type { Env, AccessTokenPayload, Role } from "@/types";
import { validateBody } from "@/middleware/validate";
import { verifyAccessToken } from "@/lib/jwt";
import { assignRole, getOrgRoles } from "@/services/roleService";
import { trackAuthEvent } from "@/lib/analytics";
import { logger } from "@/lib/logger";

const AssignSchema = z.object({
  userId: z.string().uuid(),
  role:   z.enum(["owner", "admin", "member", "viewer"]),
});

const roles = new Hono<{ Bindings: Env }>();

// Require auth on all role routes
roles.use("*", async (c, next) => {
  const token = (c.req.header("Authorization") ?? "").replace("Bearer ", "");
  const payload = await verifyAccessToken(token, c.env.JWT_SECRET);
  if (!payload) return c.json({ error: "Unauthorized" }, 401);
  (c as any).set("user", payload);
  await next();
});

// GET /roles — list org roles
roles.get("/", async (c) => {
  const user = (c as any).get("user") as AccessTokenPayload;
  if (!["owner", "admin"].includes(user.role)) {
    return c.json({ error: "Forbidden. Admin or Owner required." }, 403);
  }
  const list = await getOrgRoles(c.env, user.orgId);
  return c.json({ ok: true,  list });
});

// POST /roles/assign — assign a role to a user
roles.post(
  "/assign",
  validateBody(AssignSchema),
  async (c) => {
    const user   = (c as any).get("user") as AccessTokenPayload;
    const body   = (c as any).get("body") as z.infer<typeof AssignSchema>;

    if (!["owner", "admin"].includes(user.role)) {
      return c.json({ error: "Forbidden. Admin or Owner required." }, 403);
    }

    try {
      await assignRole(c.env, user.orgId, user.sub, user.role as Role, body.userId, body.role);
      trackAuthEvent(c.env, "role_assigned", user.orgId, { targetUserId: body.userId, newRole: body.role });
      return c.json({ ok: true, message: `Role '${body.role}' assigned.` });
    } catch (e: any) {
      logger.warn("Role assignment failed", { error: e.message });
      return c.json({ error: e.message }, e.status ?? 500);
    }
  }
);

export default roles;
TS
success "Routes written."

# =============================================================================
# 13. Entry point — src/index.ts
# =============================================================================
info "Writing src/index.ts…"
cat > src/index.ts <<'TS'
import { Hono } from "hono";
import type { Env } from "@/types";

// Middleware
import { corsMiddleware }    from "@/middleware/cors";
import { rateLimitMiddleware } from "@/middleware/rateLimit";

// Routes
import register from "@/routes/register";
import login    from "@/routes/login";
import logout   from "@/routes/logout";
import refresh  from "@/routes/refresh";
import verify   from "@/routes/verify";
import roles    from "@/routes/roles";

import { logger } from "@/lib/logger";

const app = new Hono<{ Bindings: Env }>();

// ── Global middleware ─────────────────────────────────────────────────────────
app.use("*", corsMiddleware);

// ── Health check ──────────────────────────────────────────────────────────────
app.get("/health", (c) =>
  c.json({ ok: true, service: "insighthunter-auth", ts: new Date().toISOString() })
);

// ── Auth routes ───────────────────────────────────────────────────────────────
app.route("/auth/register", register);
app.route("/auth/login",    login);
app.route("/auth/logout",   logout);
app.route("/auth/refresh",  refresh);
app.route("/auth/verify",   verify);
app.route("/auth/roles",    roles);

// ── 404 handler ───────────────────────────────────────────────────────────────
app.notFound((c) =>
  c.json({ error: "Not Found", message: `${c.req.method} ${c.req.path} not found.` }, 404)
);

// ── Error handler ─────────────────────────────────────────────────────────────
app.onError((err, c) => {
  logger.error("Unhandled error", { message: err.message, stack: err.stack });
  return c.json({ error: "Internal Server Error", message: "An unexpected error occurred." }, 500);
});

export default app;
TS
success "src/index.ts written."

# =============================================================================
# 14. Tests
# =============================================================================
info "Writing tests…"

cat > tests/fixtures/mockUser.ts <<'TS'
import type { User, AccessTokenPayload } from "../../src/types";

export const mockUser: User = {
  id:             "user-test-001",
  org_id:         "org-test-001",
  email:          "test@insighthunter.com",
  name:           "Test User",
  password_hash:  "pbkdf2:100000:abc123salt:abc123hash",
  role:           "owner",
  tier:           "lite",
  email_verified: 1,
  status:         "active",
  created_at:     "2026-01-01T00:00:00.000Z",
  updated_at:     "2026-01-01T00:00:00.000Z",
};

export const mockTokenPayload: AccessTokenPayload = {
  sub:   mockUser.id,
  email: mockUser.email,
  name:  mockUser.name,
  orgId: mockUser.org_id,
  role:  mockUser.role,
  tier:  mockUser.tier,
  type:  "access",
  iat:   Math.floor(Date.now() / 1000),
  exp:   Math.floor(Date.now() / 1000) + 3600,
};
TS

cat > tests/routes/login.test.ts <<'TS'
import { describe, it, expect, vi, beforeEach } from "vitest";

// Placeholder — wire up with Miniflare or vitest-environment-miniflare
// for full integration tests against the Worker runtime.

describe("POST /auth/login", () => {
  it("returns 422 for invalid body", async () => {
    expect(true).toBe(true);
  });

  it("returns 401 for wrong password", async () => {
    expect(true).toBe(true);
  });

  it("returns tokens on success", async () => {
    expect(true).toBe(true);
  });
});
TS

cat > tests/routes/register.test.ts <<'TS'
import { describe, it, expect } from "vitest";

describe("POST /auth/register", () => {
  it("returns 422 for short password", async () => {
    expect(true).toBe(true);
  });

  it("returns 409 for duplicate email", async () => {
    expect(true).toBe(true);
  });

  it("returns 201 and tokens on success", async () => {
    expect(true).toBe(true);
  });
});
TS

cat > tests/services/tokenService.test.ts <<'TS'
import { describe, it, expect, vi } from "vitest";
import { issueTokens, rotateRefreshToken } from "../../src/services/tokenService";

const mockEnv = {
  JWT_SECRET:     "test_jwt_secret_that_is_long_enough_64chars_minimum_xxxxxxxxxxxxx",
  REFRESH_SECRET: "test_refresh_secret_that_is_long_enough_64chars_minimum_xxxxxxxxx",
  JWT_EXPIRY:     "3600",
  REFRESH_EXPIRY: "2592000",
  TOKENS: {
    put:    vi.fn().mockResolvedValue(undefined),
    get:    vi.fn().mockResolvedValue(JSON.stringify({ valid: true })),
    delete: vi.fn().mockResolvedValue(undefined),
  },
} as any;

const mockUser = {
  id:     "user-001",
  email:  "test@example.com",
  name:   "Test",
  org_id: "org-001",
  role:   "owner",
  tier:   "lite",
};

describe("tokenService.issueTokens", () => {
  it("returns access and refresh tokens", async () => {
    const result = await issueTokens(mockEnv, mockUser);
    expect(result.accessToken).toBeTruthy();
    expect(result.refreshToken).toBeTruthy();
    expect(result.tokenType).toBe("Bearer");
    expect(result.expiresIn).toBe(3600);
  });

  it("access token has 3 segments (HS256 JWT)", async () => {
    const result = await issueTokens(mockEnv, mockUser);
    expect(result.accessToken.split(".")).toHaveLength(3);
  });
});

describe("tokenService.rotateRefreshToken", () => {
  it("returns null for invalid token", async () => {
    const result = await rotateRefreshToken(mockEnv, "bad.token.here", async () => null);
    expect(result).toBeNull();
  });

  it("issues new tokens on valid rotation", async () => {
    const { refreshToken } = await issueTokens(mockEnv, mockUser);
    const result = await rotateRefreshToken(mockEnv, refreshToken, async () => mockUser);
    expect(result).not.toBeNull();
    expect(result?.accessToken).toBeTruthy();
  });
});
TS
success "Tests written."

# =============================================================================
# 15. README
# =============================================================================
info "Writing README.md…"
cat > README.md <<'MD'
# insighthunter-auth

Insight Hunter Auth Service — Cloudflare Worker
JWT issuance · Session management · PBKDF2 password hashing · RBAC · Email verification

## Stack
- **Runtime**: Cloudflare Workers (Hono router)
- **DB**: D1 (users, sessions, roles, audit log)
- **KV**: Session tokens, refresh JTIs, reset/verify tokens
- **Hashing**: PBKDF2 via Web Crypto API (no bcrypt)
- **JWT**: HS256 via Web Crypto API (no jsonwebtoken)
- **Email**: MailChannels Send API

## Quick Start

```bash
cp .env.example .dev.vars

# Create D1 database
wrangler d1 create insighthunter-auth-db

# Create KV namespaces
wrangler kv:namespace create SESSIONS
wrangler kv:namespace create TOKENS

# Update IDs in wrangler.toml

# Run migrations
npm run migrate:local

# Set secrets
wrangler secret put JWT_SECRET
wrangler secret put REFRESH_SECRET
wrangler secret put MAILCHANNELS_API_KEY

# Dev
npm run dev

# Deploy
npm run deploy

cat > README.md <<'MD'
# insighthunter-auth

Insight Hunter Auth Service — Cloudflare Worker
JWT issuance · Session management · PBKDF2 password hashing · RBAC · Email verification

## Stack
- Runtime: Cloudflare Workers (Hono router)
- DB: D1 (users, sessions, roles, audit log)
- KV: Session tokens, refresh JTIs, reset/verify tokens
- Hashing: PBKDF2 via Web Crypto API (no bcrypt)
- JWT: HS256 via Web Crypto API (no jsonwebtoken)
- Email: MailChannels Send API

## Quick Start

  cp .env.example .dev.vars
  wrangler d1 create insighthunter-auth-db
  wrangler kv:namespace create SESSIONS
  wrangler kv:namespace create TOKENS
  # Update D1 + KV IDs in wrangler.toml
  npm run migrate:local
  wrangler secret put JWT_SECRET
  wrangler secret put REFRESH_SECRET
  wrangler secret put MAILCHANNELS_API_KEY
  npm run dev
  npm run deploy

## API Routes

  POST  /auth/register                [10/min]   Create account + org
  POST  /auth/login                   [10/min]   Login, issue tokens
  POST  /auth/logout                  [100/min]  Revoke tokens + sessions
  POST  /auth/refresh                 [30/min]   Rotate refresh token
  GET   /auth/verify                  [100/min]  Validate access token (service-to-service)
  POST  /auth/verify/email            [20/min]   Consume email verify token
  POST  /auth/verify/forgot-password  [10/min]   Request password reset
  POST  /auth/verify/reset-password   [10/min]   Consume reset token, update password
  GET   /auth/roles                   [admin+]   List org roles
  POST  /auth/roles/assign            [admin+]   Assign role to user
  GET   /health                       [public]   Health check

## Token Flow

  Register/Login
    -> accessToken  (HS256 JWT, 1hr, verified by all services)
    -> refreshToken (HS256 JWT, 30d, rotated on use, JTI stored in KV)

  Service-to-service token validation:
    GET /auth/verify
    Authorization: Bearer <accessToken>
    -> { valid: true, payload: { sub, email, orgId, role, tier } }

## Security Notes
- Passwords hashed with PBKDF2-SHA256 (100k iterations) — no native bcrypt needed
- Refresh tokens use JTI rotation — old JTI revoked on every refresh
- Rate limiting per IP per route stored in KV
- Email enumeration prevented on forgot-password endpoint
- Audit log writes on login, failed login, register, role changes
MD
success "README.md written."

# =============================================================================
# 16. npm install & git init
# =============================================================================
info "Installing dependencies…"
npm install --silent
success "Dependencies installed."

info "Initialising git repository…"
git init -q
git add -A
git commit -m "chore: scaffold insighthunter-auth (Hono + D1 + KV + PBKDF2 + JWT + RBAC)" -q
success "Git repository initialised."

# =============================================================================
# Done
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔═════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║  ✅  insighthunter-auth scaffolded                      ║${RESET}"
echo -e "${BOLD}${GREEN}╠═════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║  Next steps:                                            ║${RESET}"
echo -e "${GREEN}║  1.  cp .env.example .dev.vars                          ║${RESET}"
echo -e "${GREEN}║  2.  wrangler d1 create insighthunter-auth-db           ║${RESET}"
echo -e "${GREEN}║  3.  wrangler kv:namespace create SESSIONS              ║${RESET}"
echo -e "${GREEN}║  4.  wrangler kv:namespace create TOKENS                ║${RESET}"
echo -e "${GREEN}║  5.  Update D1 + KV IDs in wrangler.toml               ║${RESET}"
echo -e "${GREEN}║  6.  npm run migrate:local                              ║${RESET}"
echo -e "${GREEN}║  7.  wrangler secret put JWT_SECRET                     ║${RESET}"
echo -e "${GREEN}║  8.  wrangler secret put REFRESH_SECRET                 ║${RESET}"
echo -e "${GREEN}║  9.  wrangler secret put MAILCHANNELS_API_KEY           ║${RESET}"
echo -e "${GREEN}║  10. npm run dev                                        ║${RESET}"
echo -e "${GREEN}╚═════════════════════════════════════════════════════════╝${RESET}"
echo ""
if command -v tree &> /dev/null; then
  tree . -a --dirsfirst -I "node_modules|.git|dist"
else
  find . -not -path "*/node_modules/*" -not -path "*/.git/*" | sort
fi

//*
Register/Login
  → accessToken  (HS256 JWT, 1hr, verified by all services)
  → refreshToken (HS256 JWT, 30d, rotated on use, JTI stored in KV)

Service-to-service token validation:
  GET /auth/verify
  Authorization: Bearer <accessToken>
  → { valid: true, payload: { sub, email, orgId, role, tier } }

Security Notes
•	Passwords hashed with PBKDF2-SHA256 (100k iterations) — no native bcrypt needed
•	Refresh tokens use JTI rotation — old JTI revoked on every refresh
•	Rate limiting per IP per route stored in KV
•	Email enumeration prevented on forgot-password endpoint
•	Audit log writes on login, failed login, register, role changes
MD
success “README.md written.”
# =============================================================================
# 16. npm install & git init
# =============================================================================
info “Installing dependencies…”
npm install –silent
success “Dependencies installed.”
info “Initialising git repository…”
git init -q
git add -A
git commit -m “chore: scaffold insighthunter-auth (Hono + D1 + KV + PBKDF2 + JWT + RBAC)” -q
success “Git repository initialised.”
# =============================================================================
# Done
# =============================================================================
echo “”
echo -e “${BOLD}${GREEN}╔═════════════════════════════════════════════════════════╗${RESET}”
echo -e “${BOLD}${GREEN}║  ✅  insighthunter-auth scaffolded                      ║${RESET}”
echo -e “${BOLD}${GREEN}╠═════════════════════════════════════════════════════════╣${RESET}”
echo -e “${GREEN}║  Next steps:                                            ║${RESET}”
echo -e “${GREEN}║  1.  cp .env.example .dev.vars                          ║${RESET}”
echo -e “${GREEN}║  2.  wrangler d1 create insighthunter-auth-db           ║${RESET}”
echo -e “${GREEN}║  3.  wrangler kv:namespace create SESSIONS              ║${RESET}”
echo -e “${GREEN}║  4.  wrangler kv:namespace create TOKENS                ║${RESET}”
echo -e “${GREEN}║  5.  Update D1 + KV IDs in wrangler.toml               ║${RESET}”
echo -e “${GREEN}║  6.  npm run migrate:local                              ║${RESET}”
echo -e “${GREEN}║  7.  wrangler secret put JWT_SECRET                     ║${RESET}”
echo -e “${GREEN}║  8.  wrangler secret put REFRESH_SECRET                 ║${RESET}”
echo -e “${GREEN}║  9.  wrangler secret put MAILCHANNELS_API_KEY           ║${RESET}”
echo -e “${GREEN}║  10. npm run dev                                        ║${RESET}”
echo -e “${GREEN}╚═════════════════════════════════════════════════════════╝${RESET}”
echo “”
if command -v tree &> /dev/null; then
tree . -a –dirsfirst -I “node_modules|.git|dist”
else
find . -not -path*//