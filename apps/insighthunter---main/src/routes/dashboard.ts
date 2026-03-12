import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { getDashboardData } from "@/services/dashboardService";
import { trackEvent } from "@/lib/analytics";

const dashboard = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

dashboard.get("/", async (c) => {
  const user = c.get("user");
  const data = await getDashboardData(c.env, user.orgId);
  trackEvent(c.env, "dashboard_viewed", user.orgId);
  return c.json({ ok: true, data });
});

export default dashboard;
