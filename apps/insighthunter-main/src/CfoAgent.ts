import { Agent } from "agents";
import type { Connection } from "agents";

// ─── Env ──────────────────────────────────────────────────────
export interface Env {
  CFO_AGENT:    DurableObjectNamespace;
  AI:           Ai;
  DB:           D1Database;
  REPORT_QUEUE: Queue;
  AI_JOB_QUEUE: Queue;
  VECTORS:      VectorizeIndex;
  ANALYTICS:    AnalyticsEngineDataset;
  REPORTS:      R2Bucket;
  UPLOADS:      R2Bucket;
  SESSIONS:     KVNamespace;
  CONFIG:       KVNamespace;
}

// ─── State (synced to frontend via this.setState) ─────────────
interface CfoState {
  userId:          string;
  email:           string;
  plan:            "free" | "pro" | "white-label";
  lastForecastAt:  string | null;
  lastReportAt:    string | null;
  alerts:          Alert[];
  kpis:            KpiSnapshot | null;
  onboarded:       boolean;
  reportsUsed:     number;
  reportsLimit:    number;
}

interface Alert {
  id:        string;
  type:      "cash_flow" | "overdue_invoice" | "expense_spike" | "forecast";
  message:   string;
  severity:  "info" | "warning" | "critical";
  createdAt: string;
  read:      boolean;
}

interface KpiSnapshot {
  revenue:      number;
  expenses:     number;
  netIncome:    number;
  transactions: number;
  periodDays:   number;
  updatedAt:    string;
}

interface Transaction {
  id:          string;
  date:        string;
  description: string;
  amount:      number;
  category:    string;
  type:        "revenue" | "expense";
}

// ─── Agent ────────────────────────────────────────────────────
export class CfoAgent extends Agent<Env, CfoState> {

  // ── Default State ─────────────────────────────────────────
  initialState: CfoState = {
    userId:         "",
    email:          "",
    plan:           "free",
    lastForecastAt: null,
    lastReportAt:   null,
    alerts:         [],
    kpis:           null,
    onboarded:      false,
    reportsUsed:    0,
    reportsLimit:   3, // free tier default
  };

  // ═══════════════════════════════════════════════════════════
  // HTTP ROUTING
  // ═══════════════════════════════════════════════════════════
  async onRequest(request: Request): Promise<Response> {
    const { pathname } = new URL(request.url);
    const method = request.method;

    try {
      // ── User & Onboarding ──────────────────────────────
      if (method === "POST"   && pathname === "/init")             return this.initUser(request);
      if (method === "GET"    && pathname === "/state")            return Response.json(this.state);
      if (method === "PATCH"  && pathname === "/state")            return this.patchState(request);

      // ── KPIs & Transactions ────────────────────────────
      if (method === "GET"    && pathname === "/kpis")             return this.getKpis();
      if (method === "GET"    && pathname === "/transactions")     return this.getTransactions(request);
      if (method === "POST"   && pathname === "/transactions")     return this.addTransaction(request);
      if (method === "DELETE" && pathname.startsWith("/transactions/")) return this.deleteTransaction(pathname);

      // ── CSV Upload & Ingestion ─────────────────────────
      if (method === "POST"   && pathname === "/upload")           return this.handleUpload(request);

      // ── AI Forecast ────────────────────────────────────
      if (method === "POST"   && pathname === "/forecast")         return this.runForecast();
      if (method === "GET"    && pathname === "/forecast/history") return this.getForecastHistory();

      // ── Reports ────────────────────────────────────────
      if (method === "POST"   && pathname === "/report")           return this.queueReport(request);
      if (method === "GET"    && pathname === "/reports")          return this.listReports();

      // ── Alerts ─────────────────────────────────────────
      if (method === "GET"    && pathname === "/alerts")           return this.getAlerts();
      if (method === "PATCH"  && pathname.startsWith("/alerts/"))  return this.markAlertRead(pathname);
      if (method === "DELETE" && pathname.startsWith("/alerts/"))  return this.deleteAlert(pathname);

      // ── Semantic Search ────────────────────────────────
      if (method === "POST"   && pathname === "/search")           return this.handleSearch(request);

      // ── Plan & Billing ─────────────────────────────────
      if (method === "GET"    && pathname === "/plan")             return this.getPlan();
      if (method === "POST"   && pathname === "/plan/upgrade")     return this.upgradePlan(request);

      // ── Cash Flow Analysis ─────────────────────────────
      if (method === "GET"    && pathname === "/cashflow")         return this.getCashFlow(request);
      if (method === "GET"    && pathname === "/pnl")              return this.getPnL(request);

      return Response.json({ error: "Not found" }, { status: 404 });

    } catch (err) {
      console.error(`[CfoAgent] Error on ${method} ${pathname}:`, err);
      return Response.json(
        { error: err instanceof Error ? err.message : "Internal error" },
        { status: 500 }
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // WEBSOCKET — Real-time Dashboard
  // ═══════════════════════════════════════════════════════════
  async onConnect(connection: Connection) {
    connection.accept();
    // Send current state immediately on connect
    connection.send(JSON.stringify({
      type:  "init",
      state: this.state,
    }));
  }

  async onMessage(connection: Connection, raw: string) {
    const { type, payload } = JSON.parse(raw);

    switch (type) {
      case "ping":
        connection.send(JSON.stringify({ type: "pong" }));
        break;

      case "get_kpis": {
        const res  = await this.getKpis();
        const data = await res.json();
        connection.send(JSON.stringify({ type: "kpis", ...data }));
        break;
      }

      case "get_alerts": {
        connection.send(JSON.stringify({
          type:   "alerts",
          alerts: this.state.alerts,
        }));
        break;
      }

      case "run_forecast": {
        connection.send(JSON.stringify({ type: "forecast_started" }));
        const res  = await this.runForecast();
        const data = await res.json();
        connection.send(JSON.stringify({ type: "forecast_done", ...data }));
        break;
      }

      default:
        connection.send(JSON.stringify({ type: "error", message: "Unknown message type" }));
    }
  }

  async onClose(connection: Connection) {
    console.log(`[CfoAgent] WebSocket closed for user: ${this.state.userId}`);
  }

  // ═══════════════════════════════════════════════════════════
  // SCHEDULED TASKS
  // ═══════════════════════════════════════════════════════════
  async onStart() {
    // Schedule daily digest on first agent start
    await this.schedule("0 8 * * *", "dailyDigest", {});
    // Schedule weekly alert check
    await this.schedule("0 9 * * 1", "weeklyAlertScan", {});
  }

  async dailyDigest(_ unknown) {
    if (!this.state.userId) return;
    await this.refreshKpis();
    await this.runForecast();
    await this.checkAlerts();
    this.trackEvent("daily_digest_run", 1);
  }

  async weeklyAlertScan(_ unknown) {
    if (!this.state.userId) return;
    await this.checkAlerts();
    this.trackEvent("weekly_alert_scan", 1);
  }

  // ═══════════════════════════════════════════════════════════
  // USER & ONBOARDING
  // ═══════════════════════════════════════════════════════════
  private async initUser(request: Request): Promise<Response> {
    const { userId, email, plan } = await request.json<{
      userId: string;
      email:  string;
      plan:   CfoState["plan"];
    }>();

    // Initialize SQLite schema on first run
    await this.sql`
      CREATE TABLE IF NOT EXISTS transactions (
        id          TEXT PRIMARY KEY,
        date        TEXT NOT NULL,
        description TEXT NOT NULL,
        amount      REAL NOT NULL,
        category    TEXT DEFAULT 'uncategorized',
        type        TEXT CHECK(type IN ('revenue','expense')) NOT NULL,
        source      TEXT DEFAULT 'manual',
        created_at  TEXT DEFAULT (datetime('now'))
      )
    `;

    await this.sql`
      CREATE TABLE IF NOT EXISTS forecasts (
        id         TEXT PRIMARY KEY,
        content    TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      )
    `;

    await this.sql`
      CREATE TABLE IF NOT EXISTS reports (
        id         TEXT PRIMARY KEY,
        type       TEXT NOT NULL,
        r2_key     TEXT NOT NULL,
        status     TEXT DEFAULT 'pending',
        created_at TEXT DEFAULT (datetime('now'))
      )
    `;

    const reportsLimit = plan === "free" ? 3 : plan === "pro" ? 50 : 999;

    this.setState({
      ...this.state,
      userId,
      email,
      plan,
      onboarded:    true,
      reportsLimit,
    });

    this.trackEvent("user_init", 1);
    return Response.json({ ok: true, state: this.state });
  }

  private async patchState(request: Request): Promise<Response> {
    const patch = await request.json<Partial<CfoState>>();
    // Prevent overwriting protected fields
    const { userId, email, ...safe } = patch;
    this.setState({ ...this.state, ...safe });
    return Response.json({ ok: true });
  }

  // ═══════════════════════════════════════════════════════════
  // KPIs
  // ═══════════════════════════════════════════════════════════
  private async getKpis(): Promise<Response> {
    const rows = await this.sql`
      SELECT
        COALESCE(SUM(CASE WHEN type = 'revenue' THEN amount ELSE 0 END), 0) AS revenue,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expenses,
        COUNT(*) AS transactions
      FROM transactions
      WHERE date >= date('now', '-30 days')
    `;

    const row = [...rows][0] as any ?? { revenue: 0, expenses: 0, transactions: 0 };
    const kpis: KpiSnapshot = {
      revenue:      row.revenue,
      expenses:     row.expenses,
      netIncome:    row.revenue - row.expenses,
      transactions: row.transactions,
      periodDays:   30,
      updatedAt:    new Date().toISOString(),
    };

    this.setState({ ...this.state, kpis });
    return Response.json({ kpis });
  }

  private async refreshKpis() {
    await this.getKpis();
  }

  // ═══════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ═══════════════════════════════════════════════════════════
  private async getTransactions(request: Request): Promise<Response> {
    const url      = new URL(request.url);
    const limit    = parseInt(url.searchParams.get("limit")  ?? "50");
    const offset   = parseInt(url.searchParams.get("offset") ?? "0");
    const type     = url.searchParams.get("type");
    const category = url.searchParams.get("category");
    const from     = url.searchParams.get("from");
    const to       = url.searchParams.get("to");

    // Build dynamic query with optional filters
    const rows = type
      ? await this.sql`
          SELECT * FROM transactions
          WHERE type = ${type}
          ORDER BY date DESC LIMIT ${limit} OFFSET ${offset}`
      : category
      ? await this.sql`
          SELECT * FROM transactions
          WHERE category = ${category}
          ORDER BY date DESC LIMIT ${limit} OFFSET ${offset}`
      : from && to
      ? await this.sql`
          SELECT * FROM transactions
          WHERE date BETWEEN ${from} AND ${to}
          ORDER BY date DESC LIMIT ${limit} OFFSET ${offset}`
      : await this.sql`
          SELECT * FROM transactions
          ORDER BY date DESC LIMIT ${limit} OFFSET ${offset}`;

    return Response.json({ transactions: [...rows] });
  }

  private async addTransaction(request: Request): Promise<Response> {
    const txn = await request.json<Omit<Transaction, "id"> & { id?: string }>();
    const id  = txn.id ?? crypto.randomUUID();

    await this.sql`
      INSERT INTO transactions (id, date, description, amount, category, type)
      VALUES (${id}, ${txn.date}, ${txn.description}, ${txn.amount}, ${txn.category ?? "uncategorized"}, ${txn.type})
    `;

    // Auto-embed for semantic search
    await this.embedTransaction({ ...txn, id });

    this.trackEvent("transaction_added", txn.amount);
    return Response.json({ ok: true, id });
  }

  private async deleteTransaction(pathname: string): Promise<Response> {
    const id = pathname.split("/").pop()!;
    await this.sql`DELETE FROM transactions WHERE id = ${id}`;
    await this.env.VECTORS.deleteByIds([id]);
    return Response.json({ ok: true });
  }

  // ═══════════════════════════════════════════════════════════
  // CSV UPLOAD & INGESTION
  // ═══════════════════════════════════════════════════════════
  private async handleUpload(request: Request): Promise<Response> {
    const formData   = await request.formData();
    const file       = formData.get("file") as File;
    if (!file) return Response.json({ error: "No file provided" }, { status: 400 });

    // Store raw CSV in R2
    const r2Key = `uploads/${this.state.userId}/${Date.now()}_${file.name}`;
    await this.env.UPLOADS.put(r2Key, file.stream(), {
      httpMetadata: { contentType: "text/csv" },
    });

    // Queue for async processing
    await this.env.AI_JOB_QUEUE.send({
      type:   "parse_csv",
      userId: this.state.userId,
      r2Key,
    });

    this.trackEvent("csv_upload", 1);
    return Response.json({ ok: true, r2Key, status: "processing" });
  }

  // ═══════════════════════════════════════════════════════════
  // AI FORECAST
  // ═══════════════════════════════════════════════════════════
  private async runForecast(): Promise<Response> {
    const history = await this.sql`
      SELECT date, description, amount, category, type
      FROM transactions
      ORDER BY date DESC
      LIMIT 90
    `;
    const rows = [...history] as Transaction[];

    if (rows.length === 0) {
      return Response.json({
        forecast: "No transaction data available yet. Add transactions to generate a forecast.",
      });
    }

    // Summarize for prompt efficiency
    const totalRevenue  = rows.filter(r => r.type === "revenue").reduce((s, r) => s + r.amount, 0);
    const totalExpenses = rows.filter(r => r.type === "expense").reduce((s, r) => s + r.amount, 0);
    const categories    = [...new Set(rows.map(r => r.category))];

    const prompt = `You are a senior CFO analyst. Given this financial data from the past 90 days:
- Total Revenue:  $${totalRevenue.toFixed(2)}
- Total Expenses: $${totalExpenses.toFixed(2)}
- Net Income:     $${(totalRevenue - totalExpenses).toFixed(2)}
- Categories:     ${categories.join(", ")}
- Transactions:   ${rows.length} total

Provide:
1. A 30-day cash flow forecast with projected revenue and expenses
2. Top 3 financial risks to watch
3. One specific CFO-level recommendation
Keep it concise and actionable.`;

    const result = await this.env.AI.run(
      "@cf/meta/llama-3.1-8b-instruct",
      { prompt, max_tokens: 768 }
    ) as { response: string };

    const forecastId = crypto.randomUUID();
    await this.sql`
      INSERT INTO forecasts (id, content)
      VALUES (${forecastId}, ${result.response})
    `;

    this.setState({
      ...this.state,
      lastForecastAt: new Date().toISOString(),
    });

    this.trackEvent("forecast_generated", rows.length);
    return Response.json({ forecast: result.response, forecastId });
  }

  private async getForecastHistory(): Promise<Response> {
    const rows = await this.sql`
      SELECT id, content, created_at
      FROM forecasts
      ORDER BY created_at DESC
      LIMIT 10
    `;
    return Response.json({ forecasts: [...rows] });
  }

  // ═══════════════════════════════════════════════════════════
  // REPORTS
  // ═══════════════════════════════════════════════════════════
  private async queueReport(request: Request): Promise<Response> {
    // Enforce plan limits
    if (this.state.reportsUsed >= this.state.reportsLimit) {
      return Response.json(
        { error: "Report limit reached. Please upgrade your plan." },
        { status: 403 }
      );
    }

    const { type } = await request.json<{ type: "pnl" | "cashflow" | "forecast" | "full" }>();
    const reportId = crypto.randomUUID();

    await this.sql`
      INSERT INTO reports (id, type, r2_key, status)
      VALUES (${reportId}, ${type}, ${"pending"}, ${"pending"})
    `;

    await this.env.REPORT_QUEUE.send({
      reportId,
      userId:  this.state.userId,
      type,
      plan:    this.state.plan,
    });

    this.setState({
      ...this.state,
      reportsUsed:  this.state.reportsUsed + 1,
      lastReportAt: new Date().toISOString(),
    });

    this.trackEvent("report_queued", 1);
    return Response.json({ ok: true, reportId, status: "queued" });
  }

  private async listReports(): Promise<Response> {
    const rows = await this.sql`
      SELECT id, type, r2_key, status, created_at
      FROM reports
      ORDER BY created_at DESC
      LIMIT 20
    `;
    return Response.json({ reports: [...rows] });
  }

  // ═══════════════════════════════════════════════════════════
  // ALERTS
  // ═══════════════════════════════════════════════════════════
  private async checkAlerts() {
    const kpisRes = await this.getKpis();
    const { kpis } = await kpisRes.json() as { kpis: KpiSnapshot };
    const newAlerts: Alert[] = [];

    // Negative net income alert
    if (kpis.netIncome < 0) {
      newAlerts.push({
        id:        crypto.randomUUID(),
        type:      "cash_flow",
        message:   `Negative net income of $${Math.abs(kpis.netIncome).toFixed(2)} in the last 30 days.`,
        severity:  "critical",
        createdAt: new Date().toISOString(),
        read:      false,
      });
    }

    // Expense spike alert (expenses > 80% of revenue)
    if (kpis.revenue > 0 && kpis.expenses / kpis.revenue > 0.8) {
      newAlerts.push({
        id:        crypto.randomUUID(),
        type:      "expense_spike",
        message:   `Expenses are ${((kpis.expenses / kpis.revenue) * 100).toFixed(0)}% of revenue.`,
        severity:  "warning",
        createdAt: new Date().toISOString(),
        read:      false,
      });
    }

    if (newAlerts.length > 0) {
      const existing = this.state.alerts.filter(a => !a.read).slice(0, 20);
      this.setState({
        ...this.state,
        alerts: [...newAlerts, ...existing],
      });
    }
  }

  private async getAlerts(): Promise<Response> {
    return Response.json({ alerts: this.state.alerts });
  }

  private async markAlertRead(pathname: string): Promise<Response> {
    const id = pathname.split("/").pop()!;
    this.setState({
      ...this.state,
      alerts: this.state.alerts.map(a => a.id === id ? { ...a, read: true } : a),
    });
    return Response.json({ ok: true });
  }

  private async deleteAlert(pathname: string): Promise<Response> {
    const id = pathname.split("/").pop()!;
    this.setState({
      ...this.state,
      alerts: this.state.alerts.filter(a => a.id !== id),
    });
    return Response.json({ ok: true });
  }

  // ═══════════════════════════════════════════════════════════
  // SEMANTIC SEARCH (Vectorize)
  // ═══════════════════════════════════════════════════════════
  private async handleSearch(request: Request): Promise<Response> {
    const { query, type, topK = 5 } = await request.json<{
      query: string;
      type?:  string;
      topK?:  number;
    }>();

    const embedding = await this.generateEmbedding(query);
    const filter: Record<string, string> = { userId: this.state.userId };
    if (type) filter["type"] = type;

    const matches = await this.env.VECTORS.query(embedding, {
      topK,
      filter,
      returnMetadata: true,
    });

    const results = matches.matches
      .filter(m => m.score >= 0.4)
      .map(m => ({ id: m.id, score: m.score, meta: m.metadata }));

    this.trackEvent("semantic_search", results.length);
    return Response.json({ results });
  }

  private async embedTransaction(txn: Transaction) {
    const text = `${txn.type} on ${txn.date}: ${txn.description} for $${txn.amount} in ${txn.category}`;
    const embedding = await this.generateEmbedding(text);
    await this.env.VECTORS.upsert([{
      id:     txn.id,
      values: embedding,
      metadata: {
        userId:   this.state.userId,
        type:     txn.type,
        amount:   txn.amount,
        date:     txn.date,
        category: txn.category,
        text:     text.slice(0, 512),
      },
    }]);
  }

  private async generateEmbedding(text: string): Promise<number[]> {
    const res = await this.env.AI.run(
      "@cf/baai/bge-base-en-v1.5",
      { text: [text] }
    ) as { data: number[][] };
    return res.data[0];
  }

  // ═══════════════════════════════════════════════════════════
  // CASH FLOW & P&L
  // ═══════════════════════════════════════════════════════════
  private async getCashFlow(request: Request): Promise<Response> {
    const url  = new URL(request.url);
    const days = parseInt(url.searchParams.get("days") ?? "30");

    const rows = await this.sql`
      SELECT
        date,
        SUM(CASE WHEN type = 'revenue' THEN amount ELSE 0 END) AS revenue,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expenses
      FROM transactions
      WHERE date >= date('now', ${`-${days} days`})
      GROUP BY date
      ORDER BY date ASC
    `;
    return Response.json({ cashflow: [...rows], days });
  }

  private async getPnL(request: Request): Promise<Response> {
    const url  = new URL(request.url);
    const from = url.searchParams.get("from") ?? new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10);
    const to   = url.searchParams.get("to")   ?? new Date().toISOString().slice(0, 10);

    const rows = await this.sql`
      SELECT
        category,
        type,
        SUM(amount) AS total,
        COUNT(*)    AS count
      FROM transactions
      WHERE date BETWEEN ${from} AND ${to}
      GROUP BY category, type
      ORDER BY total DESC
    `;
    return Response.json({ pnl: [...rows], from, to });
  }

  // ═══════════════════════════════════════════════════════════
  // PLAN & BILLING
  // ═══════════════════════════════════════════════════════════
  private async getPlan(): Promise<Response> {
    return Response.json({
      plan:         this.state.plan,
      reportsUsed:  this.state.reportsUsed,
      reportsLimit: this.state.reportsLimit,
    });
  }

  private async upgradePlan(request: Request): Promise<Response> {
    const { plan } = await request.json<{ plan: CfoState["plan"] }>();
    const reportsLimit = plan === "pro" ? 50 : plan === "white-label" ? 999 : 3;
    this.setState({ ...this.state, plan, reportsLimit });
    this.trackEvent("plan_upgraded", 1);
    return Response.json({ ok: true, plan, reportsLimit });
  }

  // ═══════════════════════════════════════════════════════════
  // ANALYTICS HELPER
  // ═══════════════════════════════════════════════════════════
  private trackEvent(event: string, value: number) {
    this.env.ANALYTICS.writeDataPoint({
      blobs:   [event, this.state.userId, this.state.plan],
      doubles: [value],
      indexes: [this.state.userId],
    });
  }
}
