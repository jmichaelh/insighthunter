import type { Env, Insight } from "@/types";
import { cacheGetOrSet } from "@/lib/cache";
import { logger } from "@/lib/logger";

/** Delegates to insighthunter-agents via internal service binding */
export async function getInsights(
  env: Env,
  orgId: string,
  context: Record<string, unknown>
): Promise<Insight[]> {
  const cacheKey = `insights:${orgId}`;

  return cacheGetOrSet(env.CACHE, cacheKey, async () => {
    try {
      const res = await fetch(`${env.AGENTS_SERVICE_URL}/api/insights`, {
        method:  "POST",
        headers: {
          "Content-Type":  "application/json",
          "X-Api-Key":     env.SERVICE_API_KEY,
          "X-Org-Id":      orgId,
        },
        body: JSON.stringify({ orgId, context }),
      });
      if (!res.ok) throw new Error(`Agents service ${res.status}`);
      return res.json() as Promise<Insight[]>;
    } catch (e) {
      logger.warn("Insight service unavailable", { error: String(e) });
      return [];
    }
  }, 900); // cache 15 min
}
