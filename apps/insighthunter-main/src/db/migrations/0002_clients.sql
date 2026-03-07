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
