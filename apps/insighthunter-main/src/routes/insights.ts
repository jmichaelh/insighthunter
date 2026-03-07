import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { getInsights } from "@/services/insightService";
import { getDashboardData } from "@/services/dashboardService";
import { trackEvent } from "@/lib/analytics";

const insights = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

insights.get("/", async (c) => {
  const user    = c.get("user");
  const dash    = await getDashboardData(c.env, user.orgId);
  const results = await getInsights(c.env, user.orgId, { kpis: dash.kpis });
  trackEvent(c.env, "insight_generated", user.orgId);
  return c.json({ ok: true,  results });
});

export default insights;
