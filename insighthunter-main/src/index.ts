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
