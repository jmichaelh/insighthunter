import { Hono } from "hono";
import type { Env, TokenPayload } from "@/types";
import { cacheGet, cacheSet } from "@/lib/cache";

const settings = new Hono<{ Bindings: Env; Variables: { user: TokenPayload } }>();

settings.get("/", async (c) => {
  const user = c.get("user");
  const key  = `settings:${user.orgId}`;
  const data = await cacheGet(c.env.CACHE, key) ?? {
    notifications:   true,
    cashThreshold:   5000,
    forecastHorizon: 6,
    currency:        "USD",
    timezone:        "America/New_York",
  };
  return c.json({ ok: true, data });
});

settings.put("/", async (c) => {
  const user = c.get("user");
  const body = await c.req.json() as Record<string, unknown>;
  const key  = `settings:${user.orgId}`;
  const current = await cacheGet<Record<string, unknown>>(c.env.CACHE, key) ?? {};
  const updated = { ...current, ...body };
  await cacheSet(c.env.CACHE, key, updated, 60 * 60 * 24 * 30);
  return c.json({ ok: true,  updated });
});

export default settings;
