-- apps/insighthunter-platform/schema.sql
-- Platform-level D1 schema — tracks all tenant provisioning state.
-- This is NOT a per-tenant database. One shared platform DB tracks all tenants.

CREATE TABLE IF NOT EXISTS tenants (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL UNIQUE,
  user_id TEXT NOT NULL,
  email TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  tier TEXT NOT NULL DEFAULT 'free',

  -- Cloudflare resource identifiers
  worker_name TEXT NOT NULL DEFAULT '',
  d1_database_id TEXT NOT NULL DEFAULT '',
  d1_database_name TEXT NOT NULL DEFAULT '',
  kv_namespace_id TEXT NOT NULL DEFAULT '',
  kv_namespace_name TEXT NOT NULL DEFAULT '',
  r2_bucket_name TEXT NOT NULL DEFAULT '',
  custom_domain TEXT NOT NULL DEFAULT '',
  dns_record_id TEXT NOT NULL DEFAULT '',

  -- Lifecycle
  status TEXT NOT NULL DEFAULT 'provisioning',
  -- status: provisioning | active | suspended | deprovisioning | deleted

  provisioned_at TEXT,
  suspended_at TEXT,
  deleted_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_tenants_org_id ON tenants(org_id);
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON tenants(slug);
CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);
CREATE INDEX IF NOT EXISTS idx_tenants_user_id ON tenants(user_id);

-- Provisioning audit log — records each step for debugging failures
CREATE TABLE IF NOT EXISTS provision_audit (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL,
  step TEXT NOT NULL,         -- d1_created | kv_created | r2_created | worker_uploaded | dns_created | completed | failed | rolled_back
  status TEXT NOT NULL,       -- success | failure
  detail TEXT,                -- Resource ID or error message
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_audit_org ON provision_audit(org_id, created_at);
