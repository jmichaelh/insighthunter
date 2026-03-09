
import type { MiddlewareHandler } from "hono";
import type { Env, TokenPayload } from "@/types";
import { logger } from "@/lib/logger";

export const authMiddleware: MiddlewareHandler<{ Bindings: Env; Variables: { user: TokenPayload } }> = async (c, next) => {
  const authHeader = c.req.header("Authorization") ?? "";

  try {
    const res = await fetch("http://localhost:8787/verify", {
      headers: { Authorization: authHeader },
    });

    if (!res.ok) {
      logger.error("Auth failed", { status: res.status, statusText: res.statusText });
      return c.json({ error: "Unauthorized" }, 401);
    }

    const user = (await res.json()) as TokenPayload;
    c.set("user", user);
    logger.debug("Auth OK", { sub: user.sub, orgId: user.orgId });
    await next();
  } catch (err) {
    logger.error("Auth middleware error", { err });
    return c.json({ error: "Internal Server Error" }, 500);
  }
};
