import type { MiddlewareHandler } from "hono";
import type { Env, TokenPayload } from "@/types";

type Tier = "lite" | "standard" | "enterprise";

const TIER_FEATURES: Record<Tier, Set<string>> = {
  lite:       new Set(["dashboard", "transactions", "csv_upload"]),
  standard:   new Set(["dashboard", "transactions", "csv_upload", "reports", "forecasts", "insights"]),
  enterprise: new Set(["dashboard", "transactions", "csv_upload", "reports", "forecasts", "insights", "clients", "whitelabel", "api_access"]),
};

export function requireFeature(feature: string): MiddlewareHandler<{ Bindings: Env; Variables: { user: TokenPayload } }> {
  return async (c, next) => {
    const user = c.get("user");
    const tier = (user?.tier ?? "lite") as Tier;
    const allowed = TIER_FEATURES[tier] ?? TIER_FEATURES.lite;

    if (!allowed.has(feature)) {
      return c.json({
        error:   "Forbidden",
        message: `This feature requires a higher tier. Current: ${tier}.`,
        upgrade: "https://app.insighthunter.com/upgrade",
      }, 403);
    }
    await next();
  };
}
