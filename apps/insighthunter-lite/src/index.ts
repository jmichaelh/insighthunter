// workers/insight-lite-api/index.ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { bearerAuth } from 'hono/bearer-auth';

export interface Env {
  DB: D1Database;
  SESSIONS: KVNamespace;
  REPORT_BUCKET: R2Bucket;
  ANALYTICS: AnalyticsEngineDataset;
  ALLOWED_ORIGIN: string;
  INTERNAL_API_SECRET: string;
}

interface PLRow {
  category: string;
  type: 'income' | 'expense';
  total: number;
  month: string;
}

interface SessionData {
  userId: string;
  orgId: string;
  tier: 'lite' | 'standard' | 'pro';
}

const app = new Hono<{ Bindings: Env }>();

// CORS — explicit origin only
app.use('*', async (c, next) => {
  return cors({
    origin: c.env.ALLOWED_ORIGIN,
    allowMethods: ['GET', 'POST', 'OPTIONS'],
    allowHeaders: ['Authorization', 'Content-Type'],
  })(c, next);
});

// Session resolution middleware
app.use('*', async (c, next) => {
  const token = c.req.header('Authorization')?.slice(7);
  if (!token) return c.json({ error: 'Unauthorized' }, 401);

  const raw = await c.env.SESSIONS.get(token);
  if (!raw) return c.json({ error: 'Invalid or expired session' }, 401);

  const session = JSON.parse(raw) as SessionData;

  // Hard gate: Lite API only serves lite tier (standard/pro use their own workers)
  if (session.tier !== 'lite') {
    return c.json({ error: 'Use the Standard or Pro API endpoint for your tier' }, 403);
  }

  c.set('session' as never, session);
  return next();
});

// ── GET /api/lite/report/pl ──────────────────────────────────────────────────
// Returns a basic P&L summary (current month + prior 2 months) from D1
app.get('/api/lite/report/pl', async (c) => {
  const session = c.get('session' as never) as SessionData;

  const { results } = await c.env.DB.prepare(
    `SELECT category, type, SUM(amount) AS total,
            strftime('%Y-%m', date) AS month
     FROM transactions
     WHERE org_id = ?
       AND date >= date('now', '-3 months')
     GROUP BY category, type, month
     ORDER BY month DESC, type, category`
  )
    .bind(session.orgId)
    .all<PLRow>();

  // Aggregate totals per month
  const summary: Record<string, { income: number; expenses: number; net: number }> = {};
  for (const row of results) {
    if (!summary[row.month]) summary[row.month] = { income: 0, expenses: 0, net: 0 };
    if (row.type === 'income') summary[row.month].income += row.total;
    if (row.type === 'expense') summary[row.month].expenses += row.total;
    summary[row.month].net = summary[row.month].income - summary[row.month].expenses;
  }

  // Track Analytics Engine event (non-blocking)
  c.env.ANALYTICS.writeDataPoint({
    blobs: ['lite_report_viewed', session.orgId, 'pl'],
    doubles: [1],
    indexes: [session.userId],
  });

  return c.json({ ok: true, summary, rows: results });
});

// ── GET /api/lite/report/kpis ────────────────────────────────────────────────
// Returns top 3 KPIs only (Lite tier cap)
app.get('/api/lite/report/kpis', async (c) => {
  const session = c.get('session' as never) as SessionData;
  const LITE_KPI_LIMIT = 3;

  const { results } = await c.env.DB.prepare(
    `SELECT kpi_key, kpi_label, value, unit, trend
     FROM kpis
     WHERE org_id = ?
     ORDER BY display_order ASC
     LIMIT ?`
  )
    .bind(session.orgId, LITE_KPI_LIMIT)
    .all();

  c.env.ANALYTICS.writeDataPoint({
    blobs: ['lite_report_viewed', session.orgId, 'kpis'],
    doubles: [1],
    indexes: [session.userId],
  });

  return c.json({ ok: true, kpis: results, tier_cap: LITE_KPI_LIMIT });
});

// ── POST /api/lite/transactions/upload ───────────────────────────────────────
// CSV upload — manual bookkeeping entry, stores to D1
app.post('/api/lite/transactions/upload', async (c) => {
  const session = c.get('session' as never) as SessionData;
  const body = await c.req.json<{ rows: Array<{ date: string; description: string; amount: number; type: 'income' | 'expense'; category: string }> }>();

  if (!Array.isArray(body.rows) || body.rows.length === 0) {
    return c.json({ error: 'No rows provided' }, 400);
  }

  // Batch insert — D1 supports up to 100 statements per batch
  const BATCH_SIZE = 100;
  const chunks: typeof body.rows[] = [];
  for (let i = 0; i < body.rows.length; i += BATCH_SIZE) {
    chunks.push(body.rows.slice(i, i + BATCH_SIZE));
  }

  for (const chunk of chunks) {
    const stmts = chunk.map((row) =>
      c.env.DB.prepare(
        `INSERT INTO transactions (org_id, date, description, amount, type, category, source)
         VALUES (?, ?, ?, ?, ?, ?, 'csv')
         ON CONFLICT DO NOTHING`
      ).bind(session.orgId, row.date, row.description, row.amount, row.type, row.category)
    );
    await c.env.DB.batch(stmts);
  }

  c.env.ANALYTICS.writeDataPoint({
    blobs: ['lite_csv_uploaded', session.orgId],
    doubles: [body.rows.length],
    indexes: [session.userId],
  });

  return c.json({ ok: true, inserted: body.rows.length });
});

// ── POST /api/lite/paywall-hit ───────────────────────────────────────────────
// Called by frontend when a locked feature is clicked; fires analytics event
app.post('/api/lite/paywall-hit', async (c) => {
  const session = c.get('session' as never) as SessionData;
  const { feature } = await c.req.json<{ feature: string }>();

  c.env.ANALYTICS.writeDataPoint({
    blobs: ['lite_user_hit_paywall', session.orgId, feature ?? 'unknown'],
    doubles: [1],
    indexes: [session.userId],
  });

  return c.json({ ok: true });
});

// Health check (no auth required)
app.get('/health', (c) => c.json({ ok: true, service: 'insight-lite-api', ts: Date.now() }));

export default app;
