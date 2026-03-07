import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { getForecast } from "@/services/forecastService";
import { trackEvent } from "@/lib/analytics";

const forecasts = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

forecasts.get("/", async (c) => {
  const user    = c.get("user");
  const horizon = parseInt(c.req.query("horizon") ?? "6");
  const result  = await getForecast(c.env, user.orgId, Math.min(Math.max(horizon, 1), 24));
  trackEvent(c.env, "forecast_run", user.orgId, { horizon });
  return c.json({ ok: true,  result });
});

export default forecasts;
