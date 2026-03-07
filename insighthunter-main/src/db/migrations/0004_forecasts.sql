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
