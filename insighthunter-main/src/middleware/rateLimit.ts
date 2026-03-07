import type { MiddlewareHandler } from "hono";
import type { Env } from "@/types";

export const rateLimitMiddleware: MiddlewareHandler<{ Bindings: Env }> = async (c, next) => {
  const ip      = c.req.header("CF-Connecting-IP") ?? "unknown";
  const key     = `rl:${ip}:${Math.floor(Date.now() / 1000 / parseInt(c.env.RATE_LIMIT_WINDOW ?? "60"))}`;
  const max     = parseInt(c.env.RATE_LIMIT_MAX ?? "100");

  const raw     = await c.env.RATE_LIMIT.get(key);
  const count   = raw ? parseInt(raw) : 0;

  if (count >= max) {
    return c.json({ error: "Too Many Requests", message: "Rate limit exceeded. Try again shortly." }, 429);
  }

  const ttl = parseInt(c.env.RATE_LIMIT_WINDOW ?? "60");
  await c.env.RATE_LIMIT.put(key, String(count + 1), { expirationTtl: ttl * 2 });

  c.res.headers.set("X-RateLimit-Limit",     String(max));
  c.res.headers.set("X-RateLimit-Remaining", String(Math.max(0, max - count - 1)));

  await next();
};
