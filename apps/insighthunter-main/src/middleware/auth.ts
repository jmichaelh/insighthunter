import type { MiddlewareHandler } from "hono";
import type { Env, TokenPayload } from "@/types";
import { logger } from "@/lib/logger";

/** Validates JWT issued by insighthunter-auth via Web Crypto API */
async function verifyJWT(token: string, secret: string): Promise<TokenPayload | null> {
  try {
    const [headerB64, payloadB64, sigB64] = token.split(".");
    if (!headerB64 || !payloadB64 || !sigB64) return null;

    const enc      = new TextEncoder();
    const keyData  = enc.encode(secret);
    const key      = await crypto.subtle.importKey("raw", keyData, { name: "HMAC", hash: "SHA-256" }, false, ["verify"]);
    const sigBuf   = Uint8Array.from(atob(sigB64.replace(/-/g, "+").replace(/_/g, "/")), c => c.charCodeAt(0));
    const data     = enc.encode(`${headerB64}.${payloadB64}`);
    const valid    = await crypto.subtle.verify("HMAC", key, sigBuf, data);
    if (!valid) return null;

    const payload = JSON.parse(atob(payloadB64)) as TokenPayload;
    if (payload.exp && Date.now() / 1000 > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

export const authMiddleware: MiddlewareHandler<{ Bindings: Env; Variables: { user: TokenPayload } }> = async (c, next) => {
  const authHeader = c.req.header("Authorization") ?? "";
  const token      = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

  if (!token) {
    return c.json({ error: "Unauthorized", message: "Bearer token required." }, 401);
  }

  const payload = await verifyJWT(token, c.env.JWT_SECRET);
  if (!payload) {
    return c.json({ error: "Unauthorized", message: "Invalid or expired token." }, 401);
  }

  c.set("user", payload);
  logger.debug("Auth OK", { sub: payload.sub, orgId: payload.orgId });
  await next();
};
