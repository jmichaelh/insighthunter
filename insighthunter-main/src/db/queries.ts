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
