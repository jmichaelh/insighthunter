import type { MiddlewareHandler } from "hono";
import type { Env } from "@/types";

export const corsMiddleware: MiddlewareHandler<{ Bindings: Env }> = async (c, next) => {
  const origin  = c.env.CORS_ORIGIN ?? "*";
  const reqOrigin = c.req.header("Origin") ?? "";
  const allowed = origin === "*" || reqOrigin === origin || reqOrigin.endsWith(".insighthunter.com");

  if (c.req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin":  allowed ? reqOrigin : origin,
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Api-Key",
        "Access-Control-Max-Age":       "86400",
      },
    });
  }

  await next();

  c.res.headers.set("Access-Control-Allow-Origin", allowed ? reqOrigin : origin);
  c.res.headers.set("Vary", "Origin");
};
